#!/usr/bin/env bash
# =============================================================================
# Tari Community Discourse — rotate the bootstrap admin password
# =============================================================================
# Used at handover: forces a password reset email to be sent to ADMIN_EMAIL,
# invalidates any existing sessions, and prints a one-time URL to set a new
# password.
#
# Usage:  sudo ./scripts/rotate-admin.sh <email>
# Example: sudo ./scripts/rotate-admin.sh project-lead@tari.com
# =============================================================================
set -euo pipefail

EMAIL="${1:-}"
if [[ -z "${EMAIL}" ]]; then
  echo "Usage: $0 <admin-email>" >&2
  exit 1
fi

# Validate that the argument looks like an email address before interpolating
# it into a shell command. This prevents a malformed argument from breaking the
# Ruby runner invocation.  RFC 5321 permits exotic local-parts (e.g. quoted
# strings with parentheses), but those are not used in practice for admin
# accounts; a basic check is a sufficient guard here.
if [[ ! "${EMAIL}" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
  echo "Error: '${EMAIL}' does not look like a valid email address." >&2
  exit 1
fi

DISCOURSE_DIR="/var/discourse"
cd "${DISCOURSE_DIR}"

echo "[tari-rotate] invalidating existing sessions for ${EMAIL}..."
# Pass EMAIL as an environment variable and use a single-quoted heredoc so
# the shell never interpolates ${EMAIL} inside the Ruby script — avoiding
# injection if the address contains Ruby-significant characters.
EMAIL="${EMAIL}" ./launcher enter app <<'RUBY'
bin/rails runner '
  email = ENV["EMAIL"]
  user = User.find_by_email(email)
  if user.nil?
    puts "[tari-rotate] no user found for #{email}"
    exit 1
  end
  user.user_auth_tokens.destroy_all
  user.password = SecureRandom.hex(24)
  user.save!
  # Generate a one-time password reset URL the new admin can use immediately.
  token = EmailToken.enqueue_email_token(user, :password_reset)
  puts "[tari-rotate] reset URL: #{Discourse.base_url}/u/password-reset/#{token.token}"
  puts "[tari-rotate] (also emailed to #{email})"
'
RUBY
