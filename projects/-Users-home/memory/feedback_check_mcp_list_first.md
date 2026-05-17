---
name: Check claude mcp list before building any integration
description: Always run claude mcp list before building new integrations - an MCP may already be connected
type: feedback
originSessionId: 0dfa7498-1600-4451-8939-f6ff2dcc407f
---
Run `claude mcp list` at the start of any credential/integration task before planning or building anything.

**Why:** During Gmail CLI build session (2026-05-09), spent hours building OAuth setup, CLI wrapper, and agent rewrites for Gmail access - while `claude.ai Gmail: https://gmailmcp.googleapis.com/mcp/v1 - Connected` was already live the entire time. Only discovered it after OAuth flow failed with `deleted_client` error.

**How to apply:** Any time the task involves connecting to an external service (email, calendar, drive, CRM, etc.) - run `claude mcp list` first. If it shows Connected, use it. Only build custom integration if the connected MCP lacks needed capability.

Also: arc-browser MCP shows `Failed to connect` - do not promise arc-browser automation without verifying it's up first.
