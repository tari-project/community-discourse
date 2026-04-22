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
├── Client Development
└── Core Development
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
Parent category for implementation-level discussions. Four subcategories:

- **Node & Mining** — base node operation, mining-lane selection,
  merge mining with Monero, hashrate troubleshooting.
- **Wallets** — console wallet, mobile, FFI, Ledger integration, seed
  recovery. Moderators must **always** warn users who paste seed phrases
  in the clear and edit/remove the phrase immediately.
- **Client Development** — building apps and services *on* Tari: RPC/gRPC,
  wallet SDK, Ootle smart contracts, libraries, integrations. Link to
  GitHub issues rather than hosting bug reports here.
- **Core Development** — contributing *to* Tari itself: protocol,
  consensus, cryptography, contract/templating features, and
  tari-project repos.

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
TL2+ to post. Intended for concrete goods-and-services trades: hardware
(ASICs, Ledgers, used mining rigs), paid consulting/dev work, and
community merchandise. It is **not** a place to advertise tokens,
indices, staking products, or any "put money in, get money out" scheme.

Hard rules, enforced by moderators:

- **No unaudited financial products.** In this rule, "financial product"
  means anything whose value proposition is monetary return (a token
  sale, a yield product, an index, a vault, a staking-as-a-service
  offer, etc.). This explicitly includes Tari-adjacent projects: the
  core protocol itself is out of scope, but derivative tokens, wrapped
  representations, and investment funds built on top of Tari are not
  exempt.
- **No unregistered securities.** If a posting would need a prospectus
  to be legal in your jurisdiction, don't post it.
- **No pseudo-investments disguised as sales.** "Buy my $X membership
  and earn passive income" is an investment product, not a trade,
  regardless of how it's framed.
- **Scams → immediate ban.** "Scam" is a subjective judgement call made
  by the staff moderators (not an automated rule and not subject to
  community vote). Staff will lean on these heuristics: deceptive claims
  about yield/return, impersonation of Tari or its contributors,
  recovery-phrase phishing, and known rug patterns. Borderline cases
  should be raised in the Staff category before the ban lands; once
  actioned, the ban is final.

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

Prefer codifying every category in the seed script before creating it
in the admin UI. The UI path works — and categories *are* included in
Discourse's Postgres backup, so a normal DB restore does bring them
back — but ad-hoc UI changes are opaque to code review, aren't
rediscoverable on a fresh install, and drift silently between
environments. Keeping the seed script authoritative means a green-field
install stands up identically to production, and every category change
leaves a commit trail.

## Deleting a category

Never delete — archive instead. Deletion loses the history and breaks
links. Use the admin UI → Category → Settings → Archive.
