---
name: aibrainbuilders.com Resend sender domain
description: Resend free plan only allows 1 domain - exitstorm.com is verified. aibrainbuilders.com sender upgrade pending.
type: project
originSessionId: 105d8b3b-b640-4d6b-a448-e3e5bbbf6eed
---
Forms on aibrainbuilders.com send via Resend from `contact@exitstorm.com` (verified) to `me@advertisingreportcard.com`.

**Why:** Resend free plan = 1 domain max. exitstorm.com was already verified. Adding aibrainbuilders.com requires Resend Pro ($20/mo).

**How to apply:** When user is ready to send from `contact@aibrainbuilders.com`, upgrade Resend plan and run `POST https://api.resend.com/domains` with `{ name: "aibrainbuilders.com" }`, then add the returned DNS records via `cf-deploy dns add`, then update `FROM_EMAIL` in `/tmp/aibrainbuilders-worker/worker.js` and redeploy. Worker is at Cloudflare Worker name `aibrainbuilders`.
