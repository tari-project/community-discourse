#!/usr/bin/env bash
# =============================================================================
# Tari Community Discourse — safe rebuild helper
# =============================================================================
# Wraps `./launcher rebuild app` with a pre-rebuild backup so that if the
# rebuild fails for any reason (plugin incompat, config typo, upstream
# breakage), you have a fresh snapshot to roll back to.
#
# Usage: sudo ./scripts/rebuild.sh
# =============================================================================
set -euo pipefail

DISCOURSE_DIR="/var/discourse"
log() { printf '[tari-rebuild] %s\n' "$*"; }

if [[ $EUID -ne 0 ]]; then
  echo "rebuild.sh must be run as root (use sudo)." >&2
  exit 1
fi

log "taking a pre-rebuild backup..."
cd "${DISCOURSE_DIR}"
./launcher backup app

log "re-rendering app.yml from template..."
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"${REPO_DIR}/deploy/install.sh"   # idempotent — will just re-render config + rebuild

log "done. Tail /var/discourse/shared/standalone/log/rails/production.log to watch the restart."
