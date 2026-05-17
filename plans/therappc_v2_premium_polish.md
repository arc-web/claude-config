# therappc.com v2 - Premium Polish + Bug Fixes

## Context

v2 is live with correct structure, content, and a warm palette - but it reads "competent agency site" not "premium specialist." The gap between competent and expensive is almost entirely in CSS micro-details: shadow depth, typography authority, motion quality, and gradient intentionality. Additionally, one HTML typo and one slider init bug need fixing.

User goals:
1. Make it look 10x more expensive
2. Fix stat counters populating (currently work, but verify under production CDN timing)
3. Fix chart/slider alignment and disconnected visuals

---

## Bug Fixes (3 items)

### BUG-1: Malformed class attribute in index.html
- **Location:** pipeline math table, first ROI row
- **Problem:** `class="pt-cell class highlight"` - literal word "class" inside class attribute
- **Fix:** Change to `class="pt-cell highlight"`

### BUG-2: Slider track-fill not initialized on page load (pipeline-calculator.html)
- **Problem:** CSS `--pct` variable defaults to `0%` until user first touches a slider
- **Fix:** Call `updateTrack(input)` for every slider inside the `DOMContentLoaded` init block (already calls `update()` but not `updateTrack()` per-slider)

### BUG-3: Stats banner mobile border bleed (results.html)
- **Problem:** On 2-column mobile layout, item 3 retains `border-right` it should lose
- **Fix:** Add `.stat-item:nth-child(odd) { border-right: none; }` inside `max-width: 680px` media query

---

## Premium Design Overhaul - CSS Surgery Only

No HTML structure changes. Pure CSS additions and targeted overrides.

### 1. Typography authority (all pages)
```css
/* Tighter letter-spacing on headings - the single biggest "expensive" signal */
h1, h2, h3 { letter-spacing: -0.03em; }
h1.hero-title { letter-spacing: -0.04em; font-size: clamp(2.8rem, 5.5vw, 4.2rem); }

/* Gradient accent on hero title's key phrase */
h1.hero-title em {
  background: linear-gradient(120deg, var(--gold-dim) 0%, var(--rust) 100%);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}
```

### 2. Button premium treatment (index.html + all pages)
```css
.btn-primary {
  position: relative; overflow: hidden;
  background: linear-gradient(135deg, var(--gold) 0%, #6B4A2B 100%);
  box-shadow: 0 4px 12px rgba(138,107,72,0.3), 0 1px 0 rgba(255,255,255,0.15) inset;
  transition: transform 0.2s cubic-bezier(0.34,1.56,0.64,1), box-shadow 0.2s;
  letter-spacing: 0.01em;
}
.btn-primary::before {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.12) 50%, transparent 100%);
  transform: translateX(-100%); transition: transform 0.5s;
}
.btn-primary:hover { box-shadow: 0 8px 28px rgba(138,107,72,0.4), 0 1px 0 rgba(255,255,255,0.15) inset; }
.btn-primary:hover::before { transform: translateX(100%); }
.btn-primary:active { transform: translateY(1px); }
```

### 3. Multi-layer card shadows
Replace flat `box-shadow: var(--shadow-sm)` with:
```css
/* Applied to: .hero-card, .result-card, .stage-card, .offer-card */
box-shadow:
  0 1px 0 rgba(255,255,255,0.06) inset,
  0 2px 4px rgba(26,24,20,0.06),
  0 8px 20px rgba(26,24,20,0.10),
  0 20px 40px rgba(26,24,20,0.07);
```

### 4. Gradient border on hero card
```css
.hero-card {
  background: linear-gradient(var(--bg-dark), var(--bg-dark)) padding-box,
              linear-gradient(135deg, rgba(184,115,74,0.35) 0%, rgba(138,107,72,0.08) 50%, rgba(184,115,74,0.2) 100%) border-box;
  border: 1px solid transparent;
}
```

