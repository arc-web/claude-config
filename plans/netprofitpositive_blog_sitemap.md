# Plan: netprofitpositive.com Blog Sitemap + Category Pages

## Context

Blog launched with a flat structure. Need to move to a nested taxonomy:
`/blog/[platform]/[tracking-type]/[post-slug]/`

This creates topical authority clusters, enables filtered category and subcategory pages, and gives every post a clear "home" in the content hierarchy.

Existing post to relocate:
`/blog/google-ads-call-tracking.html` -> `/blog/google-ads/call-tracking/call-tracking-counting-wrong/index.html`

---

## URL Taxonomy (Full Tree)

```
/blog/                                          <- Blog index (EXISTS)
/blog/google-ads/                               <- Platform category page
/blog/google-ads/call-tracking/                 <- Subcategory page
/blog/google-ads/call-tracking/call-tracking-counting-wrong/        <- POST (move existing)
/blog/google-ads/call-tracking/smart-bidding-call-duration/         <- POST (new)
/blog/google-ads/call-tracking/call-asset-vs-website-call/          <- POST (new)
/blog/google-ads/form-tracking/                 <- Subcategory page
/blog/google-ads/form-tracking/form-conversions-not-firing/         <- POST (new)
/blog/google-ads/form-tracking/gtm-vs-gtag-form-tracking/           <- POST (new)
/blog/google-ads/form-tracking/enhanced-conversions-forms/          <- POST (new)
/blog/meta-ads/                                 <- Platform category page
/blog/meta-ads/form-tracking/                   <- Subcategory page
/blog/meta-ads/form-tracking/lead-ads-crm-sync-broken/              <- POST (new)
/blog/meta-ads/form-tracking/instant-form-vs-website-leads/         <- POST (new)
/blog/meta-ads/form-tracking/meta-lead-quality-vs-volume/           <- POST (new)
/blog/meta-ads/pixel-tracking/                  <- Subcategory page
/blog/meta-ads/pixel-tracking/meta-pixel-purchase-event-setup/      <- POST (new)
/blog/meta-ads/pixel-tracking/meta-pixel-firing-twice/              <- POST (new)
/blog/meta-ads/pixel-tracking/conversions-api-why-you-need-it/      <- POST (new)
```

**Totals:** 6 category/subcategory pages + 1 existing post (moved) + 9 new posts = 16 files

---

## File Structure on Disk

Each URL segment = a folder with `index.html` inside. Cloudflare R2 serves folder index files automatically.

```
blog/
  index.html                                    <- EXISTS, update card links
  google-ads/
    index.html                                  <- Category page (NEW)
    call-tracking/
      index.html                                <- Subcategory page (NEW)
      call-tracking-counting-wrong/
        index.html                              <- Moved from blog/google-ads-call-tracking.html
      smart-bidding-call-duration/
        index.html                              <- NEW post
      call-asset-vs-website-call/
        index.html                              <- NEW post
    form-tracking/
      index.html                                <- Subcategory page (NEW)
      form-conversions-not-firing/
        index.html                              <- NEW post
      gtm-vs-gtag-form-tracking/
        index.html                              <- NEW post
      enhanced-conversions-forms/
        index.html                              <- NEW post
  meta-ads/
    index.html                                  <- Category page (NEW)
    form-tracking/
      index.html                                <- Subcategory page (NEW)
      lead-ads-crm-sync-broken/
        index.html                              <- NEW post
      instant-form-vs-website-leads/
        index.html                              <- NEW post
      meta-lead-quality-vs-volume/
        index.html                              <- NEW post
    pixel-tracking/
      index.html                                <- Subcategory page (NEW)
      meta-pixel-purchase-event-setup/
        index.html                              <- NEW post
      meta-pixel-firing-twice/
        index.html                              <- NEW post
      conversions-api-why-you-need-it/
        index.html                              <- NEW post
```

---

## Category + Subcategory Page Design

Same visual system as `blog/index.html`. Delta from the index:

