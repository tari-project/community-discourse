# Category layout

The seed script at `deploy/seed-categories.rb` creates the following
categories on first boot. Edits to that file propagate by re-running it
(the seeder is idempotent).

## Top-level tree

```
Announcements          (read-only for everyone, staff posts)
General Discussion     (everyone can post)
Technical              (everyone can post)
├── Node & Mining
├── Wallets
└── Development
Governance & Proposals (TL1+ can post)
Support                (everyone can post)
Marketplace            (TL2+ can post)
Lounge                 (TL3+ read/post, staff manage)
Staff                  (staff only)
```

## Per-category notes

### Announcements
Official news. Read-only for everyone except staff. Used for release
announcements, network upgrade notices, and security advisories. Pin
important topics; close old ones within 30 days of the event.

### General Discussion
The default town square. Use for anything on-topic that doesn't fit
elsewhere. Off-topic threads get recategorised (not deleted) to encourage
engagement.

### Technical
Parent category for implementation-level discussions. Three subcategories:

- **Node & Mining** — base node operation, RandomX performance, merge
  mining with Monero, hashrate troubleshooting.
- **Wallets** — console wallet, mobile, FFI, Ledger integration, seed
  recovery. Moderators must **always** warn users who paste seed phrases
  in the clear and edit/remove the phrase immediately.
- **Development** — building on Tari, RPC/gRPC, SDK, contributing to
  tari-project repos. Link to GitHub issues rather than hosting bug
  reports here.

### Governance & Proposals
TL1+ to post. Used for community proposals, parameter discussions,
upgrade debates. Every proposal topic should follow a template (staff
to create a pinned "How to write a proposal" post during handover).

### Support
Open posting so users who just signed up can ask for help. Expect the
highest volume of low-effort / repeat questions — staff should aggressively
link to existing threads and close duplicates. Consider enabling "solved"
plugin in future.

### Marketplace
TL2+ to post. Buy/sell/trade. Hard rules, enforced by moderators:

- No promotion of unaudited financial products
- No unregistered securities
- No "investment opportunities" that aren't actual product/service exchanges
- Scams → immediate ban, no second chances

### Lounge
TL3+ only (earned). Social space for regulars. Staff monitor but
intervene lightly. Serves as a reward for sustained participation.

### Staff
Private. Moderators and admins only. Used for incident response,
escalations, and coordination.

## Adding a new category

1. Edit `deploy/seed-categories.rb` — add a new `ensure_category(...)` call.
2. Commit + push.
3. On the host:
   ```bash
   cd /opt/tari-discourse
   git pull
   sudo cp deploy/seed-categories.rb /var/discourse/shared/standalone/tari-seed/
   sudo /var/discourse/launcher enter app
   su discourse -c 'cd $home && bundle exec rails runner /shared/tari-seed/seed-categories.rb'
   ```

Do **not** create categories via the admin UI alone — they'll be lost in
disaster recovery. Always codify in the seed script first, then apply.

## Deleting a category

Never delete — archive instead. Deletion loses the history and breaks
links. Use the admin UI → Category → Settings → Archive.
