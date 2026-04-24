# Tari Community Forum -- Style Guide

Extracted from the [Tari Brand Kit](https://www.figma.com/design/S2KtBt1kvlWq1Mcn18d5x3/Tari-Brand-Kit?node-id=0-1) on 2026-04-24.

---

## 1. Logo

The Tari logo consists of a geometric diamond "T" mark and the "TARI" wordmark.

| Variant | File | Usage |
|---------|------|-------|
| Black (on light backgrounds) | `assets/tari-logo-black.svg` | Default header, light themes |
| White (on dark backgrounds) | `assets/tari-logo-white.svg` | Dark themes, dark hero sections |

Both are vector SVGs (511 x 159 native). For Discourse uploads, export at required raster sizes:

| Discourse setting | Source | Recommended size |
|-------------------|--------|-----------------|
| `logo` | tari-logo-black.svg | 400 x 124 px PNG |
| `logo_small` | tari-logo-black.svg | 200 x 62 px PNG |
| `favicon` | Diamond mark only | 512 x 512 px PNG |
| `apple_touch_icon` | Diamond mark only | 180 x 180 px PNG |
| `large_icon` | Diamond mark only | 512 x 512 px PNG |
| `opengraph_image` | Custom composition | 1200 x 630 px PNG |

> **Note:** The diamond "T" mark should be extracted separately for square icon uses
> (favicon, touch icon). The full wordmark is too wide for square formats.

---

## 2. Color Palette

### Primary Colors

| Name | Hex | RGB | CSS Variable | Usage |
|------|-----|-----|-------------|-------|
| **Cloud** | `#ECEEFF` | 236, 238, 255 | `--cloud` | Light backgrounds, cards |
| **Ink** | `#040723` | 4, 7, 35 | `--dark-blue` | Primary text, dark backgrounds |
| **Purple** | `#813BF5` | 129, 59, 245 | `--purple` | Accent, links, CTAs |
| **Green** | `#C9EB00` | 200, 235, 0 | `--green` | Highlights, success states |

### Secondary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Red** | `#FE2C3F` | 254, 44, 63 | Alerts, warnings, category accent |
| **Azure** | `#0939CF` | 9, 57, 207 | Links (alternative), info states |
| **Yellow** | `#EBC216` | 235, 194, 22 | Badges, attention |
| **Glitch Gradient** | see below | -- | Hero sections, decorative |

### Neutral Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Steel** | `#67697C` | 103, 105, 124 | Muted text, footers |
| **Light Frost** | `#D3D7DE` | 211, 215, 222 | Borders, dividers |
| **Beige** | `#F6E6D4` | 246, 230, 212 | Warm backgrounds |
| **Off White** | `#FBF1E9` | 251, 241, 233 | Page background (brand default) |
| **MoVi Ink** | `#0D1018` | 13, 16, 24 | Deepest dark (near-black) |

### Glitch Gradient

```css
background: linear-gradient(
  90deg,
  #DE1527 0%,
  #6B227F 25.35%,
  #0638DF 50.1%,
  #40709C 75.23%,
  #C3F52C 100%
);
```

---

## 3. Typography

### Brand Typefaces

| Role | Family | Weight | Source |
|------|--------|--------|--------|
| **Primary (Display)** | Druk LCG | Bold, Medium | [Dropbox download](https://www.dropbox.com/scl/fi/s94un6pu0ugmphox1jbkn/DRUK-Font.zip?rlkey=2qtnep5h29il06mryx2vck75w&dl=0) |
| **Secondary (UI/Body)** | Poppins | Regular 400, Medium 500, SemiBold 600, Bold 700 | [Google Fonts](https://fonts.google.com/specimen/Poppins) |

### Brand Kit Typography Specs (from Figma)

| Scale | Family | Weight | Size | Line Height | Letter Spacing |
|-------|--------|--------|------|-------------|----------------|
| Scale-32 | Poppins | Medium 500 | 32px | 1.3 (130%) | -1px |
| Scale-21 | Poppins | Medium 500 | 21px | 1.4 (140%) | -1px |
| Display | Druk LCG | Bold | 300px+ | 0.93 (93%) | 0 |
| Cities (Druk) | Druk LCG | Medium | 164px | 1.0 | +6.56px |
| Cities (Poppins) | Poppins | SemiBold | 164px | 1.0 | -3.28px |
| Body labels | Poppins | Regular 400 | ~17px | 0.79-1.27 | 0 |

---

## 4. Legibility Review for Discourse

The Tari brand kit is designed for **marketing and presentation contexts** -- large
display type, hero sections, brand decks. A community forum has very different needs:
long-form reading, code blocks, dense navigation, and small UI labels.

### Issues and Recommendations

#### 4a. Druk is wrong for forum body text

**Druk** is a condensed display face. It's designed for headlines at 100px+ and becomes
hard to read below ~24px. It has extremely tight vertical proportions and minimal
x-height.

**Recommendation:** Use Druk **only** for the forum banner/hero (if any) and major
section headers. Never for body text, post content, category names, or navigation.

#### 4b. Poppins needs careful size/weight tuning

Poppins is a geometric sans-serif with relatively uniform stroke width. At small sizes
(12-14px), the geometric letterforms can feel "samey" and reduce character
differentiation compared to humanist alternatives (like Inter or Source Sans).

**Recommendations for Discourse:**

| Element | Font | Weight | Size | Line Height | Notes |
|---------|------|--------|------|-------------|-------|
| Page title / hero | Poppins | Bold 700 | 28-32px | 1.3 | Can also use Druk Bold |
| Category headers | Poppins | SemiBold 600 | 20-24px | 1.3 | Uppercase sparingly |
| Topic titles (list) | Poppins | Medium 500 | 16-18px | 1.4 | |
| Post body | Poppins | Regular 400 | 16px | 1.6 | **Increase line height from brand's 1.27 to 1.6** |
| Post body (mobile) | Poppins | Regular 400 | 15px | 1.5 | |
| Small UI / metadata | Poppins | Regular 400 | 13-14px | 1.4 | Timestamps, user badges |
| Code blocks | System monospace | Regular | 14px | 1.5 | Don't override with Poppins |

#### 4c. Line height is too tight in brand spec

The brand kit uses line heights of 0.79-1.0 for display and 1.27-1.4 for body. For
a forum with multi-paragraph posts:

- **Body text:** bump to **1.6** (standard for long-form web reading)
- **Headings:** 1.3 is fine
- **UI labels/nav:** 1.4 is fine

#### 4d. Letter spacing: loosen at small sizes

The brand kit uses -1px letter spacing at 21px and 32px. This is aggressive. At forum
body sizes (14-16px), negative tracking hurts legibility.

**Recommendation:**
- **16px body:** `letter-spacing: 0` or `0.01em`
- **20-24px headings:** `letter-spacing: -0.02em` (subtle tightening OK)
- **32px+ display:** `letter-spacing: -0.03em` (matches brand intent)

#### 4e. Color contrast

| Combination | Contrast Ratio | WCAG AA (normal) | WCAG AA (large) |
|-------------|---------------|------------------|-----------------|
| Ink `#040723` on Off White `#FBF1E9` | ~16.8:1 | Pass | Pass |
| Ink `#040723` on Cloud `#ECEEFF` | ~16.2:1 | Pass | Pass |
| Purple `#813BF5` on Off White `#FBF1E9` | ~3.9:1 | **Fail** | Pass |
| Purple `#813BF5` on Ink `#040723` | ~4.3:1 | Pass (barely) | Pass |
| Green `#C9EB00` on Ink `#040723` | ~10.5:1 | Pass | Pass |
| Green `#C9EB00` on Off White `#FBF1E9` | ~1.6:1 | **Fail** | **Fail** |
| Steel `#67697C` on Off White `#FBF1E9` | ~4.6:1 | Pass | Pass |
| Red `#FE2C3F` on Off White `#FBF1E9` | ~4.0:1 | **Fail** | Pass |

**Key issues:**
- **Purple on light backgrounds fails AA for normal text.** Use only for large text
  (18px+ bold, 24px+ regular) or interactive elements with additional visual cues.
  For links in body text, prefer Azure `#0939CF` (contrast ~8.5:1 on Off White).
- **Green on light backgrounds is invisible.** Never use Green text on light.
  Green works only on dark (Ink) backgrounds.
- **Red on light backgrounds is marginal.** OK for badges/icons, not for body text.

#### 4f. Background color

The brand default `#FBF1E9` (Off White / warm cream) is distinctive but unusual for
a forum. Consider:

- **Option A:** Use Off White as the page bg to stay on-brand. Works well.
- **Option B:** Use white `#FFFFFF` for post content areas with Off White for the
  surrounding chrome. Improves readability for long posts.
- **Option C:** Use Cloud `#ECEEFF` for a cooler feel that still feels branded.

All three work. Option A is recommended for strongest brand alignment.

---

## 5. Discourse Theme Mapping

For the Discourse admin color scheme (`/admin/customize/colors`):

| Discourse Setting | Tari Token | Hex |
|-------------------|-----------|-----|
| `primary` (text) | Ink | `#040723` |
| `secondary` (background) | Off White | `#FBF1E9` |
| `tertiary` (links) | Azure | `#0939CF` |
| `quaternary` (navigation) | Purple | `#813BF5` |
| `header_background` | Ink | `#040723` |
| `header_primary` (header text) | Cloud | `#ECEEFF` |
| `highlight` | Yellow | `#EBC216` |
| `danger` | Red | `#FE2C3F` |
| `success` | Green (on dark) | `#C9EB00` |
| `love` (like button) | Purple | `#813BF5` |

> **Why Azure for links instead of Purple?** Purple `#813BF5` on Off White `#FBF1E9`
> only achieves ~3.9:1 contrast -- below WCAG AA for normal body text. Azure `#0939CF`
> achieves ~8.5:1 and still feels on-brand. Use Purple for large interactive elements
> (buttons, nav highlights) where the larger size compensates.

---

## 6. Font Loading (Discourse Theme)

```scss
// In theme SCSS or component
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap');

// Druk must be self-hosted (not on Google Fonts)
// Upload Druk Bold WOFF2 via Discourse theme assets, then:
@font-face {
  font-family: 'Druk';
  src: url($druk-bold-woff2) format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}

html {
  font-family: 'Poppins', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
}

// Use Druk only for banner/display
.custom-banner-title,
.category-page-hero h1 {
  font-family: 'Druk', 'Poppins', sans-serif;
  text-transform: uppercase;
  letter-spacing: -0.03em;
}
```

---

## 7. Asset Checklist

| Asset | Status | Notes |
|-------|--------|-------|
| Logo (black SVG) | Done | `assets/tari-logo-black.svg` |
| Logo (white SVG) | Done | `assets/tari-logo-white.svg` |
| Diamond mark (square) | Needed | Extract from SVG for favicon/icons |
| Logo (400x124 PNG) | Needed | Export from SVG |
| Logo small (200x62 PNG) | Needed | Export from SVG |
| Favicon (512x512 PNG) | Needed | Diamond mark only |
| Apple touch icon (180x180) | Needed | Diamond mark only |
| Large icon (512x512) | Needed | Diamond mark only |
| OpenGraph image (1200x630) | Needed | Custom composition needed |
| Druk Bold WOFF2 | Needed | Download from Dropbox, convert |
| Poppins WOFF2 | Not needed | Use Google Fonts CDN |

---

## References

- Figma Brand Kit: https://www.figma.com/design/S2KtBt1kvlWq1Mcn18d5x3/Tari-Brand-Kit
- Druk Font: https://www.dropbox.com/scl/fi/s94un6pu0ugmphox1jbkn/DRUK-Font.zip?rlkey=2qtnep5h29il06mryx2vck75w&dl=0
- Poppins: https://fonts.google.com/specimen/Poppins
- Animated Logo: https://www.dropbox.com/scl/fo/ogtfljw4sx9i8z2m8ezlp/AJE_oWzuZ9khfn5dVAioMEw?rlkey=a677v0lsjc9otabxbmam8x1dq&e=2&dl=0
