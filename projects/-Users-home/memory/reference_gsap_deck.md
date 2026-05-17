---
name: gsap-deck presentation generator
description: CLI tool to generate animated HTML presentations from JSON - 5 themes, 8 slide types, GSAP-powered
type: reference
originSessionId: 1de0e5e9-7d10-497e-bb4e-c7613565245d
---
**Repo:** https://github.com/arc-web/gsap-deck

**Not on npm.** Public repo (verified 2026-05-01; was private at write time). Local clone `/Users/home/tools/gsap-deck` MISSING - npm link gone; clone fresh before use.

**Usage:**
```bash
gsap-deck build deck.json -o output.html --open
gsap-deck build deck.json --theme midnight -o output.html --open
gsap-deck themes
```

**Skill:** `/deck` skill handles the full flow - source material in, presentation out. Use it instead of manual JSON authoring.

**JSON format:** top-level object with `"title"`, `"theme"`, and `"slides"` array. NOT a bare array.
- `compare` uses `left`/`right` + `leftType`/`rightType` ("good"/"bad")
- `quote` uses `"quote"` field, not `"text"`
- Supports `"eyebrow"` on any slide
- Wrap text in `*asterisks*` for gradient highlight

**Slide types:** hero, cards, steps, stats, compare, quote, code, flow

**Themes:** dark (default), midnight, ember, forest, ocean

**Output:** single self-contained HTML file, GSAP from CDN, zero runtime deps. Arrow keys to navigate.

**How to apply:** Use this whenever you need a presentation. Clone the repo first, then define slides in JSON. Reference `examples/demo.json` for correct schema.
