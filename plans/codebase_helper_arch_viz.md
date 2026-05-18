# Add `arch-viz` Renderer to codebase_helper

**Last updated: 2026-05-18**

## Context

The OpenBao credential flow session produced a 1238-line interactive HTML (`~/Desktop/openbao-flow.html`) showing 4 auth identities with animated flows, policy scopes, and audit log previews. It was built by a background agent with hardcoded data. The request is to generalize this pattern so codebase_helper can generate the same type of artifact for any project from a markdown file with an embedded JSON config block - same way `system-map` reads a `system-map` fenced block.

No human in the loop. Full pipeline: Plane task → branch → build → smoke test → PR → merge → done.

---

## What Gets Built

**New renderer: `render_arch_viz.py`**

- Input: `.md` file with a fenced `` ```arch-viz `` block containing JSON config
- Output: self-contained dark-theme interactive HTML on `~/Desktop/`
- Behavior: left panel identity/entity cards, click → right panel animated auth flow + policy scope grid + audit log, tabs for additional flows
- Registered in `RENDERERS.md` as `arch-viz`

**New fixture**: `smoke/fixtures/arch-viz-sample.md` (generic, not OpenBao-specific - demonstrates the schema)

**Smoke test**: one new line in `smoke/smoke_preview_workflow.sh`

---

## JSON Schema (embedded in markdown as ```arch-viz block)

```json
{
  "project": {
    "title": "My Architecture",
    "subtitle": "Optional subtitle"
  },
  "identities": [
    {
      "id": "agent1",
      "name": "Display Name",
      "icon": "🤖",
      "avatarGradient": "linear-gradient(135deg, #238636, #2ea043)",
      "authType": "AppRole",
      "authColor": "var(--green)",
      "description": "Short description",
      "badges": [
        { "text": "Label", "bg": "var(--green-dim)", "color": "var(--green)" }
      ],
      "networkPath": [
        { "icon": "🖥️", "name": "Client", "subtext": "origin" },
        { "icon": "🔒", "name": "Auth", "subtext": "middlelayer" },
        { "icon": "🏦", "name": "Vault", "subtext": "secrets" }
      ],
      "steps": [
        {
          "node": "Client",
          "nodeColor": "var(--blue)",
          "numberBg": "var(--blue-dim)",
          "action": "POST /v1/auth/approle/login",
          "detail": "{ role_id, secret_id } → token"
        }
      ],
      "policies": {
        "allow": ["shared/*", "hosting/*"],
        "deny": ["human-only/*"]
      },
      "auditLog": "role_name=agent1 | path=secret/data/shared/key | op=read",
      "alert": {
        "type": "blue",
        "icon": "ℹ️",
        "text": "Optional note about this identity"
      }
    }
  ],
  "flows": [
    {
      "id": "main-flow",
      "title": "Main Flow",
      "description": "How it works end to end",
      "badges": ["step-by-step", "automated"],
      "steps": [
        {
          "actor": "Client",
          "actorColor": "var(--blue)",
          "actorBg": "var(--blue-dim)",
          "dotColor": "var(--blue)",
          "event": "Event fires",
          "detail": "Description of what happens",
          "code": "POST /api/endpoint { key: value }"
        }
      ],
      "stateMappings": [
        { "trigger": "Event A", "result": "State X", "resultColor": "var(--blue)" }
      ]
    }
  ],
  "infrastructure": [
    { "label": "Endpoint", "value": "https://example.com" },
    { "label": "Version", "value": "v2.2.0" }
  ]
}
```

---

## File Changes

| File | Action |
|------|--------|
| `scripts/render_arch_viz.py` | CREATE - full renderer |
| `RENDERERS.md` | ADD row: `arch-viz` |
| `smoke/smoke_preview_workflow.sh` | ADD smoke test line |
| `smoke/fixtures/arch-viz-sample.md` | CREATE - generic fixture |
| `docs/arch-viz-sample.md` | CREATE - nav-registered sample (reuses fixture data) |
| `mkdocs.yml` | ADD nav entry for arch-viz-sample |

---

## Implementation: `render_arch_viz.py`

Follows exact same patterns as `render_system_map.py`:

```
scripts/render_arch_viz.py <input.md> [--output <path>] [--title <text>] [--no-open]
```

**Steps inside the script:**
1. Parse args (positional `input`, optional `--output`, `--title`, `--no-open`)
2. Read markdown, find `` ```arch-viz `` fenced block (regex, same as system-map)
3. Parse JSON block (json.loads; error if missing/invalid)
4. Extract title from JSON `project.title` or `--title` arg or first H1
5. Slugify → output path `~/Desktop/<slug>-arch-viz.html`
6. Inject config into HTML template:
   - Template is embedded multiline string in the script
   - Single substitution: `"__CONFIG_PLACEHOLDER__"` → `json.dumps(config)`
7. Write output file
8. Static check: file exists + size > 1000 bytes
9. Print `html=<path>`
10. `open()` unless `--no-open`

**HTML template:**
- Full refactor of `openbao-flow.html` making it 100% data-driven
- All JS reads from `const CONFIG = __CONFIG_PLACEHOLDER__;`
- `renderSidebar(CONFIG.identities)` generates left panel HTML
- `renderIdentityView(identity)` generates right panel - unchanged logic
- `renderFlows(CONFIG.flows)` generates tab content
- Dark theme CSS unchanged (same variables)
- ~1000-1200 lines embedded in Python as triple-quoted string
- Only external dep: Google Fonts CDN (same as current file)

---

## Smoke Test Addition

```bash
python3 scripts/render_arch_viz.py smoke/fixtures/arch-viz-sample.md \
  --output /tmp/codebase-helper-arch-viz-smoke.html --no-open
test -s /tmp/codebase-helper-arch-viz-smoke.html && echo "arch-viz: OK"
```

---

## Plane Task

Create AGENT project task at start. Branch name follows pattern:
`claude/feat/agent-XXX-codebase-helper-arch-viz`

PR body includes `[AGENT-XXX - Add arch-viz renderer to codebase_helper](...)` for auto plane-sync.

---

## Verification

1. Smoke test passes: `bash smoke/smoke_preview_workflow.sh`
2. Output file exists: `test -s ~/Desktop/<slug>-arch-viz.html`
3. Open in browser: renders correctly (left panel cards, right panel flows, tabs work)
4. PR triggers plane-sync: AGENT task moves In Progress
5. Merge triggers plane-sync: task moves Done

---

## What This Does NOT Do

- Does not modify `preview_markdown.py` (unrelated renderer)
- Does not add Python dependencies (stdlib + json only)
- Does not change existing renderers
- Does not add _lib/ shared utilities (out of scope)
- Does not create a CLI wrapper or new script entry point beyond the renderer itself
