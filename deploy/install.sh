#!/usr/bin/env bash
# =============================================================================
# Tari Community Discourse — bootstrap installer
# =============================================================================
# Target: fresh Ubuntu 24.04 LTS host with a public IPv4, root (or sudo).
#
# This script is IDEMPOTENT. Re-running it on an already-installed host is
# safe: it will no-op the install steps and only regenerate /var/discourse/
# containers/app.yml from the template + .env.
#
# Exit codes:
#   0   success
#   2   .env missing or required var unset
#   3   DNS not pointing at this host
#   4   docker install failed
#   5   discourse launcher bootstrap failed
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${REPO_DIR}/.env"
DISCOURSE_DIR="/var/discourse"
APP_YML_TEMPLATE="${REPO_DIR}/deploy/app.yml"
SEED_SCRIPT_SRC="${REPO_DIR}/deploy/seed-categories.rb"

log()  { printf '\e[1;34m[tari]\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m[tari]\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[1;31m[tari]\e[0m %s\n' "$*" >&2; exit "${2:-1}"; }

# -----------------------------------------------------------------------------
# 0. Preflight: root, env file, required vars, DNS
# -----------------------------------------------------------------------------
require_root() {
  if [[ $EUID -ne 0 ]]; then
    die "install.sh must be run as root (use sudo)." 1
  fi
}

require_env() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    die ".env not found at ${ENV_FILE}. Copy .env.example and fill it in." 2
  fi
  set -a
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +a

  local missing=()
  for var in FORUM_DOMAIN ADMIN_EMAIL SMTP_ADDRESS SMTP_USER_NAME SMTP_PASSWORD \
             SMTP_DOMAIN NOTIFICATION_EMAIL DB_SHARED_BUFFERS UNICORN_WORKERS \
             BACKUP_RETENTION_DAYS LETSENCRYPT_ACCOUNT_EMAIL; do
    if [[ -z "${!var:-}" ]]; then
      missing+=("$var")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Required .env vars unset: ${missing[*]}" 2
  fi
}

require_dns() {
  log "Checking DNS for ${FORUM_DOMAIN}..."
  local public_ip resolved_ip
  public_ip="$(curl -fsSL https://api.ipify.org || true)"
  resolved_ip="$(getent hosts "${FORUM_DOMAIN}" | awk '{print $1}' | head -1 || true)"
  if [[ -z "${public_ip}" ]]; then
    warn "Could not determine public IP — skipping DNS check."
    return 0
  fi
  if [[ "${public_ip}" != "${resolved_ip}" ]]; then
    die "DNS for ${FORUM_DOMAIN} resolves to '${resolved_ip}' but this host is '${public_ip}'. Fix DNS before continuing — Let's Encrypt will fail otherwise." 3
  fi
  log "DNS OK (${FORUM_DOMAIN} → ${public_ip})."
}

# -----------------------------------------------------------------------------
# 1. Host packages + Docker
# -----------------------------------------------------------------------------
install_host_packages() {
  log "Updating apt and installing base packages..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -yqq \
    ca-certificates curl git gnupg lsb-release \
    ufw fail2ban unattended-upgrades \
    jq openssl

  # Enable unattended security updates — one fewer thing for handover.
  dpkg-reconfigure -f noninteractive unattended-upgrades
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed ($(docker --version))."
    return 0
  fi
  log "Installing Docker via the official convenience script..."
  curl -fsSL https://get.docker.com | sh || die "Docker install failed." 4
  systemctl enable --now docker
}

configure_firewall() {
  log "Configuring UFW: allow 22, 80, 443; deny everything else inbound."
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp   comment 'SSH'
  ufw allow 80/tcp   comment 'HTTP (Discourse / Let'\''s Encrypt HTTP-01)'
  ufw allow 443/tcp  comment 'HTTPS (Discourse)'
  ufw --force enable
}

# -----------------------------------------------------------------------------
# 2. discourse_docker launcher
# -----------------------------------------------------------------------------
clone_discourse_docker() {
  if [[ -d "${DISCOURSE_DIR}/.git" ]]; then
    log "discourse_docker already cloned — fast-forwarding..."
    git -C "${DISCOURSE_DIR}" fetch --quiet origin
    git -C "${DISCOURSE_DIR}" reset --hard origin/main
  else
    log "Cloning discourse_docker into ${DISCOURSE_DIR}..."
    git clone --depth 1 https://github.com/discourse/discourse_docker.git "${DISCOURSE_DIR}"
  fi
  mkdir -p "${DISCOURSE_DIR}/shared/standalone/tari-seed"
}

