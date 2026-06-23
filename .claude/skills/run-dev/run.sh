#!/usr/bin/env bash
# Launch (or relaunch) the card-game dev stand: the Flutter web build served on
# Chrome at http://127.0.0.1:<port> (default 8080). Frees the port and kills any
# stale Flutter dev server first, so it is safe to run repeatedly.
#
# Usage: bash .claude/skills/run-dev/run.sh [port]
set -uo pipefail

# repo root = three levels up from .claude/skills/run-dev/
cd "$(dirname "$0")/../../.." || exit 1
PORT="${1:-8080}"

echo "→ Freeing port $PORT and stopping any stale Flutter dev server…"
PIDS="$(lsof -ti "tcp:$PORT" 2>/dev/null || true)"
[ -n "$PIDS" ] && kill -9 $PIDS 2>/dev/null || true
pkill -9 -f "flutter_tools.snapshot run -d chrome" 2>/dev/null || true
sleep 1

echo "→ Starting dev stand: flutter run -d chrome --web-port $PORT"
echo "→ Once you see 'Flutter run key commands', open http://127.0.0.1:$PORT"
exec flutter run -d chrome --web-port "$PORT" --web-hostname 127.0.0.1
