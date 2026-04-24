# Operations runbook

Day-2 ops for the Tari Discourse forum. Assumes install is complete per
[`INSTALL.md`](INSTALL.md).

## Where things live

| Path | What it is |
|------|------------|
| `/opt/tari-discourse/` | This repo, checked out on the host |
| `/var/discourse/` | `discourse_docker` launcher + containers/ |
| `/var/discourse/containers/app.yml` | **Generated** from `deploy/app.yml`. Do not hand-edit. |
| `/var/discourse/shared/standalone/` | Persistent data: Postgres, uploads, backups, logs |
| `/var/discourse/shared/standalone/log/` | All runtime logs |
| `/etc/tari-discourse.env` | Filtered non-secret env used by cron jobs |
| `/etc/cron.d/tari-discourse-backup` | Nightly backup cron |
| `/var/log/tari-discourse-backup.log` | Nightly backup output |

## Daily checks

- **Are backups running?** `ls -lht /var/discourse/shared/standalone/backups/default/ | head`
  — newest `*.tar.gz` should be < 24h old.
- **Is the site responding?** `curl -fsS https://<FORUM_DOMAIN>/srv/status` should return 200.
- **Any 5xx in nginx?** `./scripts/tail-logs.sh nginx`
- **Disk usage?** `df -h /var/discourse/shared` — alert at 70%.

## Common operator tasks

### Upgrade Discourse

Push a change to `main` and the CI/CD pipeline handles the rest:

```bash
# edit .env to bump DISCOURSE_VERSION, or change deploy/app.yml, etc.
git commit -am "chore: bump Discourse to vX.Y.Z"
git push origin main
```

The GitHub Actions workflow (`.github/workflows/deploy.yml`) will:
1. Lint all scripts and YAML
2. SSH to Hetzner via Ansible
3. Pull the latest repo to `/opt/tari-discourse`
4. Copy the `.env` from `ENV_PRODUCTION` secret
5. Run `install.sh` (re-renders `app.yml`, rebuilds the container)
6. Health-check `https://<FORUM_DOMAIN>/srv/status`

Expect ~5 minutes of downtime during rebuild on a 4 vCPU host.

**Manual fallback** (if CI is unavailable):

```bash
ssh root@178.105.25.174
cd /opt/tari-discourse
git pull
sudo ./scripts/rebuild.sh
```

`rebuild.sh` takes a fresh backup first, then re-runs `install.sh` which
re-renders `app.yml` and does `./launcher rebuild app`.

**Pin the version** in `.env` (`DISCOURSE_VERSION=<tag>`) for reproducible
rebuilds between scheduled upgrade windows.

### Add a plugin

1. Edit `deploy/app.yml` under `hooks.after_code` and add a `git clone` line.
2. Commit + push to `main`. The CI/CD pipeline will rebuild automatically.

Avoid pinning plugins to `master` — pin to a tag, or at least a commit, so
that rebuilds are reproducible.

### Reset an admin password

```bash
sudo /opt/tari-discourse/scripts/rotate-admin.sh user@tari.com
```

Prints a one-time reset URL *and* emails the user. Used at handover and any
time a credential is suspected compromised.

### Enter the Rails console

```bash
cd /var/discourse
sudo ./launcher enter app
rails c
```

Read-only reads are fine; writes should go through `SiteSetting` or model
methods, never raw SQL.

### Change a site setting

Prefer the Admin UI at `/admin/site_settings/`. Permanent settings should be
added to `deploy/seed-categories.rb` so they're re-applied on rebuild. If you
only set something in the UI, a rebuild will keep it (settings live in the
DB), but new environments won't pick it up.

### Promote/demote a user

Admin UI → Users → [username] → Admin → toggle Admin/Moderator, or set
Trust Level manually. Rules for auto-promote are documented in
[`TRUST_LEVELS.md`](TRUST_LEVELS.md).

## Monitoring

Discourse exposes `/srv/status` (unauthenticated, returns plain `ok`) for
liveness probes. Point any external monitor (UptimeRobot, Pingdom, Grafana
Synthetic) at `https://<FORUM_DOMAIN>/srv/status`.

The container exports Prometheus metrics on `:9405/metrics` when you include
`templates/web.prometheus.template.yml` in `app.yml`. Not enabled by default;
add only if/when Tari deploys a Prometheus server.

## Incident playbook

### "The site is down"

1. `ssh` to the host.
2. `docker ps` — is the `app` container running?
3. If not: `cd /var/discourse && ./launcher start app` and watch with
   `./scripts/tail-logs.sh rails`.
4. If crash-looping: check `./scripts/tail-logs.sh unicorn`. Most common
   crash cause is a bad plugin after a rebuild — revert the plugin change
   and rebuild.
5. If data corruption is suspected: stop the container, restore the newest
   good backup per [`BACKUP_RESTORE.md`](BACKUP_RESTORE.md), document the
   incident in the Staff category.

### "I need to take the site offline for maintenance"

```bash
cd /var/discourse
sudo ./launcher stop app
# ... do the thing ...
sudo ./launcher start app
```

For anything longer than a few minutes, flip the maintenance-mode setting
via Rails console first so users get a friendly banner:

```ruby
SiteSetting.maintenance_mode = true
```

### "I was pwned, rotate everything"

1. `sudo ./scripts/rotate-admin.sh <email>` for every admin.
2. Regenerate SMTP credentials at the provider, update `.env`, rebuild.
3. If S3 keys are suspected compromised, rotate via IAM, update `.env`, rebuild.
4. Force logout every user: `sudo ./launcher enter app` →
   `rails runner 'UserAuthToken.delete_all'`.
5. Announce in the Staff category with timestamp + scope.