### 5. Noise texture on dark sections
Small inline SVG noise pattern at 3% opacity over dark sections - adds tactile depth without weight:
```css
.hero::after, .section-dark::after, .contact-section::after {
  content: ''; position: absolute; inset: 0; pointer-events: none;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='1'/%3E%3C/svg%3E");
  opacity: 0.035; mix-blend-mode: overlay;
}
```

### 6. Stats section - larger numbers + subtle per-card gradient
```css
.stat-num { font-size: 3.4rem; letter-spacing: -0.04em; }
.stat-card { 
  background: linear-gradient(170deg, #fff 60%, rgba(244,239,227,0.6) 100%);
  padding: 40px 28px;
}
.stat-card:first-child { background: linear-gradient(170deg, #fff 60%, rgba(184,115,74,0.04) 100%); }
```

### 7. Timeline dot glow + gradient fill
```css
.timeline-dot { 
  background: linear-gradient(135deg, var(--bg-2) 0%, var(--bg-3) 100%);
  box-shadow: 0 0 0 6px rgba(138,107,72,0.06);
}
.timeline-step:hover .timeline-dot {
  background: linear-gradient(135deg, var(--gold) 0%, var(--rust) 100%);
  box-shadow: 0 0 0 6px rgba(138,107,72,0.15), 0 4px 16px rgba(138,107,72,0.3);
}
```

### 8. Eyebrow pill treatment
```css
.section-eyebrow {
  display: inline-flex; align-items: center; gap: 8px;
  background: rgba(184,115,74,0.1); border: 1px solid rgba(184,115,74,0.2);
  padding: 5px 12px; border-radius: 20px;
  margin-bottom: 16px;
}
.section-eyebrow-dark {
  background: rgba(184,115,74,0.12); border-color: rgba(184,115,74,0.25);
}
```

### 9. Nav frosted glass refinement
```css
nav {
  background: rgba(30,26,20,0.88);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border-bottom: 1px solid rgba(184,115,74,0.12);
}
```

### 10. Pull quote gradient border
```css
.pull-quote { border-left: 3px solid transparent;
  border-image: linear-gradient(180deg, var(--rust) 0%, var(--gold) 100%) 1; }
```

### 11. Result card hover glow
```css
.result-card:hover {
  box-shadow: 0 0 0 1px rgba(138,107,72,0.15),
    0 8px 24px rgba(26,24,20,0.12),
    0 24px 48px rgba(26,24,20,0.08);
}
```

### 12. Form input focus refinement
```css
.form-input:focus {
  border-color: rgba(184,115,74,0.6);
  box-shadow: 0 0 0 3px rgba(184,115,74,0.12), 0 0 0 1px rgba(184,115,74,0.4) inset;
}
```

### 13. Stat counter - add `$` prefix for CPA stat
The `$37` stat should show dollar sign. Update JS so stat card 1 counter appends `$` prefix.

---

## Files to Edit

| File | Changes |
|------|---------|
| `website_v2/src/index.html` | BUG-1 fix + all 13 CSS overrides (1-13 above) |
| `website_v2/src/pipeline-calculator.html` | BUG-2 fix (call updateTrack per slider on init) + match premium CSS tokens |
| `website_v2/src/results.html` | BUG-3 fix + apply matching premium card/stat CSS |
| `website_v2/src/pricing.html` | Apply button + card + eyebrow CSS to match |

## Deploy Sequence

```bash
cf-deploy update therappc --source website_v2/src
cf-deploy seo therappc  # verify no regressions
```

## Verification

- Open https://therappc.com - stat counters animate on scroll to stats section
- Scroll to pipeline table - no "class" text visible in row, highlight cells are gold
- Check /pipeline-calculator.html - slider tracks are filled to default position on load (not at 0)
- Check /results.html on 375px viewport - stats banner has no double right-borders
- Hover over CTA buttons - shimmer sweep visible, no jank
- Hover over timeline dots - glow ring visible
- Dark sections should show subtle grain texture (not a pattern, just depth)
