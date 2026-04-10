# Branding assets

Placeholder directory. Final assets to be provided by Tari at handover
time, or created from the official brand guide.

## Required assets

| File | Used at | Recommended dimensions |
|------|---------|-----------------------|
| `logo.png` | Header on desktop | 400 × 100 px, transparent PNG |
| `logo-small.png` | Header on mobile / condensed | 200 × 50 px, transparent PNG |
| `favicon.png` | Browser tab | 512 × 512 px, square PNG |
| `apple-touch-icon.png` | iOS add-to-home | 180 × 180 px, square PNG |
| `large-icon.png` | Splash screens | 512 × 512 px, square PNG |
| `opengraph-image.png` | Social sharing previews | 1200 × 630 px, PNG/JPG |

## How to install

Once the files exist in this directory, upload them through the Discourse
admin UI:

1. Log in as admin → `/admin/site_settings/category/branding`
2. For each setting below, click the upload button and pick the
   corresponding file from this directory:

   - `logo` → `logo.png`
   - `logo small` → `logo-small.png`
   - `favicon` → `favicon.png`
   - `apple touch icon` → `apple-touch-icon.png`
   - `large icon` → `large-icon.png`
   - `opengraph image` → `opengraph-image.png`

3. Save. Clear browser cache to verify.

## Theme colours

The seed script sets category colours to Tari brand red (`#BF1E2E`) and
complementary accents. To change the base theme colour scheme:

`/admin/customize/colors` → **New** → copy an existing scheme → adjust.

Document any theme customisations in a `branding/theme.scss` file in this
repo so they survive disaster recovery.
