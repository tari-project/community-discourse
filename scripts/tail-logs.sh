#!/usr/bin/env bash
# =============================================================================
# Tari Community Discourse — tail all the relevant logs at once
# =============================================================================
# Usage: sudo ./scripts/tail-logs.sh [rails|nginx|unicorn|sidekiq|backup|all]
# =============================================================================
set -euo pipefail

TARGET="${1:-all}"
LOG_BASE="/var/discourse/shared/standalone/log"

case "${TARGET}" in
  rails)
    exec tail -F "${LOG_BASE}/rails/production.log"
    ;;
  nginx)
    exec tail -F "${LOG_BASE}/nginx/access.log" "${LOG_BASE}/nginx/error.log"
    ;;
  unicorn)
    exec tail -F "${LOG_BASE}/rails/unicorn.stdout.log" "${LOG_BASE}/rails/unicorn.stderr.log"
    ;;
  sidekiq)
    exec tail -F "${LOG_BASE}/rails/sidekiq.log"
    ;;
  backup)
    exec tail -F /var/log/tari-discourse-backup.log
    ;;
  all)
    exec tail -F \
      "${LOG_BASE}/rails/production.log" \
      "${LOG_BASE}/nginx/error.log" \
      "${LOG_BASE}/rails/sidekiq.log" \
      /var/log/tari-discourse-backup.log
    ;;
  *)
    echo "Usage: $0 [rails|nginx|unicorn|sidekiq|backup|all]" >&2
    exit 1
    ;;
esac
