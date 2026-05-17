---
name: User is not a developer
description: User's role and how to communicate technical concepts to them
type: user
originSessionId: 2f694a2f-6a7e-4f73-9ab5-d5744481bb66
---
The user is not a developer. They run a business (advertising agency, ARC) and direct the technical work but don't write code themselves.

When explaining anything technical: use plain English over jargon. Say "we'll link these tables" not "establish FK constraints with cascade delete." Say "the database forgot the connection" not "the FK reference is dangling." Say "we have two columns holding the same thing" not "denormalized duplicate."

Detail is still required. They want to understand what's happening and approve each step. The bar is plain English with full context, not stripped-down explanations.

Hard exception: when generating prompts for OTHER bots/agents (Hermes, etc.), technical terminology is fine because the receiver is a machine, not the user.
