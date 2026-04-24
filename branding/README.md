# Branding assets

Brand assets extracted from the official
[Tari Brand Kit](https://www.figma.com/design/S2KtBt1kvlWq1Mcn18d5x3/Tari-Brand-Kit)
on 2026-04-24.

See [STYLE_GUIDE.md](STYLE_GUIDE.md) for the full style guide with color
palette, typography specs, contrast review, and Discourse theme mapping.

## Available assets

| File | Format | Description |
|------|--------|-------------|
| `assets/tari-logo-black.svg` | SVG | Wordmark + diamond mark, dark on transparent |
| `assets/tari-logo-white.svg` | SVG | Wordmark + diamond mark, white on transparent |

## Still needed

| Asset | Source | Notes |
|-------|--------|-------|
| Favicon (512 x 512 PNG) | Extract diamond mark from SVG | Square crop |
| Apple touch icon (180 x 180 PNG) | Same | Square crop |
| Logo raster (400 x 124 PNG) | Export from SVG | Discourse header |
| Logo small (200 x 62 PNG) | Export from SVG | Mobile header |
| OpenGraph image (1200 x 630 PNG) | Custom composition | Social sharing |
| Druk Bold WOFF2 | [Dropbox](https://www.dropbox.com/scl/fi/s94un6pu0ugmphox1jbkn/DRUK-Font.zip?rlkey=2qtnep5h29il06mryx2vck75w&dl=0) | Self-hosted display font |

## How to install

1. Log in as admin, go to `/admin/site_settings/category/branding`
2. Upload each asset to its corresponding setting
3. Save and clear browser cache

## Theme colours

The correct brand colours (per the 2026 Brand Kit) are documented in
[STYLE_GUIDE.md](STYLE_GUIDE.md). Key values:

- Primary text: Ink `#040723`
- Background: Off White `#FBF1E9`
- Accent: Purple `#813BF5`
- Links: Azure `#0939CF` (better contrast than Purple for body text)
- Danger: Red `#FE2C3F`

To apply: `/admin/customize/colors` -- New -- set values per the
Discourse Theme Mapping table in the style guide.