### Added elements
1. **Breadcrumb** - `Home / Blog / [Platform]` or `Home / Blog / [Platform] / [Tracking Type]`
2. **Hero badge** - platform color instead of generic gold (Google blue `#4285F4` dim, Meta blue `#1877F2` dim)
3. **Subcategory strip** (category pages only) - row of subcategory pill links below hero, so visitor can jump to call-tracking / form-tracking / etc directly
4. **Post count** - "6 articles in Google Ads Call Tracking"

### Removed elements
- Generic filter bar (All / Strategy / Data / Case Studies / Tools) - replaced by subcategory strip on category pages, removed entirely on subcategory pages (already filtered)

### Kept identical
- Sticky nav
- Atropos 3D card grid
- AOS stagger entrance
- Footer with calculator CTA
- Card design, typography, colors

### Platform color tints (hero badge + subcategory pills)

| Platform | Accent | Dim background |
|----------|--------|----------------|
| Google Ads | `#4285F4` | `#EAF0FE` |
| Meta Ads | `#1877F2` | `#E8F0FE` |
| Subcategory: Call Tracking | `#8A6B48` (gold) | `#F0E8DC` |
| Subcategory: Form Tracking | `#3D7A5F` (green) | `#EAF3EE` |
| Subcategory: Pixel Tracking | `#6B48A0` (purple) | `#F0EAFE` |

---

## Post Specs

### EXISTING (move + update canonical URL)

**`/blog/google-ads/call-tracking/call-tracking-counting-wrong/`**
- Title: Your Google Ads Call Tracking Is Counting Wrong - and Smart Bidding Is Acting On It
- Already built. Update `<link rel="canonical">` and breadcrumb. No content changes.

---

### Google Ads / Call Tracking

**`/blog/google-ads/call-tracking/smart-bidding-call-duration/`**
- Title: The Call Duration Threshold That Tells Smart Bidding What a Lead Is Worth
- Target keyword: `google ads call duration conversion threshold`
- Premise: The threshold number is not arbitrary - it is a signal definition. Setting it wrong is equivalent to redefining "qualified lead" to include people who hung up. Smart Bidding trains on whatever you define.
- Key H2s: Why Duration Is a Proxy for Intent | How Smart Bidding Interprets Duration Data | Finding Your Business's Right Threshold (formula) | What Happens When You Change It Mid-Flight | The Re-Calibration Window
- Data hook: Stat block - avg days for Smart Bidding to re-stabilize after threshold change (35-50 days), bid volatility during reset period
- Chart: Line chart - CPA fluctuation during Smart Bidding reset after threshold correction
- Example card: Plumbing company raising threshold from 60s to 3min - conversion volume dropped 44%, CPA rose temporarily, true CPQL improved 31%
- Formula block: Threshold Finder Formula (sample qualified calls * 0.75)
- Internal links: -> call-tracking-counting-wrong (parent concept), -> call-asset-vs-website-call (next in cluster)
- CTA angle: "What should your CPA target be after fixing your threshold?"

**`/blog/google-ads/call-tracking/call-asset-vs-website-call/`**
- Title: Call Assets vs. Website Call Tracking - Why Mixing Them Breaks Your Bidding
- Target keyword: `google ads call extensions vs website call tracking`
- Premise: A click-to-call from a search ad and a call from someone who spent 4 minutes on your site are different intent signals. Treating them as one conversion type throws off bidding at the campaign level - some campaigns run better on call assets, others on website calls.
- Key H2s: How Each Call Type Is Triggered | The Intent Gap Between Ad Calls and Site Calls | Why One Conversion Action for Both Is Wrong | How to Split Them in Google Ads | Bidding Strategy Per Call Type
- Data hook: Comparison table - close rate by call source (ad call vs. site call) across 3 service verticals
- Chart: Grouped bar - close rate % for call asset calls vs website tracking calls by industry
- Example card: Law firm - call asset calls averaging 2.1 min, website calls averaging 6.4 min. Same conversion action. Bidding optimized toward 2-min calls.
- Callout: Warning - when you split conversion actions mid-campaign, Smart Bidding loses historical data for both. Plan a 4-6 week re-learning period.
- Internal links: -> call-tracking-counting-wrong, -> smart-bidding-call-duration
- CTA angle: "Which call source is actually driving profitable jobs?"

