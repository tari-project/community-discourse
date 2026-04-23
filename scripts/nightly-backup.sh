#!/usr/bin/env bash
# =============================================================================
# Tari Community Discourse — nightly backup runner
# =============================================================================
# Invoked by /etc/cron.d/tari-discourse-backup at 03:17 UTC.
#
# 1. Calls `./launcher backup app` so Discourse itself produces a consistent
#    Postgres + uploads snapshot (this is the officially supported path).
# 2. Prunes local backups older than BACKUP_RETENTION_DAYS.
# 3. If S3_BACKUP_BUCKET is set in /etc/tari-discourse.env, uploads the
#    newest backup to s3://$bucket/discourse/nightly/.
#
# All output is captured to /var/log/tari-discourse-backup.log by the cron.
# =============================================================================
set -euo pipefail

DISCOURSE_DIR="/var/discourse"
BACKUP_DIR="${DISCOURSE_DIR}/shared/standalone/backups/default"
ENV_FILE="/etc/tari-discourse.env"

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

# Load env (written by install.sh — a filtered copy of repo .env with only
# non-secret operational vars).
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +a
fi
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"

# -----------------------------------------------------------------------------
# 1. Trigger Discourse backup via the launcher
# -----------------------------------------------------------------------------
log "starting discourse backup..."
cd "${DISCOURSE_DIR}"
# `launcher backup` exits non-zero on any error.
./launcher backup app
log "discourse backup complete"

# -----------------------------------------------------------------------------
# 2. Prune old local backups
# -----------------------------------------------------------------------------
log "pruning backups older than ${BACKUP_RETENTION_DAYS} days from ${BACKUP_DIR}"
find "${BACKUP_DIR}" -maxdepth 1 -type f -name '*.tar.gz' \
  -mtime "+${BACKUP_RETENTION_DAYS}" -print -delete || true

# -----------------------------------------------------------------------------
# 3. Optional S3 offsite
# -----------------------------------------------------------------------------
if [[ -n "${S3_BACKUP_BUCKET:-}" ]]; then
  if ! command -v aws >/dev/null 2>&1; then
    log "WARN: S3_BACKUP_BUCKET set but aws CLI not installed — skipping offsite"
    exit 0
  fi
  LATEST="$(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | head -1 || true)"
  if [[ -z "${LATEST}" ]]; then
    log "WARN: no backup to upload"
    exit 0
  fi
  KEY="discourse/nightly/$(basename "${LATEST}")"
  log "uploading $(basename "${LATEST}") to s3://${S3_BACKUP_BUCKET}/${KEY}"
  AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}" \
  AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}" \
  AWS_DEFAULT_REGION="${S3_REGION}" \
    aws s3 cp "${LATEST}" "s3://${S3_BACKUP_BUCKET}/${KEY}" \
      --storage-class STANDARD_IA
  log "offsite upload complete"
fi

log "nightly-backup done"
