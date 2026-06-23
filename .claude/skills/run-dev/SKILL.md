---
name: run-dev
description: Use when you need to start or restart the local dev stand for this Flutter card game — running/relaunching the web build on Chrome at http://127.0.0.1:8080, testing changes in the browser, or recovering when the dev server is stale or port 8080 is "Address already in use".
---

# Run the dev stand

## Overview

Launches the card game's local dev stand: the Flutter **web** build served on Chrome at `http://127.0.0.1:8080`. The backend API is remote (Coolify) at `https://cardsspg.duckdns.org`, so **no local server is needed** — only the Flutter web dev server.

`flutter run` is long-lived: it builds, opens Chrome, then stays attached for hot reload. So launch it in the background and wait for the ready line.

## How to launch (agent procedure)

1. Run the launch script **in the background** (it frees port 8080 + kills any stale dev server first, then starts `flutter run`):

   ```bash
   bash .claude/skills/run-dev/run.sh
   ```

2. Wait for the ready line by polling the task's output for `Flutter run key commands` (or a build error). Do **not** foreground-`sleep`; use an until-loop on the output file, e.g.:

   ```bash
   until grep -qE "Flutter run key commands|Failed to bind|Error:|Compilation failed" "<task-output-file>"; do sleep 1; done
   ```

3. Tell the user to open / hard-refresh **http://127.0.0.1:8080** (Cmd+Shift+R).

The server keeps running across turns. To apply new code, re-run the script (it relaunches cleanly).

## Quick reference

| Task | Command |
|---|---|
| Start / restart dev stand | `bash .claude/skills/run-dev/run.sh` |
| Use a different port | `bash .claude/skills/run-dev/run.sh 8090` |
| Run tests | `flutter test` |
| Static analysis | `flutter analyze` |
| Build web (no serve) | `flutter build web` |

## Notes & troubleshooting

- **`SocketException: Address already in use, errno = 48`** — a previous dev server still holds the port. The script already frees it; if it persists, run `lsof -ti tcp:8080 | xargs kill -9`.
- **`flutter run -d chrome` stays attached** — that's expected; run it in the background. Killing the background task stops the server.
- **Cloud sync** — on first load the app silently creates an anonymous player and syncs progress to Postgres via the remote API; the game still works fully offline if the API is unreachable.
- **`flutter` not found** — ensure `/opt/homebrew/bin` is on PATH (Flutter was installed via Homebrew).
- This is web-only by default. No Android emulator / iOS Simulator is configured on this machine; `flutter build web` is also used as the end-to-end compile check.
