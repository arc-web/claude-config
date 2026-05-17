# therappc - Palette + Typography Rethink + Tooling Fix

## Context

The dry run with `web-audience.md` exposed that therappc.com uses the wrong palette and typography for its audience. Root cause is in the tooling itself - three structural gaps caused the agent to default to Warm/Gold (the only fully-tokenized palette) without audience-specific research. Both the tooling and the site need fixing together.

---

## Part 1 - Tooling Fixes

### Gap 1: Only Warm/Gold has full CSS tokens

`web-audience.md` lists 3 other palettes (Clinical Teal, Dark Precision, Warm Dark) as hex lists with no CSS custom properties, shadows, border colors, or radius tokens. Agent always defaults to the only tokenized one.

**Fix:** Add full token set to each named palette in `web-audience.md`. Also add the new Therapist/Sage palette (see below) to both `web-audience.md` and `web-design.md`.

---

### Gap 2: No competitor research step

Neither file requires the agent to look at actual sites in the specific sub-industry before picking a palette.

**Fix:** Add explicit Step 0 to `web-audience.md` Section 1:
> "Before picking any palette: find 5 sites used by the exact target audience (not the archetype broadly - the specific niche). Screenshot their color, type, and tone. Ask: do they feel like the client wants to feel? What's the gap the client could own?"

---

### Gap 3: Therapy treated as monolithic

"Care Seeker - therapy" is a single node with no sub-categories. Trauma-informed practice ≠ psychiatric clinic ≠ group therapy practice ≠ therapist coaching agency.

**Fix:** Add therapy sub-category matrix to Care Seeker section:

| Therapy positioning | Color direction | Typography signal |
|---|---|---|
| Warm/holistic/healing-focused | Sage + warm cream | Rounded humanist sans (Nunito, Plus Jakarta Sans) |
| Evidence-based/clinical | Soft teal + cool white | Clean sans (DM Sans, Lato) |
| Trauma-informed | Muted sage + dusty rose | Very rounded, soft (Nunito, Quicksand) |
| Executive/psychiatry/medical | Navy + cool grey | Structured sans (Manrope, Source Sans Pro) |
| PPC agency *for* therapists | Warm professional + nature accent | Authoritative serif heading + neutral body |

The last row is exactly therappc.com - an agency targeting therapist practice owners. Different again from the therapy practice itself: needs to feel like a trusted professional peer, not a clinical service.

---

### New Named Palette: Therapist/Sage

For any brand targeting mental health professionals or positioning within the therapy/wellness professional space. Full token set:

```css
/* ── Palette: Therapist / Sage ─────────────────────────────────────────── */
:root {
  /* Backgrounds */
  --bg:          #F5F0E8;   /* warm cream - calm, grounded */
  --bg-2:        #EDE8DC;   /* slightly deeper cream */
  --bg-3:        #E0D8CC;   /* section separator */
  --bg-dark:     #1E2D2A;   /* deep forest - authoritative, calm */
  --bg-dark-2:   #162320;   /* darkest - footer, nav */

  /* Accent - sage green (growth, healing, nature) */
  --sage:        #6B8F71;   /* primary accent */
  --sage-hover:  #527060;   /* hover state */
  --sage-dim:    #8FAF95;   /* lighter sage for dark sections */

  /* Warm accent - dusty terracotta (earthy, human) */
  --terra:       #B87355;   /* warm secondary accent */
  --terra-dim:   #D49070;   /* lighter on dark */

  /* Text */
  --ink:         #2C2A26;   /* near-black warm */
  --ink-soft:    #5C5850;   /* body text muted */
  --muted:       #5C5850;
  --muted-2:     #8A8478;
  --on-dark:     #EDE8DC;   /* text on dark sections */
  --on-dark-2:   rgba(237,232,220,0.65);
  --on-dark-3:   rgba(237,232,220,0.35);

  /* Lines and borders */
  --line:        rgba(107,143,113,0.22);   /* sage-tinted border */
  --line-soft:   rgba(44,42,38,0.07);
  --line-dark:   rgba(237,232,220,0.12);

  /* Shadows */
  --shadow:      0 20px 50px -15px rgba(30,45,42,0.15);
  --shadow-sm:   0 4px 20px rgba(30,45,42,0.08);

  /* Radii */
  --radius:      10px;
  --radius-lg:   16px;
  --radius-pill: 50px;

  /* Layout */
  --max-w:       1160px;
}
```

