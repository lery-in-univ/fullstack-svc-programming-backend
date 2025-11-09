import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'lsp_message.dart';

enum LspState {
  disconnected,
  connecting,
  connected,
  initializing,
  initialized,
  error,
}

class LspClient {
  final String serverUrl;
  final String token;
  io.Socket? _socket;
  LspState _state = LspState.disconnected;
  int _nextId = 1;
  final Map<int, Completer<dynamic>> _pendingRequests = {};
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  LspClient(this.serverUrl, this.token);

  LspState get state => _state;
  Stream<String> get statusStream => _statusController.stream;

  Future<void> connect(String sessionId) async {
    if (_state != LspState.disconnected) {
      throw Exception('Already connected or connecting');
    }

    _state = LspState.connecting;
    _statusController.add('서버에 연결 중...');

    _socket = io.io(
      '$serverUrl/lsp',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    final connectCompleter = Completer<void>();
    Completer<void>? lspConnectCompleter;

    _socket!.onConnect((_) {
      _statusController.add('WebSocket 연결 완료');
      connectCompleter.complete();
    });

    _socket!.onConnectError((error) {
      _state = LspState.error;
      connectCompleter.completeError(Exception('연결 실패: $error'));
    });

    _socket!.on('lsp-connected', (data) {
      _state = LspState.connected;
      _statusController.add('LSP 컨테이너 연결 완료');
      lspConnectCompleter?.complete();
    });

    _socket!.on('lsp-message', (data) {
      _handleLspMessage(data['message'] as String);
    });

    _socket!.on('lsp-error', (data) {
      final error = data['error'] as String;
      final code = data['code'] as int;
      _statusController.add('LSP 에러 ($code): $error');

      if (code == 404) {
        _statusController.add('컨테이너 준비 대기 중...');
      } else if (lspConnectCompleter != null &&
          !lspConnectCompleter.isCompleted) {
        lspConnectCompleter.completeError(Exception('LSP 에러 ($code): $error'));
      }
    });

    _socket!.on('lsp-disconnected', (data) {
      _statusController.add('LSP 연결 종료: ${data['reason']}');
      _state = LspState.disconnected;
    });

    _socket!.connect();
    await connectCompleter.future;

    const maxRetries = 10;
    const retryInterval = Duration(seconds: 2);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      lspConnectCompleter = Completer<void>();
      _socket!.emit('lsp-connect', {'sessionId': sessionId});

      try {
        await lspConnectCompleter.future.timeout(
          retryInterval,
          onTimeout: () {
            if (attempt < maxRetries - 1) {
              _statusController.add('재시도 중... (${attempt + 1}/$maxRetries)');
            }
            throw TimeoutException('재시도 대기');
          },
        );
        break;
      } on TimeoutException {
        if (attempt == maxRetries - 1) {
          throw Exception('LSP 컨테이너 연결 타임아웃');
        }
        continue;
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> initialize(String rootUri) async {
    if (_state != LspState.connected) {
      throw Exception('LSP가 연결되지 않았습니다');
    }

    _state = LspState.initializing;
    _statusController.add('LSP 초기화 중...');

    final initRequest = LspMessage.createInitializeRequest(
      _generateId(),
      rootUri,
    );
    await _sendRequest<Map<String, dynamic>>(
      initRequest['id'] as int,
      initRequest,
    );

    final initializedNotif = LspMessage.createInitializedNotification();
    _sendNotification(initializedNotif);

    _state = LspState.initialized;
    _statusController.add('LSP 초기화 완료');
  }

  Future<void> openDocument(String uri, String content) async {
    if (_state != LspState.initialized) {
      throw Exception('LSP가 초기화되지 않았습니다');
    }

    final didOpen = LspMessage.createDidOpenNotification(
      uri,
      'dart',
      1,
      content,
    );
    _sendNotification(didOpen);
    _statusController.add('파일 열림: $uri');
  }

  Future<List<dynamic>?> goToDefinition(
    String uri,
    int line,
    int character,
  ) async {
    if (_state != LspState.initialized) {
      throw Exception('LSP가 초기화되지 않았습니다');
    }

    _statusController.add('Definition 조회 중...');

    final defRequest = LspMessage.createDefinitionRequest(
      _generateId(),
      uri,
      line,
      character,
    );

    final result = await _sendRequest<dynamic>(
      defRequest['id'] as int,
      defRequest,
    );

    if (result == null) {
      return null;
    }

    if (result is List) {
      return result;
    }

    return [result];
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _state = LspState.disconnected;
    _statusController.add('연결 종료');
  }

  int _generateId() => _nextId++;

  Future<T?> _sendRequest<T>(int id, Map<String, dynamic> message) {
    final completer = Completer<T?>();
    _pendingRequests[id] = completer;

    _sendLspMessage(message);

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw Exception('요청 타임아웃');
      },
    );
  }

  void _sendNotification(Map<String, dynamic> message) {
    _sendLspMessage(message);
  }

  void _sendLspMessage(Map<String, dynamic> message) {
    final formatted = LspMessage.format(message);
    _socket?.emit('lsp-message', {'message': formatted});
  }

  void _handleLspMessage(String raw) {
    _statusController.add(
      'LSP 메시지 수신: ${raw.length > 200 ? "${raw.substring(0, 200)}..." : raw}',
    );

    final json = LspMessage.parse(raw);
    if (json == null) {
      _statusController.add('LSP 메시지 파싱 실패');
      return;
    }

    _statusController.add('파싱 성공: ${json.toString()}');

    if (json.containsKey('id')) {
      final id = json['id'] as int?;
      if (id != null) {
        final completer = _pendingRequests.remove(id);
        if (completer != null) {
          if (json.containsKey('error')) {
            final error = json['error'] as Map<String, dynamic>;
            completer.completeError(
              Exception('LSP 에러: ${error['message']} (${error['code']})'),
            );
          } else {
            completer.complete(json['result']);
          }
        } else {
          _statusController.add('응답 ID $id에 대한 대기 중인 요청 없음');
        }
      }
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}
