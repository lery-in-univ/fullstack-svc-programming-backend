#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="dart-lsp:3.9.4"
CONTAINER_NAME="dart-lsp-socat-test"
VOLUME_NAME="dart_lsp_workspace"
PORT=9000

# 정리 함수
cleanup() {
  echo "== 정리 중 =="
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker volume rm "$VOLUME_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# 필요한 명령어 체크
for cmd in docker nc; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "에러: '$cmd' 명령어가 필요함." >&2
    exit 1
  fi
done

echo "== Docker volume 생성 =="
docker volume create "$VOLUME_NAME" >/dev/null

echo "== volume 안에 예제 Dart 파일 생성 =="
docker run --rm -v "$VOLUME_NAME":/workspace busybox sh -c '
  mkdir -p /workspace
  cat > /workspace/main.dart << "EOF"
int add(int a, int b) {
  return a + b;
}

void main() {
  final result = add(1, 2);
  print(result);
}
EOF
'

echo "== 컨테이너 시작 =="
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "${PORT}:9000" \
  -v "$VOLUME_NAME":/workspace \
  "$IMAGE_NAME" >/dev/null

echo "서버 기동 대기 중..."
sleep 5

# LSP 메시지들 정의 (JSON-RPC)
INITIALIZE='{
  "jsonrpc":"2.0",
  "id":1,
  "method":"initialize",
  "params":{
    "processId":1,
    "rootUri":"file:///workspace",
    "capabilities":{},
    "workspaceFolders":[{"uri":"file:///workspace","name":"workspace"}]
  }
}'

INITIALIZED='{
  "jsonrpc":"2.0",
  "method":"initialized",
  "params":{}
}'

# didOpen: 파일 내용을 그대로 text로 넘김
DIDOPEN='{
  "jsonrpc":"2.0",
  "method":"textDocument/didOpen",
  "params":{
    "textDocument":{
      "uri":"file:///workspace/main.dart",
      "languageId":"dart",
      "version":1,
      "text":"int add(int a, int b) {\n  return a + b;\n}\n\nvoid main() {\n  final result = add(1, 2);\n  print(result);\n}\n"
    }
  }
}'

# go to definition: main.dart의 add 호출 위치(line 5, char 18 기준; 0-based)
DEFINITION='{
  "jsonrpc":"2.0",
  "id":2,
  "method":"textDocument/definition",
  "params":{
    "textDocument":{"uri":"file:///workspace/main.dart"},
    "position":{"line":5,"character":18}
  }
}'

# LSP 메시지 헤더 + 바디로 감싸는 함수
make_lsp_frame() {
  local json="$1"
  local len=${#json}
  # Content-Length 헤더 + CRLF 두 개 + 본문
  printf 'Content-Length: %d\r\n\r\n%s' "$len" "$json"
}

echo "== LSP 요청 전송 (initialize → initialized → didOpen → definition) =="
{
  # 1) initialize 먼저 보냄
  make_lsp_frame "$INITIALIZE"

  # 서버가 initialize 처리할 시간 조금 줌
  sleep 3

  # 2) 이제부터는 spec상 허용되는 메시지들
  make_lsp_frame "$INITIALIZED"
  make_lsp_frame "$DIDOPEN"

  # 파일 분석할 시간 조금 더
  sleep 3
  
  # 3) definition 요청
  make_lsp_frame "$DEFINITION"

  # 응답 올 때까지 대기
  sleep 5
} | nc 127.0.0.1 "$PORT" > lsp_output.log || {
  echo "nc 실행 실패. 서버가 죽었거나 포트 연결 실패." >&2
  echo "컨테이너 로그:"
  docker logs "$CONTAINER_NAME" || true
  exit 1
}

echo "== LSP raw 응답 일부 =="
# 너무 길 수 있으니 끝부분만 보여줌
tail -n 40 lsp_output.log || true

echo
echo "== go to definition 결과 검사 =="

# id=2 응답 안에 main.dart 정의 위치가 들어있는지만 대충 확인
if grep -q '"id":2' lsp_output.log && grep -q 'main.dart' lsp_output.log; then
  echo "✅ textDocument/definition 응답이 main.dart 위치를 반환함 (add 정의를 찾은 것으로 간주)."
  # 정의가 0번 라인 근처인지도 한 번 더 체크(대략적인 sanity check)
  if grep -q '"line":0' lsp_output.log; then
    echo "✅ 정의 위치가 line 0 근처로 잡힘 (add 함수 정의 라인으로 보임)."
  else
    echo "⚠️ 응답에 line 0은 안 보이지만, main.dart 안의 위치는 반환된 것 같음. 로그를 직접 확인해봐."
  fi
  exit 0
else
  echo "❌ definition 응답에서 main.dart 위치를 찾지 못함. lsp_output.log 내용을 확인해봐."
  exit 1
fi
