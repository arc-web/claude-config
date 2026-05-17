# cloudflare_agent - New Skill: web-audience.md

## Context

The cloudflare_agent has skills for design systems (web-design.md), effects (web-effects.md), components (web-components.md), and form code (web-forms.md). What's missing is the strategic layer that sits *before* all of those: who are you building for, what design signals resonate with them, how to avoid AI slop, and how to make forms that actually convert. This is the research-backed decision layer that informs all downstream choices.

---

## File to Create

**Path:** `/Users/home/ai/agents/web/cloudflare_agent/skills/web-audience.md`

**Length:** ~500-600 lines, matching depth of web-effects.md / web-pricing.md

---

## File Structure

### Section 1: Audience Archetypes + Research Process

Three primary archetypes with decision table. For each: who they are, what signals build trust, what signals break trust, design implication summary.

| Archetype | Industry examples | Trust signals | Design implication |
|---|---|---|---|
| **Care Seeker** | Therapy, healthcare, wellness, legal | Warmth, credentials, calm, clarity | Warm neutrals, serif authority, no hype |
| **Builder/Operator** | B2B SaaS, dev tools, agencies, fintech | Speed, capability, ROI, proof | Cool precision, variable sans, dense data |
| **Consumer/Buyer** | E-commerce, courses, events, consumer apps | Desire, social proof, urgency | Bold/warm, expressive type, big imagery |

Quick qualifier questions to determine archetype from a brief:
- Who pays? (individual vs. company)
- What's the emotional state at landing? (stressed, curious, comparing)
- What's the LTV and trust threshold? (low-trust impulse buy vs. high-trust recurring service)

---

### Section 2: AI Slop - Patterns to Avoid

