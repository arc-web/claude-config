# TheraPPC: Calculator Redesign + Survey Lead Flow

## Context

The current calculator has sliders only, no lead capture, and "Book a call" sends to a generic contact form (/#contact on index.html). The goal is to:
- Make the calculator feel premium and high-trust
- Gate the full pipeline report behind a lightweight practice survey (so every calculator user becomes a lead)
- Replace "Book a call" with a Typeform-style multi-step survey that collects the same qualifying data
- Land all submissions on a pre-call prep page that sets expectations, explains the service, and gives homework

CRO research confirms: contact info last, max 5 questions, progress bar, conversational copy, sunk-cost one-question-per-page drives 20-35% higher completion vs. single-page.

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `src/pipeline-calculator.html` | Rewrite - premium design, dual inputs, teaser + unlock gate |
| `src/book-a-call.html` | Create - 5-step Typeform wizard |
| `src/next-steps.html` | Create - post-submission prep page |
| `workers/lead-proxy/worker.js` | Update - accept new fields, relax validation |
| `src/index.html` | Replace #contact section + update nav links |
| `src/pricing.html` | Nav: Book a call → /book-a-call |
| `src/google-ads-for-therapists-results.html` | Nav: Book a call → /book-a-call |
| `src/blog/index.html` | Nav: Book a call → /book-a-call |
| `src/blog/*/index.html` (3 posts) | Nav: Book a call → /book-a-call |

All at: `/Users/home/ai/clients/therappc-site/`

---

## 1. Calculator Redesign (`pipeline-calculator.html`)

### Visual upgrade ("10x more expensive")
- Left inputs card: dark background (`var(--bg-dark)`) instead of white, gold borders, larger label type
- Right output: dark premium card with cream text, numbers in `clamp(2rem, 4vw, 3rem)` Plus Jakarta Sans
- Section background: `var(--bg-2)` (warm cream) with subtle dark radial gradient at edge
- Inputs get more padding and breathing room, card shadow deepened

### Dual input controls (number field + slider, synced)
Each field gets both:
```html
<input type="number" class="num-input" id="numSpend" min="500" max="5000" step="100" value="1500">
<input type="range"  class="range-input" id="sliderSpend" ...same attrs...>
```
JS syncs them: changing either updates the other + recalculates live.

### Teaser (live, no gate)
Right card shows 3 large headline numbers (moderate scenario, updates live):
```
~25 inquiries/month
~19 new clients
~$13,300 new revenue
```
Below these: "Based on 10% conversion · $12 avg CPC · your inputs above"
CTA button: **"Unlock your full pipeline report →"**

### Unlock gate (inline, 3-step mini-survey)
Clicking "Unlock" reveals an inline card (no modal, no page change). 3 steps, progress bar, one question at a time:

**Step 1** - "How many therapists are in your practice?"
- 4 large buttons: Solo (just me) / Small (2-5) / Mid-size (6-15) / Large (15+)

**Step 2** - "What's your primary goal right now?"
- Get new clients consistently
- Fill a new therapist's caseload  
- Reduce dependency on Psychology Today / directories
- Scale beyond referrals

**Step 3** - Name + email (two text inputs, single step)
- Label: "Where should we send your full report?"
- Submit button: "Show my full report →"

On submit → POST to `/api/lead` with fields: `source: 'calculator'`, `name`, `email`, `practice_size`, `goal`, plus all 4 calculator values (`spend`, `rate`, `sessions`, `close_rate`). On success → full 3-scenario table slides into view (replacing teaser). Also redirect to `/next-steps` after 1.5s delay OR stay on page with table visible (user choice - recommend stay on page, no redirect).

> **Decision point**: Stay on page (show full table inline) OR redirect to /next-steps with full table embedded there? Recommend: **stay on page**. Redirect for book-a-call survey.

---

## 2. Book a Call Survey (`book-a-call.html`)

Full-screen Typeform-style wizard. Dark background (`var(--bg-dark)`). Large centered question text. One question per screen. Progress bar at top.

**5 steps:**

| Step | Question | Input type |
|------|----------|------------|
| 1 | "How many therapists are in your practice?" | 4 large select buttons (Solo / 2-5 / 6-15 / 15+) |
| 2 | "What do you primarily focus on?" | Multi-select pills (Anxiety & depression / Couples therapy / Trauma & PTSD / Teen & adolescent / CBT/DBT / Other) |
| 3 | "What's your biggest goal right now?" | 4 select buttons (same as calculator gate step 2) |
| 4 | "What monthly budget are you considering for Google Ads?" | 4 select buttons ($500-$1,000 / $1,000-$2,500 / $2,500-$5,000 / $5,000+) |
| 5 | "Last step — where should we send your pipeline estimate?" | First name + email inputs. Submit: "Send my estimate →" |

Progress bar: "Step X of 5". Each select button advances automatically on click (no "Next" button needed for single-select steps). Multi-select (step 2) requires a "Continue →" button.

On submit → POST to `/api/lead` with `source: 'survey'`, `name`, `email`, `practice_size`, `modalities[]`, `goal`, `budget_range`. Redirect to `/next-steps` on success.

**Design spec:**
- Full viewport height per step, vertically centered
- Question: `clamp(1.6rem, 3vw, 2.4rem)` Plus Jakarta Sans, cream `var(--on-dark)`
- Select buttons: dark card with gold border on hover/selected, `var(--bg-dark-2)` bg
- Progress bar: thin gold line at top, fills left-to-right

---

## 3. Post-Submission Prep Page (`next-steps.html`)

URL: `/next-steps` (book-a-call redirects here; calculator optionally links here)

**Section 1 - Confirmation** (dark hero)
"You're in. We'll reach out within 1 business day."
Sub: "Here's what happens next: we'll review your practice details, pull competitive data for your market, and come to the call with projections specific to your geography and specialty."

**Section 2 - How we work** (cream bg, 3 icon cards)
- We build and manage your campaigns end-to-end (no handing off a login)
- Month-to-month. No contracts. Cancel any time.
- You see every number: weekly reports, shared dashboard

**Section 3 - Get ready for the call** (warm bg, checklist format)
"The call goes faster and you get more out of it if you have these ready:"
- [ ] Access to your Google account (the one tied to your practice email)
- [ ] Know which cities or areas you want to target
- [ ] Your average session rate ($/session)
- [ ] How many new clients you can realistically onboard per month
- [ ] If you have GA4 or Google Analytics - have it open so we can review current traffic together
- [ ] Optional: any current Psychology Today / directory spend you're tracking

**Section 4 - While you wait** (cream bg, 3 blog cards)
Links to the 3 live blog posts (case study, HIPAA guide, strategy post). Use existing `.post-card` style from blog/index.html.

**Section 5 - Footer CTA**
"Questions before the call? Email hello@therappc.com"

---

## 4. Lead Proxy Worker Updates (`workers/lead-proxy/worker.js`)

Current required fields: `name, email, role, spend` - too restrictive for new forms.

**Changes:**
- Required: `name`, `email` only
- Accept new optional fields: `source`, `practice_size`, `modalities`, `goal`, `budget_range`, `rate`, `sessions`, `close_rate`, `spend`
- Email template: add a "Calculator inputs" section that renders when calculator fields are present
- Keep GHL webhook mapping, add new custom fields to GHL payload
- Keep honeypot `_gotcha` check

---

## 5. Homepage Contact Section (`index.html`)

Replace entire `#contact` / `.contact-section` with:
```html
<section id="contact" class="section-dark">
  <div class="section-inner" style="text-align:center;max-width:600px;margin:0 auto;">
    <span class="section-eyebrow section-eyebrow-dark">Ready to see your numbers?</span>
    <h2 class="section-title section-title-dark">Tell us about your practice. We'll build your pipeline projection.</h2>
    <p ...>Takes about 90 seconds. No commitment.</p>
    <a href="/book-a-call" class="btn-primary">Start here →</a>
  </div>
</section>
```

All `/#contact` nav links across all pages → `/book-a-call`.

---

## 6. Nav Link Updates

All pages: change `<a href="/#contact" class="nav-cta">Book a call</a>` → `<a href="/book-a-call" class="nav-cta">Book a call</a>`

Files: index.html, pricing.html, pipeline-calculator.html, google-ads-for-therapists-results.html, blog/index.html, blog/case-studies/.../index.html, blog/guides/.../index.html, blog/strategy/.../index.html

---

## 7. Deploy

```bash
cd /Users/home/ai/clients/therappc-site
cf-deploy update therappc          # main site (all src/ pages)
cf-deploy update therappc-blog     # blog only
# deploy worker separately via wrangler
```

New pages `book-a-call` and `next-steps` are clean-URL directory-key uploads - handled by existing cf-deploy dual-upload pattern.

---

## Verification

1. Open `/pipeline-calculator` - sliders AND number inputs both work, synced
2. Live teaser updates as inputs change (no form needed)
3. Click "Unlock your full pipeline report" - 3-step inline survey appears
4. Complete survey - full table renders, worker receives POST at `/api/lead` (check Resend inbox)
5. Open `/book-a-call` - 5 steps advance correctly, progress bar fills
6. Complete survey - redirects to `/next-steps`
7. `/next-steps` loads with all 4 sections, blog cards link correctly
8. All "Book a call" nav links site-wide → `/book-a-call`
9. Homepage `#contact` section shows simple CTA, no form
