# Just Euchre — Design Guide

> Last updated: March 2026

---

## 1. Design Philosophy

**Dark. Precise. Focused.**

Just Euchre strips everything down to the game. The design system follows the same rule: every decision should either serve the game or get out of the way. No decoration for its own sake.

Key principles:
- **One accent, used sparingly.** Mint (`#52F6AA`) does all the interactive heavy lifting. Everything else is neutral.
- **Surfaces, not shadows.** Depth comes from layered dark surfaces, not drop shadows or gradients.
- **System fonts, always.** San Francisco (via `-apple-system`) is the typeface on all platforms. It's native, legible, and fast.
- **Calm transitions.** Animations are 150ms, functional, and never decorative.

---

## 2. Color Tokens

### CSS Custom Properties

```css
:root {
  --bg:      #080B12;   /* Page background */
  --surface: #1A212C;   /* Cards, panels */
  --pill:    #161C26;   /* Pill buttons, subtle containers */
  --mint:    #52F6AA;   /* Primary accent */
  --red:     #FB595E;   /* Suits (hearts/diamonds), error/loss */
  --gold:    #FDD758;   /* Crown, achievements */
  --white:   #FFFFFF;   /* Primary text */
  --muted:   #B8B8B8;   /* Secondary text */
  --subtle:  #8C8C8C;   /* Tertiary text */
  --border:  #474747;   /* Borders, dividers */
  --radius:  14px;      /* Standard corner radius */
}
```

### iOS (Swift) — Theme Struct

```swift
static let background    = UIColor(r: 8,   g: 11,  b: 18)   // #080B12
static let surface       = UIColor(r: 26,  g: 33,  b: 44)   // #1A212C
static let cardBackground = UIColor(r: 252, g: 252, b: 252) // #FCFCFC
static let pillBackground = UIColor(r: 22,  g: 28,  b: 38)  // #161C26
static let pillBorder    = UIColor(white: 0.28)               // #474747
static let accent        = UIColor(r: 82,  g: 246, b: 170)  // #52F6AA
static let accentRed     = UIColor(r: 250, g: 89,  b: 67)   // #FA5943
static let crown         = UIColor(r: 250, g: 214, b: 89)   // #FAD659
static let mutedText     = UIColor(white: 0.72)               // #B8B8B8
static let ink           = UIColor(white: 0.12)               // #1F1F1F
```

### Semantic Color Roles

| Token | Use cases |
|-------|-----------|
| `--bg` | Page/screen background. The lowest layer. |
| `--surface` | Cards, modals, feature tiles, elevated containers. |
| `--pill` | Inline pill buttons, tags, subtle containers that sit on `--surface`. |
| `--mint` | Primary CTA buttons, active states, success/win feedback, streak highlights. |
| `--red` | Hearts/diamonds suit marks, loss states, error messages. |
| `--gold` | Crown icon, loner-mode callouts, achievement highlights. |
| `--white` | All primary body text, headlines, icon fills. |
| `--muted` | Supporting text, metadata, card subtitles. |
| `--subtle` | Footer text, timestamps, labels that should recede. |
| `--border` | 1px dividers on cards, nav border-bottom, input outlines. |

---

## 3. Typography

### Font Stack

```css
font-family: -apple-system, system-ui, "Helvetica Neue", sans-serif;
```

No web fonts are loaded. This is intentional — no flash of unstyled text, no extra requests, native rendering on Apple devices.

### Type Scale

| Name | Size | Weight | Letter-spacing | Line-height |
|------|------|--------|----------------|-------------|
| `hero` | `clamp(38px, 5.5vw, 56px)` | 700 | -1.5px | 1.1 |
| `section-title` | `clamp(26px, 4vw, 36px)` | 700 | -0.5px | 1.2 |
| `card-title` | 20–22px | 600 | 0 | 1.3 |
| `body` | 16px | 400 | 0 | 1.5 |
| `subtitle` | 13–14px | 500 | 0 | 1.4 |
| `label` | 12px | 700 | 1.5px | 1 |

Labels are always `text-transform: uppercase`.

### Rendering

Always set `-webkit-font-smoothing: antialiased` on the body. This is already in the base CSS and must be preserved across all web pages.

---

## 4. Spacing System

Spacing follows a base-4 scale with a few semantic exceptions:

| Token | Value | Common use |
|-------|-------|------------|
| `4px` | 4px | Icon-to-label gap, tight inline spacing |
| `8px` | 8px | Between list items, icon padding |
| `12px` | 12px | Card internal padding (tight) |
| `16px` | 16px | Standard card padding, button padding |
| `20px` | 20px | Section sub-gaps |
| `24px` | 24px | Page horizontal padding |
| `28px` | 28px | Card vertical padding |
| `48px` | 48px | Between content blocks within a section |
| `64px` | 64px | Between major sections (web) |
| `80px` | 80px | Section top/bottom padding (web) |

---

## 5. Border Radius

| Token | Value | Use |
|-------|-------|-----|
| `--radius` | `14px` | Standard card/tile radius |
| `7px` | `7px` | Small icons, nav icon |
| `100px` | `100px` | Pill buttons, tags |
| `30–36px` | `30–36px` | Phone mockup frame |

