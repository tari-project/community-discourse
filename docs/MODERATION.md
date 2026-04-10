# Moderation rules

Baseline rules the Tari forum launches with. Staff may revise after the
community grows — but these are the defaults on day 1.

## The four posting rules

1. **Be civil.** Disagree with the argument, not the person. No slurs, no
   doxxing, no threats, no personal attacks. One warning, then a 24-hour
   silence, then a 7-day silence, then a ban.

2. **No spam, no scams.** Unsolicited promotion, affiliate links, referral
   codes, "investment opportunities", airdrops, and token sales that aren't
   official Tari announcements are all spam. Scams → immediate permanent ban.

3. **No unsolicited financial advice.** "Buy X" or "Sell Y" posts get
   recategorised or closed. Discussion of market dynamics, tokenomics, and
   on-chain analysis is fine.

4. **Stay on-topic per category.** Off-topic posts get moved, not deleted.
   Repeated off-topic posting → 7-day silence.

## Seed phrase safety

**Hard rule, no exceptions:** if a user pastes a seed phrase in the clear
anywhere on the forum, a moderator must:

1. Edit the post **immediately** to remove the phrase, replacing it with
   `[seed redacted by moderator]`.
2. Send the user a PM warning them that the funds associated with that seed
   should be considered compromised — any attacker watching the forum
   could have captured it before the edit.
3. Log the incident in the Staff category.

This rule is so important it overrides "don't edit users' posts without
permission". Seed-phrase exposure is a financial-loss event and staff are
authorised to mitigate it without asking.

## Handling flags

Flags come in five flavours:

| Flag | Who can use it | Action |
|------|----------------|--------|
| Off-topic | TL1+ | Recategorise if valid, dismiss otherwise |
| Inappropriate | TL1+ | Warn + edit/hide if valid |
| Spam | TL1+ | Hide post, silence user if TL0, ban if repeat |
| Something else | TL1+ | Staff review, no automation |
| Take action (urgent) | TL3+ staff | Immediate hide pending staff review |

Auto-actions, configured in the seeder:

- 5 unique flags on one post → post auto-hidden pending staff review
- 3 distinct users flag posts from a TL0 account → user auto-silenced
- A silenced user's subsequent posts enter the moderation queue by default

## Ban policy

| Offence | First time | Second time | Third time |
|---------|-----------|-------------|-----------|
| Off-topic spam | Warning + delete | 7-day silence | 30-day silence |
| Personal attacks | 24h silence | 7-day silence | Permanent ban |
| Doxxing | Permanent ban | — | — |
| Scams / phishing | Permanent ban | — | — |
| Ban evasion | Permanent ban + IP block | — | — |
| Seed phrase harvesting (soliciting users to post seeds) | Permanent ban | — | — |

Bans are announced to the banned user via PM explaining the reason and any
appeal path. Document every permanent ban in the Staff category with the
reason and a link to the triggering post(s).

## Appeals

Banned users can appeal via email to `moderation@<FORUM_DOMAIN>` (set up
during handover). Appeals are reviewed by at least two staff members.
Reversed bans are documented in the Staff category.

## Moderator etiquette

- **Sign every staff action.** If you edit or hide a post, leave a
  moderator note saying why.
- **Don't moderate threads you're actively arguing in.** Ask another mod
  to review.
- **Prefer soft-hide over delete.** Deletes lose history; hides preserve
  it for audit.
- **Read the room.** A thread that's heating up is better cooled with a
  pinned reply than with closures.