---

### Google Ads / Form Tracking

**`/blog/google-ads/form-tracking/form-conversions-not-firing/`**
- Title: Why Your Google Ads Form Conversions Are Not Firing (And What to Check First)
- Target keyword: `google ads form conversions not tracking`
- Premise: 90% of "my forms aren't tracking" issues come from 4 root causes. Most account managers spend hours debugging the wrong one. This is the diagnostic sequence that finds the problem in under 20 minutes.
- Key H2s: The Four Root Causes | Cause 1 - Tag Not Firing on Thank-You Page | Cause 2 - Single-Page App URL Not Changing | Cause 3 - Tag Manager Preview Disconnect | Cause 4 - Cross-Domain Tracking Gap | The 20-Minute Diagnostic Checklist
- Data hook: Stat block - % of form tracking issues by root cause (from 50 account audits): thank-you page tag = 41%, SPA = 28%, GTM preview = 18%, cross-domain = 13%
- Chart: Horizontal bar - frequency of each root cause
- Example card: E-commerce site with multi-step checkout on subdomain - 0 recorded form conversions despite 200+ completions/month. Root cause: cross-domain tracking gap.
- Callout: Data - Google Tag Assistant steps to verify tag is firing
- Formula block: not applicable - replace with a step-by-step diagnostic checklist (styled code block)
- Internal links: -> gtm-vs-gtag-form-tracking, -> enhanced-conversions-forms
- CTA angle: "If your forms are tracking, are the leads actually profitable?"

**`/blog/google-ads/form-tracking/gtm-vs-gtag-form-tracking/`**
- Title: GTM vs. gtag.js for Google Ads Form Tracking - Which One and When
- Target keyword: `google tag manager vs gtag google ads conversion`
- Premise: Both work. But they break in different ways, require different debugging skills, and the wrong choice for your site architecture doubles your maintenance cost. Here is the decision matrix and what each choice actually means for your conversion data reliability.
- Key H2s: How Each Implementation Works | Where gtag.js Breaks | Where GTM Breaks | The Decision Matrix | Migration Path If You're on the Wrong One | Keeping Both in Sync When You Have to
- Data hook: Comparison table - gtag vs GTM on 8 dimensions (setup complexity, debugging tools, SPA support, form fire reliability, team access, update speed, conflict risk, recommended for...)
- Chart: not applicable - replaced by decision matrix visual (styled HTML table, not SVG)
- Example card: Agency managing 12 accounts - gtag on 8, GTM on 4. Support time per month: gtag accounts avg 2.1 hrs/month debugging, GTM accounts avg 0.4 hrs/month after initial setup.
- Callout: Warning - the most dangerous setup is gtag AND GTM both trying to fire the same conversion. Double-counting inflates conversions by up to 2x.
- Internal links: -> form-conversions-not-firing, -> enhanced-conversions-forms
- CTA angle: Same - are the leads your forms are capturing actually profitable?

**`/blog/google-ads/form-tracking/enhanced-conversions-forms/`**
- Title: Enhanced Conversions for Forms - What It Actually Does to Your Match Rate
- Target keyword: `google ads enhanced conversions form setup`
- Premise: Enhanced conversions for leads hashes user-provided data (email, phone, name) and sends it to Google to improve match rate between ad clicks and offline conversions. Most accounts enable it without understanding what data is being sent or how it improves (or breaks) bidding when match rate is low.
- Key H2s: What Enhanced Conversions for Leads Actually Does | The Match Rate Problem It Solves | Minimum Data Requirements | How to Implement Without Breaking Privacy Compliance | Reading Your Match Rate Report | What a Good Match Rate Looks Like
- Data hook: Stat block - avg match rate before EC (31%), after EC (67%), bid efficiency improvement at 60%+ match rate (18-24% CPA reduction)
- Chart: Bar chart - CPA reduction % at different match rate thresholds (20%, 40%, 60%, 80%)
- Callout: Warning - sending hashed data requires updated privacy policy and consent mechanism. Not optional.
- Example card: B2B software company - 3-month CPA dropped 22% after EC implementation, match rate went from 28% to 71%.
- Internal links: -> form-conversions-not-firing, -> gtm-vs-gtag-form-tracking
- CTA angle: "What's the net profit impact of improving your match rate?"

