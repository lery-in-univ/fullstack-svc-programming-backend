#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] starting dart language-server via socat ..."
echo "[entrypoint] listening on port 9000"

# dart language-server가 잘 뜨는지 로깅 확인 가능
socat -v \
  TCP-LISTEN:9000,reuseaddr,fork \
  EXEC:"dart language-server --protocol=lsp --client-id=docker.test --client-version=1.0"
