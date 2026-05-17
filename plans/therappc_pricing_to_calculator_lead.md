# therappc - Pricing Page → Calculator + Lead Capture

## Context

The current pricing page shows flat-rate cards ($1,500/mo Core, Custom Premium). Problem: visitors bounce before ever talking to sales because they're reacting to a number without context. The goal is to replace it with the same pipeline calculator that lives on `/pipeline-calculator.html`, so visitors see their own projected ROI first - then immediately hit a short contact form to get custom pricing. This turns a price-objection page into a lead capture page where the prospect has already sold themselves on the math.

`/pipeline-calculator.html` stays intact (standalone tool). `/pricing.html` becomes a new experience: run the numbers → submit info → get pricing call.

---

## Page Structure (new pricing.html)

```
1. Nav (unchanged)
2. Hero  →  new copy: "See what Google Ads would do for your practice"
3. Calculator section (sliders + results table - lifted from pipeline-calculator.html)
4. Lead capture section  →  "Get your custom pricing" inline form
5. Value math section (keep - supports ROI story)
6. FAQ section (keep - answers pricing objections)
7. CTA strip (keep)
8. Footer (unchanged)
```

---

## What Gets Removed

- Entire `.pricing-grid` section (Core + Premium cards, billing toggle, billingToggle JS, updatePricing() function)
- `id="corePrice"`, `id="coreBilling"` elements and their associated JS
- Pricing-specific CSS: `.pricing-grid`, `.pricing-card`, `.pricing-badge`, `.billing-toggle-wrap`, `.price-num`, `.price-period`, `.price-features`, `.price-note`

---

## Calculator Section (lifted from pipeline-calculator.html)

Copy verbatim from pipeline-calculator.html:
- **CSS:** slider styles, output table styles, assumptions bar (`calc-section`, `slider-card`, `output-card`, `.slider-row`, `.calc-table`, `.ct-*` classes)
- **HTML:** `.slider-card` (4 sliders with labels + value displays) + `.output-card` (results table, 3-scenario columns)
- **JS:** `calcScenario()`, `fmt$()`, `fmtX()`, `updateTrack()`, `update()`, slider event listeners, `update()` init call
- Slider IDs/values stay identical: `sliderSpend` (500-5000, default 1500), `sliderRate` (100-300, default 175), `sliderSessions` (2-8, default 4), `sliderClose` (50-95, default 75)
- Output IDs stay identical: `oInqC/M/O`, `oCliC/M/O`, `oRevC/M/O`, `oInvC/M/O`, `oRoiC/M/O`, `oBEC/M/O`

---

## Lead Capture Section (new)

Placed immediately after the calculator output card. Warm background, moderate visual weight - not a hard interruption.

**Section heading:** "Looks good? Get your custom pricing."  
**Sub:** "Tell us a bit about your practice and we'll send you a tailored proposal within 1 business day."

**Form fields (4):**
- `name` - text - "Your name"
- `practice_name` - text - "Practice name"
- `email` - email - "Email address"
- `phone` - tel - "Phone number"
- `monthly_spend` - hidden - populated from `sliderSpend.value` on submit
- `source` - hidden - value `"pricing-page"`

**Submit:** `POST /api/lead` (same endpoint as homepage contact form)  
**Submit button copy:** "Get my custom pricing →"  
**Success state:** Replace form with: "Got it! We'll have your pricing ready within 1 business day."

Form submit JS: read `sliderSpend.value` into hidden field before fetch, then same fetch pattern as index.html contact form.

---

## Hero Copy Change

**Old:** "One flat fee. Your ad budget stays yours."  
**New:** "See what Google Ads would actually do for your practice."  
**Sub:** "Adjust the numbers to match your situation. When the math works, we'll send you a tailored pricing proposal."  
**CTA button:** remove (hero flows directly into calculator below)

---

## Files to Edit

| File | Change |
|------|--------|
| `website_v2/src/pricing.html` | Full rewrite: remove pricing cards, add calculator + lead form |
| `website_v2/src/index.html` | Nav link `/pricing.html` text change: "Pricing" → "Get Pricing" (optional, one-word change) |
| `website_v2/src/pipeline-calculator.html` | No change |

---

## Deploy

```bash
cf-deploy update therappc --source website_v2/src
```

---

## Verification

- Open `/pricing.html` - sliders present, adjust spend slider → output table updates immediately
- Fill form → submit → success message appears (no page reload)
- Check `me@advertisingreportcard.com` inbox - email received with `source: pricing-page` and `monthly_spend` field
- Mobile 375px: sliders full width, results table scrollable, form single-column
- `/pipeline-calculator.html` - still loads independently, unchanged