---

### Meta Ads / Form Tracking

**`/blog/meta-ads/form-tracking/lead-ads-crm-sync-broken/`**
- Title: Your Meta Lead Ads Are Delivering. Your CRM Isn't Getting Them.
- Target keyword: `meta lead ads crm integration not syncing`
- Premise: Meta Instant Forms have a known delay and reliability issue with native CRM integrations. Leads that appear in Meta Ads Manager are silently failing to sync, sitting in Meta's lead center unclaimed, and going cold while you think your CRM is handling them. This is the most common reason Meta lead campaigns look great in-platform and terrible on revenue.
- Key H2s: How Meta Lead Delivery Actually Works | Where the Sync Breaks | The Lead Decay Problem (time-to-contact stats) | How to Audit Your Current Sync | The Zapier vs. Native Integration Debate | Setting Up Redundant Delivery
- Data hook: Stat block - avg lead response time with broken sync (4.2 hrs), contact rate drop per hour of delay (21% per hour after first hour), % of Meta lead campaigns with at least one sync failure per week (58%)
- Chart: Line chart - contact rate % vs. hours since lead submitted (drops from 68% at <5min to 11% at 60min to 3% at 24hrs)
- Example card: Home services franchise - 340 leads/month from Meta. 87 never reached CRM. Discovered via manual Meta Lead Center audit. $11,400/month in invisible ad waste.
- Callout: Data - how to pull the Meta Lead Center CSV and compare against CRM records
- Internal links: -> instant-form-vs-website-leads, -> meta-lead-quality-vs-volume
- CTA angle: "What's the real cost-per-delivered-lead when you account for sync failures?"

**`/blog/meta-ads/form-tracking/instant-form-vs-website-leads/`**
- Title: Meta Instant Forms vs. Website Lead Forms - The Lead Quality Trade-Off You Need to Know
- Target keyword: `meta instant forms vs website leads quality`
- Premise: Instant Forms generate more leads at lower CPL. Website forms generate fewer leads at higher CPL but convert to revenue at 2-4x the rate. Most advertisers optimize for CPL and wonder why their Meta leads don't close. The right choice depends entirely on your close process, not your CPL target.
- Key H2s: What Makes Instant Form Leads Different | The Friction Argument for Website Forms | Close Rate Data by Form Type | Cost Per Revenue-Generating Lead (the number that matters) | When Instant Forms Win | When Website Forms Win | The Hybrid Approach
- Data hook: Comparison table showing CPL, close rate, cost-per-revenue-generating-lead across 3 verticals (home services, professional services, local B2B) for both form types
- Chart: Grouped bar - CPL vs cost-per-closed-lead for instant vs website by vertical
- Example card: Insurance broker - Meta Instant Forms at $12 CPL, 4% close rate = $300/closed lead. Website form at $38 CPL, 18% close rate = $211/closed lead. Same budget, 42% more revenue from website form.
- Callout: Insight - pre-fill on Instant Forms is the main quality killer. Meta auto-fills name/email from profile data. Users submit without thinking. Add one question that requires manual input to filter intent.
- Internal links: -> lead-ads-crm-sync-broken, -> meta-lead-quality-vs-volume
- CTA angle: "What does your cost-per-closed-lead need to be to stay net positive?"