**Visual red flags (the exact tells):**
- Blue-to-purple gradients on backgrounds, buttons, and glowing orbs simultaneously
- Dark background + colored box-shadow glow on cards (the #1 SaaS template tell)
- Thick colored left border on rounded cards (LLM UI default)
- Every card/button/badge has identical border-radius (always 16px)
- Cards within cards within cards (5+ nesting levels with padding + shadow on each)
- Center-aligned text on every element including long-form content
- Inter as the only font with no intentional hierarchy

**Copy red flags:**
- "Delivering exceptional solutions that drive meaningful results"
- "Testimonials" with "Sarah M., Marketing Director" and no photo, company, or link
- Hero headline that could apply to any company in any industry
- Every section has an eyebrow label + H2 + body paragraph in identical structure throughout

**What counteracts slop in 2025-2026:**
- Grain / noise texture overlays (3-4% opacity) on dark sections
- Typography as the differentiator - one expressive heading font vs. Inter everywhere
- Left-aligned asymmetric layouts vs. full-center symmetry
- Buttons that spring/bounce on hover (cubic-bezier spring easing)
- Real specificity in copy: real numbers, real geography, real names with photos

---

### Section 3: Typography by Audience

Decision framework: pick heading font first (personality), then body font (readability). Max 2 families.

**Care Seeker (healthcare, therapy, professional services):**
- Heading: Alegreya, Playfair Display, or Lora (warm serif - signals expertise without coldness)
- Body: Source Sans Pro, Lato, or Open Sans (neutral, legible, open letterforms)
- Avoid: Inter-only, geometric sans for headings (feels corporate/tech, not trusted)
- Size: min 17px body on desktop, 16px mobile; line-height 1.65-1.75

**Builder/Operator (B2B SaaS, dev tools, fintech):**
- Heading: Space Grotesk, Manrope, or DM Sans (geometric, modern, technical authority)
- Body: Inter variable (designed for screens, excellent at small sizes, 330KB WOFF2 vs 700KB+ static)
- Avoid: serif headings (reads as outdated agency), excessive font weights
- Size: min 15px body; tighter line-height 1.55-1.65; use font-feature-settings for tabular numerals in data

**Consumer/Buyer (e-commerce, courses, events):**
- Heading: Montserrat Bold, Oswald, or Poppins ExtraBold (expressive, visual energy)
- Body: Merriweather, Nunito, or Lato (legible under images, warm)
- Avoid: system fonts only (feels unbranded), thin weights on dark backgrounds
- Size: larger headlines (mobile-first); high contrast for CTA areas

**Universal rules:**
- Variable fonts only: reduces file size 40-50% vs. loading multiple static weights
- Letter-spacing tight on headings (-0.03em to -0.04em) = premium signal
- Never more than 2 families on one page
- Test at 375px: if it looks bad on iPhone SE, rethink the pairing

---

### Section 4: Color Palette by Audience

**Care Seeker (healthcare, therapy, wellness):**
- Palette direction: warm neutrals OR soft teal/green (both convert; warm = inviting, teal = clinical trust)
- Avoid: saturated primary blue (too insurance/corporate), red (alarm), purple (spiritual/mystical)
- Proven warm palette: `#F4EFE3` bg / `#8A6B48` gold / `#B8734A` rust / `#2A241C` dark - (the Warm/Gold system in web-design.md)
- Proven clinical palette: `#F5FAFB` bg / `#00BCD4` teal / `#10217D` navy / `#527C88` dusty blue
- Trust color: blue signals loyalty + stability; teal/green signals calm + wellness
- Gold/warm signals premium + human vs. cold clinical (choose based on practice positioning)

**Builder/Operator (B2B SaaS, fintech, dev tools):**
- Palette direction: dark mode preferred; cool tones + high-contrast accent
- Trend 2025-2026: "chromatic density" - colors with texture and weight, not flat generic blue
- Avoid: blue-purple gradient (marks site as AI-template immediately)
- Proven pattern: deep dark bg (#0D1117 or similar) + single strong accent (gold, orange, green) + neutral text
- SaaS conversion principle: accent color = one interactive element only (CTA button, key links)

**Consumer/Buyer (e-commerce, courses):**
- Warm tones → urgency, energy (good for impulse purchases, limited-time offers)
- Cool tones → trust, calm (good for premium/luxury positioning, considered purchases)
- Pick based on product category and intended emotional state at checkout
- Up to 90% of brand judgments happen on color alone before name/message is processed

**Universal rules:**
- Background / text contrast must hit WCAG AA (4.5:1 for body, 3:1 for large text)
- Pick ONE accent color; use tints/shades of it for hierarchy, not a second accent
- Test palette with color-blind simulator (Deuteranopia affects 8% of men)
- Dark sections need noise texture to avoid flat AI-generated look

---

### Section 5: Form Conversion - The Process

This section defines the strategic decisions. Code is in `web-forms.md`.

**Field count - the conversion cliff:**

| Fields | Conversion rate |
|--------|----------------|
| 1 (email only) | ~25.5% |
| 3 fields | ~25% (sweet spot) |
| 5 fields | 17.0% |
| 7 fields | 11.4% |
| 10+ fields | 6.9% |

- Each additional field costs ~4.1% conversion on average
- The 5-to-7 cliff: after 5 fields the drop accelerates (form reads as "work")
- Match field count to funnel position: ToFu = 2-3 fields, MoFu = 3-5, BoFu = 5-7

**Label positioning (top-aligned always):**
- Top-aligned labels: 28% faster comprehension vs. left-aligned
- Reduces completion time up to 50%
- Never use placeholder-only as label: it disappears on input, fails WCAG contrast, breaks screen readers
- Persistent label above field is the only acceptable pattern

**Button copy that converts:**
- "Submit" → 14% conversion
- Generic action ("Go", "Click here") → 25-30% improvement
- First-person, specific copy → up to 25% lift: "Get my custom pricing →" beats "Submit"
- Rule: button tells user exactly what happens next, in their voice

**Trust signals - placement rules:**
- Adjacent to the form, not below it: users evaluate trust before they start typing
- Specific > generic: "37 therapy practices in Canada use this" > "Trusted by clients"
- No-obligation language reduces friction: "No commitment. No sales call unless you want one."
- Privacy signal directly under email field: "No spam. We send fewer emails than you'd expect."

**Multi-step vs. single-step decision:**
- Single-step: avg 4.53% conversion
- Multi-step: avg 13.85% conversion (86% higher; some cases 300%+ improvement)
- Use multi-step when: 6+ fields, mobile-first, complex qualification, high-stakes form
- Use single-step when: newsletter/email only, quick action, 3 fields or fewer
- Multi-step works via sunk cost: users who complete step 1 resist abandoning

**Error handling strategy:**
- Validate on blur (when user leaves field), NOT on first keystroke
- Inline error: below the field, in red, plain language ("Enter a valid email like you@example.com")
- Forms with inline validation: 42% faster completion, 22% fewer errors, 31% higher satisfaction
- Never clear the form on error: pre-fill all valid fields, highlight only broken ones
- Error recovery = where forms lose the most leads; users who see an error but don't retry = lost

---

### Section 6: Anti-Patterns Quick Reference

Design:
- Blue-purple gradient on dark hero = instant AI slop signal
- Inter + Inter (same font, different weight only) = no personality
- Rounded cards everywhere with identical border-radius = template feel
- All text centered on desktop = amateur
- Every section: eyebrow + H2 + body + CTA button = robotic structure

Content:
- Vague value propositions that fit any business = trust killer
- Testimonials without real names, photos, and verifiable context = trust killer
- Stock photos with plastic skin tones or too-perfect lighting = trust killer
- Filler body copy that hedges every claim = authority killer

Forms:
- Placeholder text as labels
- "Submit" button copy
- Validating on first keystroke
- Clearing form on error
- Trust signals placed below the form
- No feedback during submission

---

## Files to Edit

| File | Change |
|------|--------|
| `skills/web-audience.md` | Create new file |
| `skills/web-design.md` | Add 1-line cross-reference to web-audience.md at top |

---

## Verification

- Read `skills/web-audience.md` - decision tables are scannable, no code duplication from web-forms.md or web-design.md
- Start a new therappc-style project: does reading web-audience.md first change design decisions? It should map audience → typography → color → form field count before any HTML is written.
