---
name: Research named products/features before answering
description: When user asks about a named product, feature, tool, or term I'm not 100% sure of, WebSearch before answering. No guessing on factual questions.
type: feedback
originSessionId: 94f04b01-b1c9-481c-b306-1771e5593585
---
# Research named terms before answering

Triggered 2026-04-27 by Cowork failure: user asked "can Claude Cowork manage my skills" - I assumed cowork = generic word, wrote ~50 lines of guesses across 4 turns. Real answer: Cowork is Anthropic's agentic desktop app with local VM + folder grants. One WebSearch at turn 1 would have given the correct answer.

## Rule

If the user references a **named product, feature, tool, protocol, or term** and I am not 100% certain what it is or how it works, **WebSearch / WebFetch FIRST, answer second.** No improvising. No "I think it means..." No generic-word fallback for branded names.

**Why:** Guessing on factual product questions wastes turns, produces hallucinations ("separate machine"), and forces the user to rage-correct me into doing the research I should have done in turn 1.

**How to apply:**
- User mentions a product/feature name I cannot fully describe -> WebSearch the exact name + key context word
- Capitalized or quoted term I do not recognize -> assume branded, look it up
- "Can X do Y?" / "How does X work?" / "What is X?" -> research is the FIRST step, not last resort
- Apply BEFORE drafting any answer. Do not write answer then verify - draft becomes anchoring.

## Source hierarchy - validate BEFORE citing

Not all search hits equal. Use sources in this order; stop at first authoritative hit:

1. **Native vendor docs** - the platform's own docs site (e.g. `docs.anthropic.com`, `claude.com/product/*`, `support.claude.com`, `code.claude.com`, `developer.apple.com`, `nodejs.org/docs`). Always first. Brand-owned = canonical.
2. **Vendor GitHub repo** - `github.com/<vendor>/<product>` README, `/docs/`, releases, issues. Authoritative for OSS or vendor-published code.
3. **Spec / standards sites** - `modelcontextprotocol.io`, `tc39.es`, RFC docs, W3C. For protocols/standards.
4. **Context7 / devdocs.io / mdn** - aggregated official docs. Fine when native is paywalled or hard to navigate.
5. **Vendor-adjacent**: official blog posts, Anthropic Help Center, vendor YouTube/Discord announcements.

**Avoid unless above produce nothing:**
- News sites (TechCrunch, The Verge, XDA, Tom's Guide) - paraphrase docs, often stale or wrong
- **Medium - hard avoid.** SEO farm, dated, frequently wrong. Skip even if top result.
- DataCamp / freeCodeCamp / generic tutorial sites - paraphrased, often dated
- AI-generated SEO blogs - hallucination risk

**Conditional - use if vendor docs thin:**
- Substack - sometimes useful (independent expert writeups, e.g. thesignal.substack.com on Anthropic products). Check author credibility. OK when pointing at a primary source or first-hand testing.
- Dev.to - case-by-case, often paraphrased docs but occasionally has working code examples
- Reddit / HN - useful for "is this a known issue", user reports, version gotchas. Not for canonical facts.

If only secondary hits available -> say so explicitly: "no native docs found, using <source>" and flag uncertainty.

**Validation checks before citing:**
- URL domain matches the vendor (anthropic.com, claude.com - not "claude-ai-tutorial.net")
- Page has a publish/updated date and it is recent (within ~12 mo for fast-moving products)
- Multiple authoritative sources agree if the claim is non-obvious
- If two sources conflict, native docs win

**Search query patterns:**
- Start: `site:docs.<vendor>.com <feature>` or `<product> docs <feature>`
- Fallback: `<product> github` -> repo README
- Last resort: open search, filter results by domain manually

## Distinction from action-over-research

`feedback_action_over_research.md` says act fast on **debug/fix** tasks (mem-search, act, do not keep investigating). This rule is the opposite case: **factual/explanatory** questions about named things. Different task type, different default.

| Task type | Default |
|-----------|---------|
| Debug / fix / "X is broken" | Act fast, mem-search, one investigation pass |
| Factual / "what is X" / "how does X work" | Research first, WebSearch named terms, answer second |
| "Help me decide between X and Y" | Research both before recommending |

## Anti-patterns from this session

- Treated "cowork" as English compound instead of branded product name
- Wrote long generic answer about plugin management without verifying which surface "cowork" actually is
- Said "separate machine" implying desktop = different computer (it is the same Mac)
- Required two user rage-prompts before triggering WebSearch

## Last updated

2026-04-27 (added source hierarchy + validation rules)