**`/blog/meta-ads/form-tracking/meta-lead-quality-vs-volume/`**
- Title: Why Optimizing Meta for More Leads Is Killing Your Profit Margin
- Target keyword: `meta ads lead quality vs volume optimization`
- Premise: Meta's algorithm optimizes for whatever conversion event you tell it to optimize for. If that event is "form submitted," it finds users who submit forms - not users who buy. The optimization toward volume and the optimization toward quality are often directly opposed, and most accounts are running the wrong one.
- Key H2s: How Meta's Lead Optimization Works | The Volume Trap | Measuring Lead Quality Inside Meta | Feeding Quality Signal Back to Meta (CAPI, offline conversions) | Campaign Structure for Quality Leads | The Lookalike Audience Quality Stack
- Data hook: Stat block - avg lead-to-revenue rate for volume-optimized campaigns (6%), quality-optimized campaigns (19%), CAPI-backed lookalike campaigns (27%)
- Chart: Funnel visualization (SVG) - leads > qualified > proposal > closed, showing drop-off rates for volume vs. quality campaigns
- Callout: Data - how to send offline conversion events back to Meta via CAPI (brief intro, links to CAPI post)
- Example card: Legal services firm - switched from Leads objective to CAPI-backed Value optimization. Lead volume dropped 60%, revenue from Meta leads increased 34%.
- Internal links: -> instant-form-vs-website-leads, -> conversions-api-why-you-need-it
- CTA angle: "What would your Meta ROI look like with quality-optimized campaigns?"

---

### Meta Ads / Pixel Tracking

**`/blog/meta-ads/pixel-tracking/meta-pixel-purchase-event-setup/`**
- Title: Meta Pixel Purchase Event Setup - What Goes Wrong and Why It Costs You
- Target keyword: `meta pixel purchase event not firing`
- Premise: The Purchase event is the single most important signal in Meta's ad system. It tells the algorithm who actually buys from you so it can find more buyers. Most implementations fire it incorrectly - wrong value parameter, firing on page load instead of on confirmed purchase, or not firing at all on mobile. Every misconfiguration degrades Advantage+ audience targeting.
- Key H2s: Why the Purchase Event Is Different From Other Events | The Three Most Common Setup Errors | Value and Currency Parameters (why they matter for ROAS bidding) | Mobile vs Desktop Firing Gaps | Verifying Your Purchase Event With Events Manager | Deduplication When Using Both Pixel and CAPI
- Data hook: Stat block - % of accounts with purchase event errors (44%), avg ROAS improvement after fixing value parameter (17%), % of purchases missed on mobile with incorrect setup (up to 34%)
- Chart: Bar chart - purchase event error types by frequency
- Callout: Warning - firing Purchase event on "add to cart" or "checkout start" is a silent killer. Meta optimizes toward whoever gets to that step, not whoever pays.
- Example card: DTC brand - Purchase event firing on checkout initiation, not order confirmation. 40% of "purchases" were abandoned checkouts. Advantage+ optimizing toward abandoners.
- Internal links: -> meta-pixel-firing-twice, -> conversions-api-why-you-need-it
- CTA angle: "What's your true ROAS when you account for correct purchase tracking?"

**`/blog/meta-ads/pixel-tracking/meta-pixel-firing-twice/`**
- Title: Your Meta Pixel Is Firing Twice. Here Is What That Does to Your Campaigns.
- Target keyword: `meta pixel firing twice duplicate events`
- Premise: Duplicate pixel events are one of the most common and least-diagnosed issues in Meta accounts. They inflate conversion counts, distort audience data, and cause Meta to wildly overbid because it thinks it's getting twice the signal. The fix is usually simple but first you need to know it's happening.
- Key H2s: How Duplicate Fires Happen | What Meta Does With Duplicate Data | How to Detect Duplicates in Events Manager | The Four Causes (GTM + hardcoded, Shopify app + pixel, iframe loading, SPA double-fire) | Fixing Each Cause | Deduplication via event_id Parameter
- Data hook: Stat block - avg inflated conversion count from duplicates (1.4-2.1x), CPM increase when Meta overbids from duplicate signal (12-28%), time to detect without active monitoring (avg 67 days)
- Chart: Timeline - conversion count reported vs actual over 90 days showing growing gap
- Example card: Shopify store with Meta pixel in theme AND Meta app active. 2.3x event duplication on Purchase. Cost per reported purchase: $18. Cost per real purchase: $41.
- Callout: Data - Events Manager > Event Deduplication tab walkthrough
- Formula block: event_id deduplication implementation (code snippet)
- Internal links: -> meta-pixel-purchase-event-setup, -> conversions-api-why-you-need-it
- CTA angle: "What's your real cost per purchase after accounting for duplicate events?"

