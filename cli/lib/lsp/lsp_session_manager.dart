import 'dart:async';
import '../api/lsp_api.dart';
import 'lsp_client.dart';

/// Manages LSP session state and connection lifecycle
class LspSessionManager {
  String? currentSessionId;
  LspClient? activeClient;
  Timer? _renewalTimer;
  final Duration _renewalInterval = const Duration(minutes: 5);

  /// Returns true if there's an active session
  bool hasActiveSession() => currentSessionId != null;

  /// Returns true if there's an active LSP connection
  bool hasActiveConnection() => activeClient != null;

  /// Starts automatic session renewal to prevent expiration
  /// Sessions expire after 600 seconds, so renewing every 5 minutes keeps them alive
  void startRenewal(LspApi api) {
    _renewalTimer?.cancel();
    _renewalTimer = Timer.periodic(_renewalInterval, (_) async {
      if (currentSessionId != null) {
        try {
          await api.renewSession(currentSessionId!);
        } catch (e) {
          // Silently fail - user will see error on next request if session expired
        }
      }
    });
  }

  /// Disconnects the active LSP client and clears session state
  Future<void> disconnect() async {
    _renewalTimer?.cancel();
    _renewalTimer = null;

    if (activeClient != null) {
      activeClient!.dispose();
      activeClient = null;
    }

    currentSessionId = null;
  }

  /// Disposes all resources
  void dispose() {
    _renewalTimer?.cancel();
    activeClient?.dispose();
  }
}
