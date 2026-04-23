# Trust levels

Discourse has five trust levels, from TL0 (brand new) to TL4 (leader).
Promotion between TL0–TL3 is automatic based on the thresholds set in
`deploy/seed-categories.rb`. TL4 is manual, granted by staff.

## Summary

| Level | Name | How reached | Why it matters |
|-------|------|-------------|----------------|
| TL0 | New | Signed up | Throttled: 1 link, 1 image, 2 mentions per post. Can't flag, can't PM. |
| TL1 | Basic | 5 topics entered, 30 posts read, 10 min on site | Can flag, PM, upload images, post more links. |
| TL2 | Member | 15 days visited, 100 posts read, 20 topics entered, 1 like given+received, 3 replies | Can edit wiki posts, invite friends, post to Marketplace. |
| TL3 | Regular | Stringent 100-day rolling participation — see below | Can recategorise, rename, hide spam, sees the Lounge category. |
| TL4 | Leader | Manual grant by staff | Can edit any post, pin topics, close topics. |

## TL3 ("Regular") thresholds

Over any rolling 100-day window a user must have:

- Visited on at least **50** days
- Replied to at least **10** topics
- Viewed at least **25** topics
- Read at least **500** posts
- Given at least **30** likes
- Received at least **20** likes
- No silences/suspensions in the window
- No flag-rejections in the window

TL3 is a **rolling** status: fall below any threshold and the user is
demoted back to TL2 automatically. This keeps Regulars active.

## Why these numbers

The defaults are conservative but achievable for anyone who genuinely
participates. They exist to:

1. Rate-limit brand-new accounts so spam/phishing attacks can't immediately
   drop links into every thread (TL0 restrictions).
2. Gate Governance & Marketplace to users with skin in the game (TL1/TL2).
3. Reserve the Lounge as a community-earned space (TL3).
4. Allow staff to delegate light moderation (soft-hide, recategorise) to
   trusted regulars (TL3) without handing out moderator powers.

## Auto-silencing new users

If **3** separate users flag a new-user's post as spam/off-topic, that user
is automatically silenced (cannot post) pending staff review. Controlled by
`num_users_to_silence_new_user` in the seeder.

## Overriding

Staff can:

- Manually set a user's trust level from their admin page. Overrides the
  automatic calculation until the user meets the criteria for a higher TL.
- Lock a trust level so the automatic system can't change it —
  useful for VIP accounts (Tari core devs) who should always be TL3+.

Document all manual TL overrides in the Staff category with a reason.
