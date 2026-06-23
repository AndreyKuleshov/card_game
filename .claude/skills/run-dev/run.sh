#!/usr/bin/env bash
# Launch (or relaunch) the card-game dev stand: the Flutter web build served at
# http://127.0.0.1:<port> (default 8080) via the `web-server` device, which does
# NOT open a browser window itself (so relaunches don't pile up Chrome windows —
# you keep one tab open and hard-refresh). Frees the port and kills any stale
# Flutter dev server first, so it is safe to run repeatedly.
#
# Usage: bash .claude/skills/run-dev/run.sh [port]
set -uo pipefail

# repo root = three levels up from .claude/skills/run-dev/
cd "$(dirname "$0")/../../.." || exit 1
PORT="${1:-8080}"

echo "→ Stopping any already-running dev stand (so instances don't pile up)…"
# 1) Whatever holds the web port (the previous dev server).
PIDS="$(lsof -ti "tcp:$PORT" 2>/dev/null || true)"
[ -n "$PIDS" ] && echo "  · killing PID(s) on port $PORT: $PIDS" && kill -9 $PIDS 2>/dev/null || true
# 2) Any flutter run dev server, regardless of device/args (web-port, browser
#    flags, etc.) — covers stands started by this script or `flutter run` directly.
pkill -9 -f "flutter_tools.snapshot run" 2>/dev/null && echo "  · killed flutter dev server(s)" || true
pkill -9 -f "flutter run -d chrome" 2>/dev/null || true
sleep 1
# 3) Verify the port is actually free before binding.
if lsof -ti "tcp:$PORT" >/dev/null 2>&1; then
  echo "  · port $PORT still busy, force-freeing once more…"
  lsof -ti "tcp:$PORT" | xargs kill -9 2>/dev/null || true
  sleep 1
fi

# Use the `web-server` device (NOT `-d chrome`): it serves the app but does NOT
# spawn its own Chrome window each launch — so relaunching never piles up browser
# windows. Open one tab at the URL yourself and hard-refresh (Cmd+Shift+R) to pick
# up new builds.
echo "→ Starting dev stand: flutter run -d web-server --web-port $PORT"
echo "→ Once you see 'Flutter run key commands', open / hard-refresh http://127.0.0.1:$PORT"
exec flutter run -d web-server --web-port "$PORT" --web-hostname 127.0.0.1
