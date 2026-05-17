---
name: open-in-html-means-codebase-helper-not-pandoc
description: "When user says \"open in html\" / \"open this in html\" for a markdown file, use codebase_helper. Pick the named renderer in RENDERERS.md - default is mkdocs-preview (interactive site), not a single styled doc. Never pandoc."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 945c5c06-7e2d-4ff6-bfba-9cd66ac7239a
---

Rule: user says "open in html" → run codebase_helper. Default renderer is `mkdocs-preview`. Never pandoc.

**Renderer registry:** `~/ai/agents/development/codebase_helper/RENDERERS.md` is canonical. Each renderer has a short kebab-case name. To add a new one, add the script under `scripts/` + add a row to `RENDERERS.md`. Do not extend an existing renderer with new output formats - add a named version.

**Default (no qualifier):** `mkdocs-preview` - interactive Material for MkDocs site on `127.0.0.1:8014`. Searchable, multi-page, navigable. This is the original mission of codebase_helper: render Markdown into interactive websites for visual review of complex topics.

```bash
cd /Users/home/ai/agents/development/codebase_helper
python3 scripts/preview_markdown.py <abs-path-to-md>
```

**Named alternates:**
- `styled-doc` - single-file styled HTML (+ optional PDF) to `~/Desktop/`. Use only when user asks for a standalone artifact, a print/send-ready doc, or a one-file deliverable. Built 2026-05-16 from extracted primitives in `~/ai/agents/ppc/google_ads_agent/shared/presentation/`.

```bash
/Users/home/ai/agents/development/codebase_helper/scripts/render_styled.py <abs-path-to-md> [--pdf] [--title "..."] [--no-open]
```

**How to pick:** if user says "open in html as <name>" or "render with <name>", look up that name in RENDERERS.md and run the matching script. If no name is given, use `mkdocs-preview`. If user describes the output they want (send-ready, single file, print) prefer `styled-doc`.

**Why:** Pandoc -s ships default Pandoc stylesheet which user calls unstyled / "doesn't do anything meaningful." Initial mistake 2026-05-16: I made `styled-doc` the default after building it; user clarified codebase_helper's original mission is interactive sites, not finished docs - `mkdocs-preview` is the default and `styled-doc` is a named alternate.

**Project:** `/Users/home/ai/agents/development/codebase_helper/`. Read `RENDERERS.md` + `AGENT.md` before invoking. CSS assets at `assets/{base,section_header,page_break_rules}.css` (only used by `styled-doc`).

**Cross-ref:** GA agent render stack audit at `~/Desktop/google_ads_agent_audit_2026-05-16.md`.