**Button primary on this palette:** sage fill `#6B8F71` → `#527060` hover, white text.
**Dark section accent:** `--terra-dim` (`#D49070`) on dark backgrounds for warmth against forest green.

---

### New Typography for Therapist/Sage

| Role | Font | Weight | Notes |
|---|---|---|---|
| Heading | Plus Jakarta Sans | 700, 800 | Rounded humanist geometric - approachable authority |
| Body | Source Sans Pro | 400, 600 | Neutral, open, proven legibility |

```css
/* Google Fonts import */
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Source+Sans+3:wght@300;400;600;700&display=swap');

--font-heading: 'Plus Jakarta Sans', system-ui, sans-serif;
--font-body:    'Source Sans 3', system-ui, sans-serif;
```

**Why Plus Jakarta Sans for therapists:** humanist proportions (friendly, not robotic), slightly rounded terminals (warmth without being childish like Nunito), strong bold weight that holds authority at large sizes. Used by modern healthcare and wellness brands in 2024-2025. Explicitly not Space Grotesk (too geometric/tech) and not Alegreya (too literary/editorial for a performance marketing agency).

---

## Part 2 - therappc.com Website Update

### Pages to update (all 4)

- `website_v2/src/index.html`
- `website_v2/src/pricing.html`
- `website_v2/src/results.html`
- `website_v2/src/pipeline-calculator.html`

### CSS changes (surgical - token swap only)

Replace `:root` token block on all 4 pages. All existing component CSS that references tokens (`var(--gold)`, `var(--rust)`, etc.) will need renaming:

| Old token | New token | Replaces |
|---|---|---|
| `--gold` | `--sage` | Primary accent (buttons, links, active states) |
| `--gold-hover` | `--sage-hover` | Hover states |
| `--gold-dim` | `--sage-dim` | Light accent on dark |
| `--rust` | `--terra` | Secondary/warm accent |
| `--rust-dim` | `--terra-dim` | Light warm accent on dark |
| `--bg` | `#F5F0E8` | Background |
| `--bg-dark` | `#1E2D2A` | Dark sections |
| `--bg-dark-2` | `#162320` | Footer/nav |

Token rename is a `replace_all` operation on each file - no structural changes.

### Typography changes

Replace Google Fonts import and `--font-heading` / `--font-body` vars on all 4 pages. Then add `font-family: var(--font-heading)` to all `h1, h2, h3` selectors (currently set to `'Space Grotesk'` inline in some places).

### Premium polish CSS

The premium overrides added in the last deploy reference `var(--gold)`, `var(--gold-dim)`, `var(--rust)` by name. These all need updating to `var(--sage)`, `var(--sage-dim)`, `var(--terra)`.

### Hero gradient text

`h1.hero-title em` currently: `linear-gradient(120deg, var(--gold-dim) 0%, var(--rust) 100%)`. Update to: `linear-gradient(120deg, var(--terra-dim) 0%, var(--sage) 100%)`.

### Simple Icons

`https://cdn.simpleicons.org/googleads/B89270` - the hex suffix is the Warm/Gold accent. Update to `6B8F71` (sage) on all icon references.

---

## Tooling Files to Edit

| File | Change |
|---|---|
| `skills/web-audience.md` | Add competitor research Step 0; add therapy sub-category matrix; add Therapist/Sage full token set; fix other palette entries to have full tokens |
| `skills/web-design.md` | Add Therapist/Sage as a named palette with full CSS block (same format as Warm/Gold) |

## Site Files to Edit

| File | Change |
|---|---|
| `website_v2/src/index.html` | Token rename (replace_all), font swap, icon hex update |
| `website_v2/src/pricing.html` | Token rename, font swap |
| `website_v2/src/results.html` | Token rename, font swap |
| `website_v2/src/pipeline-calculator.html` | Token rename, font swap |

## Deploy

```bash
cf-deploy update therappc --source website_v2/src
```

## Verification

- Open therappc.com - nav, hero, buttons: sage green (not warm gold)
- Dark sections: deep forest (#1E2D2A) not warm black (#2A241C)
- Headings: Plus Jakarta Sans (rounded humanist) not Space Grotesk (geometric)
- Hover a CTA button: sage green gradient, same shimmer effect
- Check Simple Icons on homepage: sage green tinted logo marks
- Check /pricing.html and /pipeline-calculator.html - slider thumbs and track fill are sage
- Mobile 375px: all pages - headings readable, body clear
