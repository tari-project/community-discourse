# Install runbook

End-to-end greenfield install on a fresh host.

> The installer auto-detects the package manager and supports both
> Debian/Ubuntu (apt) and RHEL/AlmaLinux (dnf). The CI/CD pipeline
> currently deploys to AlmaLinux 10.1 on Hetzner.

## 0. Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| OS | Ubuntu 22.04 LTS **or** AlmaLinux 9+ | Ubuntu 24.04 LTS / AlmaLinux 10 |
| vCPU | 2 | 4 |
| RAM | 4 GB | 8 GB+ (bootstrap peak ~6 GB) |
| Disk | 20 GB SSD | 75 GB NVMe |
| Swap | 2 GB | 4 GB (required if RAM < 8 GB) |
| IPv4 | public, static | public, static |
| Ports | 22, 80, 443 open | 22, 80, 443 open |
| DNS | A/AAAA → host | A/AAAA → host (not proxied — see below) |
| SMTP | transactional provider | Resend / Mailgun / SES / Postmark |

Discourse **will not start without working outbound SMTP**. Sign up for
Mailgun/SES/Postmark *before* running the installer.

## 1. Point DNS

Create an A record (and AAAA if you want IPv6) for the chosen FQDN —
e.g. `forum.tari.com` → `<host IPv4>`. Wait for propagation (`dig +short
forum.tari.com` should return the host IP) before running `install.sh`, or
Let's Encrypt's HTTP-01 challenge will fail.

## 2. Clone the repo

```bash
sudo -i
cd /opt
git clone https://github.com/tari-project/community-discourse.git tari-discourse
cd tari-discourse
```

## 3. Fill in `.env`

```bash
cp .env.example .env
$EDITOR .env
```

Required fields:

- `FORUM_DOMAIN`
- `ADMIN_EMAIL`, `ADMIN_USERNAME`
- `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USER_NAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN`
- `NOTIFICATION_EMAIL`
- `LETSENCRYPT_ACCOUNT_EMAIL`

Optional but recommended:

- `S3_BACKUP_BUCKET` + credentials — enables offsite backups
- `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` — if you want GitHub SSO from day 1

## 4. Run the installer

```bash
sudo ./deploy/install.sh
```

What it does, in order:

1. Asserts root + validates `.env`
2. Confirms DNS points at this host
3. `apt update` + installs `ca-certificates`, `curl`, `ufw`, `fail2ban`, `unattended-upgrades`
4. Installs Docker via the official get.docker.com script
5. Configures UFW to allow only 22/80/443
6. Clones `discourse_docker` to `/var/discourse`
7. Renders `deploy/app.yml` → `/var/discourse/containers/app.yml` (envsubst)
8. Stages `deploy/seed-categories.rb` into the shared volume
9. `./launcher bootstrap app` — builds the image (~10 minutes)
10. `./launcher start app` — first-boot runs the category seeder exactly once
11. Installs `/etc/cron.d/tari-discourse-backup` (nightly @ 03:17 UTC)
12. Creates the bootstrap admin account (idempotent)
13. Prints a summary with next-step URLs

Re-running `install.sh` is safe: it will not re-bootstrap an existing
container, it will just re-render `app.yml` and `launcher rebuild app`.

## 5. First login

1. Visit `https://<FORUM_DOMAIN>` — you should see the Discourse welcome screen.
2. Click **Login → Forgot password**, enter `ADMIN_EMAIL`.
3. Follow the password-reset email to set a permanent admin password.
4. Visit `/admin/site_settings/category/all_results?filter=title` and
   confirm `title` = "Tari Community".

## 6. Post-install checklist

- [ ] Login works, admin gets 2FA enabled (`/my/preferences/second-factor`)
- [ ] Seeded categories visible on `/categories` (see [`CATEGORIES.md`](CATEGORIES.md))
- [ ] Run the restore drill: `sudo ./deploy/restore-test.sh`
- [ ] Verify nightly backup cron: `cat /etc/cron.d/tari-discourse-backup`
- [ ] (Optional) Wire GitHub SSO: [`GITHUB_SSO_SETUP.md`](GITHUB_SSO_SETUP.md)
- [ ] Upload branding (logo + favicon): `/admin/site_settings/category/branding`
- [ ] Hand over per [`HANDOVER.md`](HANDOVER.md)

## Troubleshooting

**"Let's Encrypt HTTP-01 challenge failed"** — DNS does not yet point at the
host, or port 80 is not reachable from the internet. Fix the DNS/firewall and
re-run `install.sh`.

> **Cloudflare users:** If your A record is orange-clouded (proxied),
> Let's Encrypt's HTTP-01 challenge will hit Cloudflare, not your host.
> Set the record to **DNS only** (grey cloud) before running install.sh.
> You can re-enable the proxy after the cert is issued if desired, but
> cert renewals (every 60 days) also need direct access to port 80.

**"SMTP connection timed out"** — most VPS providers block outbound port 25.
Use a provider like Resend/Mailgun/SES/Postmark on 587 with STARTTLS, not raw 25.

**"Backend application failed to respond" (502 after bootstrap)** — watch
`./scripts/tail-logs.sh rails`; nine times out of ten it's a missing
`DISCOURSE_HOSTNAME` or bad `DISCOURSE_SMTP_*` value in `.env`.

**Rebuild is stuck at "cloning discourse"** — `git clone` inside the container
is proxied; check `/etc/docker/daemon.json` and corporate proxy settings.

**Bootstrap fails with stale Postgres data** — if a previous bootstrap was
interrupted, leftover Postgres data can prevent a clean restart. Clean it:
```bash
rm -rf /var/discourse/shared/standalone/postgres_data \
       /var/discourse/shared/standalone/postgres_run
```
Then re-run `install.sh`.

**SSH connection drops during bootstrap (Ansible "UNREACHABLE")** — the
Discourse bootstrap takes ~15 minutes. If your SSH connection times out,
add keepalive settings to `deploy/ansible.cfg`:
```ini
[ssh_connection]
ssh_args = -o ServerAliveInterval=30 -o ServerAliveCountMax=60 -o TCPKeepAlive=yes
```

**AlmaLinux: `get.docker.com` fails** — the Docker convenience script does not
support AlmaLinux. `install.sh` handles this automatically by using the Docker
CentOS repo via `dnf config-manager --add-repo`. No manual intervention needed.
