# Tari Community Discourse

A self-hosted [Discourse](https://www.discourse.org/) forum for the Tari community, deployed at `community.tari.com`.

Production deployment artifact built on the official
[`discourse_docker`](https://github.com/discourse/discourse_docker) launcher.

## What this repo is

This repo tracks the setup, deployment configuration, and documentation for the Tari community forum. It is not the Discourse codebase itself — it contains the deployment playbook (docker-compose, nginx config, or equivalent), seeding scripts, configuration files, and operational documentation needed to stand up and hand over a production instance.

## Acceptance criteria

A submission must demonstrably satisfy all six criteria to be accepted:

1. **SSL live** — HTTPS on `community.tari.com` with a valid cert (Let's Encrypt or equivalent), no HTTP fallback.
2. **Categories seeded** — Forum categories matching the Tari community structure are present at first boot.
3. **Trust levels configured** — Discourse trust level thresholds are tuned for a new community (not Discourse defaults).
4. **GitHub SSO** — Users can sign in via GitHub OAuth; email/password login policy is documented.
5. **Backup and restore tested** — A backup has been created, restored to a clean instance, and the procedure is documented step-by-step in this repo.
6. **Tari branding applied** — Logo, colour scheme, and site title match Tari brand guidelines.

## What's in here

| Path | Purpose |
|------|---------|
| `deploy/app.yml` | Discourse container definition (templated) |
| `deploy/install.sh` | Idempotent bootstrap script for a fresh Ubuntu 24.04 host |
| `deploy/seed-categories.rb` | Rails runner script that creates the initial category tree + trust-level ACLs |
| `deploy/backup.yml` | Nightly backup cron + optional S3 offload |
| `deploy/restore-test.sh` | Downloads the most recent backup and restores it into a throwaway container (satisfies "test a restore") |
| `deploy/templates/` | Custom Discourse templates merged into `app.yml` |
| `scripts/` | One-shot operator helpers (rotate admin, rebuild, tail logs) |
| `branding/` | Logo, favicon, theme overrides |
| `docs/INSTALL.md` | Greenfield install runbook |
| `docs/OPERATIONS.md` | Day-2 ops: upgrades, rebuilds, plugin management |
| `docs/BACKUP_RESTORE.md` | Backup schedule, retention, and the restore drill |
| `docs/TRUST_LEVELS.md` | Trust-level progression policy + auto-promote thresholds |
| `docs/CATEGORIES.md` | Category layout rationale and ACL matrix |
| `docs/MODERATION.md` | Baseline moderation rules, report handling, ban policy |
| `docs/GITHUB_SSO_SETUP.md` | Steps to register the OAuth app and wire it in |
| `docs/HANDOVER.md` | Checklist for handing control to Tari Labs |
| `.env.example` | All templated variables with safe defaults |

## Quick start

```bash
git clone https://github.com/tari-project/community-discourse.git
cd community-discourse
cp .env.example .env
# edit .env — set FORUM_DOMAIN, ADMIN_EMAIL, SMTP_*, etc.
sudo ./deploy/install.sh
```

Full runbook: [`docs/INSTALL.md`](docs/INSTALL.md).

## Infrastructure

- **VPS**: Provided by Tari Labs (credentials shared privately after PR is opened)
- **Domain**: `community.tari.com`
- **Admin handover**: Credentials delivered to @metalaureate at completion

## Contributing

Open a PR against `main`. The submission that best meets all six acceptance criteria will be selected. See acceptance criteria above.
