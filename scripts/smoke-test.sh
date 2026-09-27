#!/usr/bin/env bash
# Testa automaticamente os 4 combos cliente/servidor na porta 5678.
# Uso: bash scripts/smoke-test.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PY="$ROOT/.venv/bin/python"
ICE_JAR="$ROOT/java/lib/ice-3.8.3.jar"
BREW_JDK="/opt/homebrew/opt/openjdk/bin"
JAVA="$(command -v java 2>/dev/null || echo)"
[ -x "$BREW_JDK/java" ] && JAVA="$BREW_JDK/java"
CP="$ROOT/java/out:$ICE_JAR"
PORT=5678

stop_server() { # $1 = pid ; encerra e espera a porta 5678 liberar
  kill "$1" 2>/dev/null
  "$PY" - "$PORT" "$1" <<'PYEOF'
import socket, sys, time, os, signal
port, pid = int(sys.argv[1]), int(sys.argv[2])
def free():
    try:
        with socket.create_connection(("127.0.0.1", port), 0.2):
            return False
    except OSError:
        return True
for i in range(50):                     # ate ~5s aguardando liberar
    if free():
        sys.exit(0)
    if i == 20:                         # se demorar, forca SIGKILL
        try: os.kill(pid, signal.SIGKILL)
        except OSError: pass
    time.sleep(0.1)
sys.exit(1)
PYEOF
}

wait_port() { # espera a porta abrir (ate ~10s)
  "$PY" - "$PORT" <<'PYEOF'
import socket, sys, time
port = int(sys.argv[1])
for _ in range(100):
    try:
        with socket.create_connection(("127.0.0.1", port), 0.2):
            sys.exit(0)
    except OSError:
        time.sleep(0.1)
sys.exit(1)
PYEOF
}

SRV_LOG="/tmp/asr08-srv.log"
start_server() { # $1 = py|java  -> imprime o PID; saida do servidor vai p/ $SRV_LOG
  # Redirecionar a saida e ESSENCIAL: sem isso, o processo em background herda
  # o pipe da substituicao de comando $(...) e trava a captura do PID.
  : > "$SRV_LOG"
  if [ "$1" = "py" ]; then
    ( cd python && exec "$PY" server.py ) >"$SRV_LOG" 2>&1 &
  else
    "$JAVA" -cp "$CP" Server >"$SRV_LOG" 2>&1 &
  fi
  echo $!
}

run_client() { # $1 = py|java
  if [ "$1" = "py" ]; then
    ( cd python && "$PY" client.py localhost )
  else
    "$JAVA" -cp "$CP" Client localhost
  fi
}

EXPECT_MORSE="... --- ... / .. -.-. ."
EXPECT_ROMAN="MMXXVI"
EXPECT_ERR="toRoman aceita 1..3999, recebeu 5000"

pass=0; fail=0
run_combo() { # $1=servidor $2=cliente
  local srv="$1" cli="$2" label="cliente $2 -> servidor $1"
  echo "=================================================================="
  echo ">> Cenario: $label"
  local pid; pid="$(start_server "$srv")"
  if ! wait_port; then
    echo "   [FALHA] servidor $srv nao subiu"; kill "$pid" 2>/dev/null; fail=$((fail+1)); return
  fi
  local out; out="$(run_client "$cli" 2>&1)"
  stop_server "$pid"; wait "$pid" 2>/dev/null
  echo "$out" | sed 's/^/   cli| /'
  sed 's/^/   srv| /' "$SRV_LOG" 2>/dev/null
  if echo "$out" | grep -qF "$EXPECT_MORSE" \
     && echo "$out" | grep -qF "$EXPECT_ROMAN" \
     && echo "$out" | grep -qF "$EXPECT_ERR"; then
    echo "   [OK] $label"; pass=$((pass+1))
  else
    echo "   [FALHA] saida inesperada em: $label"; fail=$((fail+1))
  fi
}

run_combo py   py
run_combo py   java
run_combo java py
run_combo java java

echo "=================================================================="
echo "RESULTADO: $pass OK, $fail FALHA"
[ "$fail" -eq 0 ]