---

## 6. Components

### Buttons

**Primary (Mint)**
```css
background: var(--mint);
color: #000;
font-size: 13px;
font-weight: 700;
letter-spacing: 0.3px;
padding: 10px 18px;
border-radius: 100px;
border: none;
```
Use for primary CTAs — "Download on the App Store", primary confirmations.

**Secondary (Pill)**
```css
background: var(--pill);
color: var(--white);
font-size: 13px;
font-weight: 600;
padding: 8px 16px;
border-radius: 100px;
border: 1px solid var(--border);
```
Use for secondary actions, navigation pills, inline links.

**Hover state:** `opacity: 0.85` on both. No color changes on hover.

---

### Cards / Surface Tiles

```css
background: var(--surface);
border-radius: var(--radius);  /* 14px */
padding: 20–28px;
border: 1px solid var(--border);  /* optional — use on elevated/floating cards */
```

Cards sit on `--bg`. Nesting (card within a card) should be avoided unless a `--pill` background is used for the inner element.

---

### Navigation Bar

```
height: 56px
background: var(--bg)
border-bottom: 1px solid var(--border)
position: sticky, top: 0
z-index: 100
```

Contents: brand mark (icon + wordmark) on the left, primary CTA button on the right. No other items.

---

### Suit Symbols in UI

Suit symbols (♠ ♥ ♦ ♣) are rendered as Unicode characters, never as image assets on the web.

```html
<span style="color: var(--white)">♠</span>
<span style="color: var(--red)">♥</span>
<span style="color: var(--red)">♦</span>
<span style="color: var(--white)">♣</span>
```

Font size depends on context. In the footer they appear at ~18px with `opacity: 0.5`.

---

### Phone Mockup (Marketing)

Used on the landing page hero to frame app screenshots.

```css
width: 240px;
aspect-ratio: 9 / 19.5;
border-radius: 36px;
border: 2px solid var(--mint);
background: var(--bg);
overflow: hidden;
```

The mint border is the only place mint is used as a structural/decorative border rather than interactive feedback.

---

## 7. Layout

### Container

```css
.container {
  width: 100%;
  max-width: 960px;
  margin: 0 auto;
  padding: 0 24px;
}
```

All page content is constrained to 960px. Do not widen this for marketing pages — the narrow, focused layout is intentional.

### Grid Patterns

**2-column feature grid (desktop → 1-column mobile)**
```css
display: grid;
grid-template-columns: repeat(2, 1fr);
gap: 16px;

@media (max-width: 700px) {
  grid-template-columns: 1fr;
}
```

**Centered hero stack**
```css
display: flex;
flex-direction: column;
align-items: center;
text-align: center;
gap: 20–28px;
```

### Breakpoints

| Breakpoint | Value | Notes |
|------------|-------|-------|
| Tablet/mobile | `700px` | Grid collapses to single column |
| Small mobile | `440px` | Reduce padding, smaller font sizes |

---

## 8. Animation & Motion

Keep motion calm and purposeful. Just Euchre does not use decorative animations.

| Property | Value |
|----------|-------|
| Standard transition | `0.15s ease` |
| Hover opacity | `opacity: 0.85` |
| Scroll behavior | `scroll-behavior: smooth` |

Do not use:
- Entrance animations / scroll-triggered reveals
- Skeleton loaders on static content
- Looping animations in marketing
- Spring/bounce physics

---

## 9. Elevation Model

Depth is expressed through layered dark surfaces, not shadows.

| Layer | Background | Z-level |
|-------|------------|---------|
| Page | `#080B12` | 0 |
| Surface (cards, panels) | `#1A212C` | 1 |
| Pill / inner container | `#161C26` | 2 |
| Playing card face | `#FCFCFC` | 3 (game only) |

**No `box-shadow` in general UI.** If a component needs visual separation, use a `1px solid var(--border)` outline, not a shadow.

---

## 10. Accessibility

- **Contrast:** White text on `--bg` exceeds WCAG AA (contrast ratio ~16:1). Muted text (`#B8B8B8`) on `--bg` is ~6.5:1 — AA compliant.
- **Tap targets:** Minimum 44×44px on iOS (Apple HIG). Web buttons are a minimum of 36px height.
- **Focus states:** Native browser focus rings are not suppressed. Do not add `outline: none` without providing a custom focus indicator.
- **Fonts:** System fonts render at native OS quality and respect user font size settings.
- **Reduced motion:** If adding new animations, respect `@media (prefers-reduced-motion: reduce)`.

---

## 11. What to Avoid

| Avoid | Reason |
|-------|--------|
| Light backgrounds | Brand is dark-only; no light mode exists |
| Drop shadows | Use surface layering instead |
| Gradient fills | Keep surfaces flat; gradients add noise |
| Rounded corners > 36px (non-pill) | Looks inflated; reserve for phone mockups |
| Multiple accent colors in one view | Mint is the only interactive accent |
| Decorative icons/emoji in UI | Suit symbols are functional; avoid decorative emoji |
| External web fonts | System font stack only |
| Animations > 300ms | Keep UI feeling instant |