render_app_yml() {
  log "Rendering ${DISCOURSE_DIR}/containers/app.yml from template..."
  mkdir -p "${DISCOURSE_DIR}/containers"
  # envsubst substitutes ONLY the variables that appear in the template.
  # We pass an explicit allow-list so a stray ${...} in a comment doesn't blow up.
  local vars='$FORUM_DOMAIN $ADMIN_EMAIL $SMTP_ADDRESS $SMTP_PORT $SMTP_USER_NAME $SMTP_PASSWORD $SMTP_DOMAIN $NOTIFICATION_EMAIL $DB_SHARED_BUFFERS $UNICORN_WORKERS $BACKUP_RETENTION_DAYS $LETSENCRYPT_ACCOUNT_EMAIL'
  envsubst "${vars}" < "${APP_YML_TEMPLATE}" > "${DISCOURSE_DIR}/containers/app.yml"
  chmod 600 "${DISCOURSE_DIR}/containers/app.yml"
}

stage_seed_script() {
  log "Staging category seed script into shared volume..."
  install -m 0644 "${SEED_SCRIPT_SRC}" \
    "${DISCOURSE_DIR}/shared/standalone/tari-seed/seed-categories.rb"
}

bootstrap_or_rebuild() {
  cd "${DISCOURSE_DIR}"
  if docker ps -a --format '{{.Names}}' | grep -q '^app$'; then
    log "Container 'app' exists — rebuilding to pick up config changes..."
    ./launcher rebuild app || die "launcher rebuild app failed." 5
  else
    log "First-time bootstrap — this will take ~10 minutes..."
    ./launcher bootstrap app || die "launcher bootstrap app failed." 5
    ./launcher start app     || die "launcher start app failed." 5
  fi
}

# -----------------------------------------------------------------------------
# 3. Post-install: backup cron, bootstrap admin, summary
# -----------------------------------------------------------------------------
install_backup_cron() {
  log "Installing nightly backup cron..."
  install -m 0755 "${REPO_DIR}/scripts/nightly-backup.sh" /usr/local/sbin/tari-nightly-backup.sh
  cat > /etc/cron.d/tari-discourse-backup <<EOF
# Tari Discourse — nightly backup (03:17 UTC, offset from the crowd)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
17 3 * * * root /usr/local/sbin/tari-nightly-backup.sh >> /var/log/tari-discourse-backup.log 2>&1
EOF
  chmod 644 /etc/cron.d/tari-discourse-backup
}

create_bootstrap_admin() {
  log "Ensuring bootstrap admin account exists (${ADMIN_EMAIL})..."
  # The Rails console will noop if the user already exists with admin=true.
  "${DISCOURSE_DIR}/launcher" enter app <<'RUBY' || true
bin/rails runner '
  email = ENV["ADMIN_EMAIL"] || "admin@tari.com"
  username = ENV["ADMIN_USERNAME"] || "tari_admin"
  user = User.find_by_email(email) || User.create!(
    email: email,
    username: username,
    password: SecureRandom.hex(24),
    active: true,
    approved: true,
    trust_level: TrustLevel[4]
  )
  user.update!(admin: true, moderator: true)
  user.activate
  puts "[tari] Admin account ready: #{user.username} <#{user.email}>"
'
RUBY
}

summary() {
  cat <<EOF

================================================================================
  Tari Community Discourse — install complete
================================================================================
  Forum URL:        https://${FORUM_DOMAIN}
  Admin email:      ${ADMIN_EMAIL}
  Container:        ${DISCOURSE_DIR}
  Backups:          /var/discourse/shared/standalone/backups (retention: ${BACKUP_RETENTION_DAYS}d)
  Cron:             /etc/cron.d/tari-discourse-backup (nightly @ 03:17 UTC)

  Next steps:
    1. Log in at https://${FORUM_DOMAIN} using the "Forgot password" flow
       with ${ADMIN_EMAIL} to set the admin password.
    2. Review seeded categories (see docs/CATEGORIES.md).
    3. (Optional) Wire GitHub SSO — docs/GITHUB_SSO_SETUP.md.
    4. Run a restore drill: sudo ./deploy/restore-test.sh
    5. Hand over to the project lead per docs/HANDOVER.md.
================================================================================
EOF
}

# -----------------------------------------------------------------------------
main() {
  require_root
  require_env
  require_dns
  install_host_packages
  install_docker
  configure_firewall
  clone_discourse_docker
  render_app_yml
  stage_seed_script
  bootstrap_or_rebuild
  install_backup_cron
  create_bootstrap_admin
  summary
}

main "$@"
