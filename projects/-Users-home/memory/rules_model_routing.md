---
name: Model routing for automated tasks
description: Model selection for automated/agent LLM calls - Gemini + Kimi only via OpenRouter, never Anthropic API
type: feedback
originSessionId: 44a55046-8629-451c-a4c9-2441d96b25dc
---
## Model Routing - Automated Tasks

Never use Anthropic API for automated or agent tasks. All automated LLM calls go through OpenRouter. Default agentic model is **kimi-k2** (moonshot/kimi-k2) unless task is cheap/fast.

### Tier table

| Tier | Model | In/M | Out/M | Use for |
|---|---|---|---|---|
| Cheap | gemini-2.5-flash-lite | $0.10 | $0.40 | Cheapest drafts, low-stakes formatting |
| Primary | gemini-2.5-flash | $0.30 | $2.50 | Daily reports, structured output, compile.py |
| **Default** | kimi-k2 (moonshotai/kimi-k2) | $0.745 | $4.655 | Default for all agentic tasks, ad copy gen, long-context chains |
| Reasoning | gemini-2.5-pro | $1.25 | $10.00 | Hard reasoning, big context windows |

### Decision logic

Default to **kimi-k2** (via OpenRouter: `moonshot/kimi-k2`) for all google_ads_agent work, ad copy generation, and agentic chains. Gemini flash for cheap/fast structured output. Never Anthropic API keys.