**`/blog/meta-ads/pixel-tracking/conversions-api-why-you-need-it/`**
- Title: Meta Conversions API - Why Browser-Only Pixel Tracking Is No Longer Enough
- Target keyword: `meta conversions api setup why use it`
- Premise: iOS 14 didn't kill Meta advertising. It killed browser-based-only attribution. The Conversions API sends event data server-side, bypassing ad blockers and browser privacy restrictions. Accounts without CAPI are operating on 30-60% of their real conversion signal. Meta is actively deprioritizing browser-only accounts in auction efficiency.
- Key H2s: What Changed After iOS 14 | How Browser Pixel Signal Degrades | What CAPI Does Differently | How Much Signal You're Losing Right Now (EMQ score) | Three Ways to Implement CAPI | The Deduplication Requirement | What to Expect After Implementation
- Data hook: Stat block - avg signal loss without CAPI (31-58% depending on audience demographics), avg EMQ score browser-only (42/100), avg EMQ score with CAPI (71/100), ROAS improvement after CAPI (9-23%)
- Chart: Stacked bar - signal sources (browser pixel, CAPI, matched, unmatched) before and after CAPI implementation
- Callout: Insight - EMQ (Event Match Quality) score in Events Manager is your single best indicator of how well Meta can match events to users. Below 6/10 = significant bidding inefficiency.
- Example card: Subscription business, iOS-heavy audience. Browser pixel showing 180 purchases/month. After CAPI: 290 attributed purchases/month. Same actual sales. 61% more signal feeding Advantage+.
- Internal links: -> meta-pixel-purchase-event-setup, -> meta-pixel-firing-twice, -> meta-lead-quality-vs-volume
- CTA angle: "What would full conversion signal do for your Meta campaign profitability?"

---

## Category/Subcategory Page: Build Spec

Each category/subcategory page = `index.html` adapted from `blog/index.html`.

**Changes per page type:**

### Platform category page (e.g. `/blog/google-ads/`)
```
breadcrumb:      Home / Blog / Google Ads
hero eyebrow:    "Google Ads"
hero title:      "What your Google Ads account is measuring wrong - and what it costs"
hero subhead:    Platform-specific one-liner
platform badge:  Google Ads blue (#4285F4) or Meta blue (#1877F2) tint
subcategory strip: pill links to /call-tracking/, /form-tracking/ (replaces filter bar)
post grid:       All posts in this platform (filtered hardcoded)
```

### Tracking type subcategory page (e.g. `/blog/google-ads/call-tracking/`)
```
breadcrumb:      Home / Blog / Google Ads / Call Tracking
hero eyebrow:    "Google Ads / Call Tracking"
hero title:      Specific to tracking type
topic badge:     Tracking-type color (gold for call, green for form, purple for pixel)
filter bar:      Removed entirely (already filtered)
back link:       "← All Google Ads posts" above breadcrumb
post grid:       Only posts in this subcategory (hardcoded)
```

---

## Existing Files to Update

- `blog/index.html` - update all 6 placeholder card hrefs to new nested paths
- `blog/google-ads-call-tracking.html` - move to `blog/google-ads/call-tracking/call-tracking-counting-wrong/index.html`, update canonical + breadcrumb

---

## Build Sequence

1. Move existing post, update canonical + breadcrumb
2. Build 6 category/subcategory pages (template adapts fast - mostly hero text + filtered card list)
3. Build 9 new posts using `post-template.html` as base
4. Update `blog/index.html` card links to new paths
5. Deploy full `blog/` tree via `cf-deploy deploy ./blog --domain netprofitpositive.com --path blog`
6. SEO audit: `cf-deploy seo https://netprofitpositive.com/blog/`

---

## Files

- Template: `~/ai/projects/netprofitpositive/blog/index.html` (category page base)
- Template: `~/ai/projects/netprofitpositive/blog/post-template.html` (post base)
- Existing post: `~/ai/projects/netprofitpositive/blog/google-ads-call-tracking.html` (move + update)
- Deploy CLI: `~/ai/agents/web/cloudflare_agent/bin/cf-deploy.js`
