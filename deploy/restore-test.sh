#!/usr/bin/env bash
# =============================================================================
# Tari Community Discourse — restore drill
# =============================================================================
# Proves that the nightly backup is actually restorable. Satisfies the bounty
# requirement to "test a restore" without touching production.
#
# What it does:
#   1. Picks the newest *.tar.gz in /var/discourse/shared/standalone/backups/default
#   2. Spins up a throwaway `app-restore-test` container from the same app.yml
#      pointed at a scratch volume
#   3. Runs `discourse restore <backup>` inside that container
#   4. Hits the /srv/status endpoint to confirm the restored site responds 200
#   5. Tears the container down
#
# Safe to run any time — NEVER touches the production `app` container or its
# data. Schedule weekly via cron (see deploy/backup.yml).
#
# Exit codes:
#   0   restore verified
#   1   no backup found
#   2   restore command failed
#   3   health check failed
# =============================================================================
set -euo pipefail

DISCOURSE_DIR="/var/discourse"
BACKUP_DIR="${DISCOURSE_DIR}/shared/standalone/backups/default"
TEST_CONTAINER="app-restore-test"
SCRATCH_SHARED="${DISCOURSE_DIR}/shared/restore-test"
LOG_TAG="[tari-restore-test]"

log()  { printf '%s %s\n' "${LOG_TAG}" "$*"; }
die()  { printf '%s ERROR: %s\n' "${LOG_TAG}" "$*" >&2; exit "${2:-1}"; }

cleanup() {
  log "cleaning up test container..."
  if docker ps -a --format '{{.Names}}' | grep -q "^${TEST_CONTAINER}$"; then
    docker stop "${TEST_CONTAINER}" >/dev/null 2>&1 || true
    docker rm   "${TEST_CONTAINER}" >/dev/null 2>&1 || true
  fi
  rm -rf "${SCRATCH_SHARED}"
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# 1. Find newest backup
# -----------------------------------------------------------------------------
if [[ ! -d "${BACKUP_DIR}" ]]; then
  die "backup dir not found: ${BACKUP_DIR}. Has a backup run yet?" 1
fi

LATEST="$(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | head -1 || true)"
if [[ -z "${LATEST}" ]]; then
  die "no *.tar.gz backups in ${BACKUP_DIR}" 1
fi
log "using backup: $(basename "${LATEST}")"

# -----------------------------------------------------------------------------
# 2. Build a scratch container definition pointed at a throwaway shared volume
# -----------------------------------------------------------------------------
mkdir -p "${SCRATCH_SHARED}/backups/default"
cp "${LATEST}" "${SCRATCH_SHARED}/backups/default/"

TEST_YML="${DISCOURSE_DIR}/containers/${TEST_CONTAINER}.yml"
# Clone the prod app.yml but swap the shared volume mount + hostname + ports
# so nothing collides with production.
sed \
  -e "s|host: /var/discourse/shared/standalone|host: ${SCRATCH_SHARED}|g" \
  -e 's|"80:80"|"8880:80"|g' \
  -e 's|"443:443"|"8443:443"|g' \
  -e 's|DISCOURSE_HOSTNAME:.*|DISCOURSE_HOSTNAME: "restore-test.local"|' \
  -e '/web.letsencrypt.ssl.template.yml/d' \
  -e '/web.ssl.template.yml/d' \
  "${DISCOURSE_DIR}/containers/app.yml" > "${TEST_YML}"

log "bootstrapping ${TEST_CONTAINER}..."
cd "${DISCOURSE_DIR}"
./launcher bootstrap "${TEST_CONTAINER}"
./launcher start     "${TEST_CONTAINER}"

# -----------------------------------------------------------------------------
# 3. Run discourse restore against the copied backup
# -----------------------------------------------------------------------------
log "restoring backup inside test container..."
BACKUP_BASENAME="$(basename "${LATEST}")"
if ! docker exec "${TEST_CONTAINER}" bash -lc "
  export DISCOURSE_ENABLE_RESTORE=1
  cd /var/www/discourse
  sudo -u discourse bundle exec discourse enable_restore
  sudo -u discourse bundle exec discourse restore ${BACKUP_BASENAME}
"; then
  die "restore command failed — see container logs" 2
fi

# -----------------------------------------------------------------------------
# 4. Smoke test: /srv/status should 200 on the internal port
# -----------------------------------------------------------------------------
log "smoke-testing restored site..."
for i in {1..30}; do
  if curl -fsS -o /dev/null -w '%{http_code}' http://127.0.0.1:8880/srv/status | grep -q '^200$'; then
    log "restore drill PASSED — /srv/status returned 200"
    exit 0
  fi
  sleep 2
done
die "restored site never returned 200 on /srv/status" 3
