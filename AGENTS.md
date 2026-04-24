## Tend Integration

This project uses [Tend](https://github.com/metalaureate/tend-cli) for workflow coordination.

### Setup

Prefer the generated hook command from .github/hooks/tend.json for automated lifecycle events. Do not assume `tend` is on PATH in non-interactive shells.

If you need to run Tend manually and `tend` is not on PATH, install it:

```bash
curl -sSL https://raw.githubusercontent.com/metalaureate/tend-cli/main/bin/tend -o /usr/local/bin/tend && chmod +x /usr/local/bin/tend
```

### On Startup

1. Read `.tend/TODO` — propose pending items to the developer and ask what to work on.
2. Review recent git history for context on what's already been done.

### During Work

- `tend emit working "<description>"` — automatically emitted by hooks on each prompt, but emit manually when switching tasks.
- `tend emit done "<summary>"` — **IMPORTANT: always emit when you finish a task.** This is the primary signal that work completed.
- `tend emit stuck "<what you need>"` — emit when you cannot proceed without human input (e.g., need a decision, credentials, access, or clarification).
- `tend emit waiting "<what you're waiting for>"` — emit when blocked on an external dependency (e.g., CI, deployment, API response).

### On Completion

- Emit `tend emit done "<summary of what you accomplished>"` before going idle.
- If there are items in `.tend/TODO`, note the next item but wait for the developer to assign it (do not auto-start).

### Relay (Cloud Monitoring)

If `TEND_RELAY_TOKEN` is set in your environment, `tend emit` automatically posts events to the relay so the developer can monitor your progress in real-time.

Verify relay connectivity at startup:

```bash
echo "TEND_RELAY_TOKEN=${TEND_RELAY_TOKEN:-NOT SET}"
tend relay debug
```

If the token is not set and you are running in a remote or cloud environment, inform the developer so they can provide `TEND_RELAY_TOKEN` for your session.

### Event Format

If `tend` is not available, append a single line to `.tend/events`:

```
<ISO-8601-timestamp> <session-id> <state> <message>
```

Use `$TEND_SESSION_ID` as the session ID if set, otherwise use `_cli`.

States: `working`, `done`, `stuck`, `waiting`, `idle`.

Example:
```
2026-03-13T14:20:00 _cli working refactoring narrative engine
2026-03-13T14:45:00 _cli done refactored narrative engine (PR #204)
2026-03-13T14:46:00 _cli stuck needs database credentials for staging
```
