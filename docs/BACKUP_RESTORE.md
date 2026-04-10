# Backup & restore

The bounty brief explicitly requires that the forum is **backed up and
restore-tested**. This document describes both.

## What's backed up

Discourse's built-in backup bundles:

- The full Postgres database (schema + all content)
- All uploads (`/shared/uploads/`)
- Site settings
- Theme assets

The backup is a single `*.tar.gz` file written to
`/var/discourse/shared/standalone/backups/default/`.

**Not** included:

- `.env` and `containers/app.yml` — version-controlled in this repo, restored
  by running `install.sh`
- Container image — rebuilt from the pinned `DISCOURSE_VERSION` in `.env`
- TLS certs — re-issued automatically by Let's Encrypt on rebuild
- Cron jobs — re-installed by `install.sh`

## Schedule

| Layer | When | What | Where |
|-------|------|------|-------|
| Local | Nightly 03:17 UTC | Discourse `launcher backup app` | Host: `/var/discourse/shared/standalone/backups/default/` |
| Offsite | Same run | Newest backup copied to S3 | `s3://$S3_BACKUP_BUCKET/discourse/nightly/` |
| Restore drill | Sundays 04:30 UTC | Scratch container restore | Ephemeral — torn down after verification |

Retention:

- Local: **14 days** (tunable via `BACKUP_RETENTION_DAYS` in `.env`)
- Offsite: managed by an S3 lifecycle rule (recommended: 30 days Standard-IA,
  90 days Glacier, 1 year deep archive)

## Verifying a backup exists

```bash
ls -lht /var/discourse/shared/standalone/backups/default/ | head
tail /var/log/tari-discourse-backup.log
```

The newest file should be < 24h old and the log should end with
`nightly-backup done`.

## Manual backup (before risky ops)

```bash
cd /var/discourse
sudo ./launcher backup app
```

Prints the filename when done. Always do this before a rebuild, plugin
change, or upgrade — `scripts/rebuild.sh` wraps it automatically.

## Restore drill (automated)

```bash
sudo ./deploy/restore-test.sh
```

What it does:

1. Grabs the newest backup from `/var/discourse/shared/standalone/backups/default/`
2. Spins up a throwaway `app-restore-test` container on ports 8880/8443
   against a scratch shared volume
3. Runs `discourse restore <backup>` inside it
4. Hits `http://127.0.0.1:8880/srv/status` and asserts 200
5. Tears everything down and exits 0 on success

It **never** touches the production container or its data. Schedule it
weekly via cron (see `deploy/backup.yml`).

## Restore — production (panic mode)

1. Find the backup you want:

   ```bash
   ls -lht /var/discourse/shared/standalone/backups/default/
   ```

2. Enable restore (disabled by default as a safety net):

   ```bash
   cd /var/discourse
   sudo ./launcher enter app
   ```

   Inside the container:

   ```bash
   discourse enable_restore
   discourse restore <filename>.tar.gz
   ```

3. Exit the container and restart it:

   ```bash
   exit
   sudo ./launcher restart app
   ```

4. Smoke-test: `curl -fsS https://<FORUM_DOMAIN>/srv/status`

5. **Disable restore again** (defence in depth):

   ```bash
   sudo ./launcher enter app
   discourse disable_restore
   exit
   ```

## Restore — from S3 offsite

If the host itself is lost, provision a new one, run the installer fresh
using the same `.env` as the old host, then:

```bash
# On the new host, with the aws CLI configured
mkdir -p /var/discourse/shared/standalone/backups/default
aws s3 cp s3://$S3_BACKUP_BUCKET/discourse/nightly/<newest>.tar.gz \
  /var/discourse/shared/standalone/backups/default/
```

Then follow "Restore — production" above.

**Critical:** the restore host must have the same `DISCOURSE_HOSTNAME` as
the backup was taken on, otherwise avatars and upload URLs break. If you
need to change the hostname during a disaster recovery, use the official
[remap rake task](https://meta.discourse.org/t/rename-a-discourse-instance/24908)
after the restore completes.
