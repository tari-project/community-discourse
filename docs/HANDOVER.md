# Handover checklist

What to do when the bounty is done and control of the forum is transferred
to the Tari project lead.

## Before the handover call

- [ ] Confirm the forum is live at `https://<FORUM_DOMAIN>` and returns 200
      from `/srv/status`
- [ ] Confirm at least one successful nightly backup has run (check
      `/var/discourse/shared/standalone/backups/default/`)
- [ ] Run the restore drill end-to-end: `sudo ./deploy/restore-test.sh`
- [ ] Verify S3 offsite backup exists (if `S3_BACKUP_BUCKET` set)
- [ ] All seeded categories visible and correctly permissioned
      (cross-check against [`CATEGORIES.md`](CATEGORIES.md))
- [ ] Trust level thresholds match [`TRUST_LEVELS.md`](TRUST_LEVELS.md)
- [ ] Admin account has 2FA enabled
- [ ] GitHub SSO wired (if in scope)
- [ ] Branding (logo, favicon, theme colors) uploaded via
      `/admin/site_settings/category/branding`
- [ ] Moderation emails (`moderation@<FORUM_DOMAIN>`) forwarding to staff
      mailbox
- [ ] CI/CD pipeline deploying successfully (check Actions tab for a green
      run on `main`)
- [ ] GitHub Actions secrets (`SSH_PRIVATE_KEY`, `ENV_PRODUCTION`) are set
      in repo Settings > Secrets
- [ ] DNS TTL lowered temporarily to 300s so the team can retarget records
      quickly if needed

## During the handover call

1. **Walk through the repo** — confirm the project lead can clone and
   read the docs.

2. **Walk through the VPS** — show them:
   - SSH access working with their key
   - `sudo` working for their account
   - `/opt/tari-discourse/` repo checkout
   - `/var/discourse/` launcher
   - `/etc/cron.d/tari-discourse-backup`

3. **Rotate the admin password** live so only they have it:
   ```bash
   sudo /opt/tari-discourse/scripts/rotate-admin.sh <their-email>
   ```
   Send them the one-time reset URL via a secure channel (Signal,
   1Password share, Keybase). **Not** Discord DM, **not** email.

4. **Rotate SSH access:**
   - Add their SSH public key to `/root/.ssh/authorized_keys`
     (or a new sudo user)
   - Remove mine from the same file
   - Confirm they can still log in
   - Remove my user account from `/etc/passwd` if one was created

5. **Transfer secrets** (secure channel, same as above):
   - `.env` file contents (SMTP, Let's Encrypt email, S3 keys, GitHub
     OAuth client ID/secret)
   - **GitHub Actions secrets** on the repo (Settings > Secrets):
     - `SSH_PRIVATE_KEY` — the ed25519 private key authorized on the host
     - `ENV_PRODUCTION` — the full `.env` contents used by CI/CD
   - Mailgun / SES / Postmark account credentials (or coordinate provider
     ownership transfer)
   - GitHub OAuth app ownership — transfer to a tari-project org account
     via <https://github.com/settings/applications>
   - S3 bucket ownership — detach the IAM user from my account and hand
     over credentials for a Tari-owned IAM user

6. **Confirm DNS ownership.** If DNS was pointed at the install host from
   a domain I control, transfer the records. Bump TTL back to 3600 once
   stable.

7. **Revoke my access entirely:**
   - Remove my SSH key
   - Remove my admin account from Discourse:
     ```bash
     sudo /opt/tari-discourse/scripts/rotate-admin.sh <project-lead-email>
     # then in the admin UI, delete my old admin user
     ```
   - Deauthorise any OAuth tokens I hold against the repo

## Post-handover

- [ ] Project lead confirms everything above in writing (issue comment
      or email)
- [ ] Mark [`community-discourse#1`](https://github.com/tari-project/community-discourse/issues/1)
      as resolved
- [ ] PR merged to the upstream repo
- [ ] Bounty XTM payout received

## What I promise not to do after handover

- I retain **no** admin access to the forum
- I retain **no** SSH access to the host
- I retain **no** credentials for SMTP, S3, GitHub OAuth, or DNS
- The only thing I keep is the public commit history in this repo

If any of the above turns out to be false (e.g. I forgot to delete a user,
or a cron job still has a stale credential), **the project lead can force
a full credential rotation** using the procedures in
[`OPERATIONS.md`](OPERATIONS.md) → "I was pwned, rotate everything", and
every credential I ever saw becomes useless.
