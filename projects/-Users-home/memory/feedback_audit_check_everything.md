---
name: Memory audit - check every claim, explain every claim, explain recommendation
description: During memory audit, verify EVERY claim live (no skipping low-priority items), state full findings (every claim checked + result), then list A/B/C with what each means in context, then recommendation with explicit reason. No truncation, no skipping.
type: feedback
originSessionId: 7e21b670-8839-4814-994f-a40d191f9629
---
# Audit format: full check, full explanation, justified recommendation

## Mandatory per file

1. **Check every claim live.** No skipping "low priority" items. If memory says X, verify X. Includes fingerprints, IDs, file perms, anything stated.
2. **State everything checked + result.** Every claim with its match/mismatch. Don't summarize past first verification, don't skip "minor" ones.
3. **A/B/C explained in context.** What A means for THIS file, what B would change, what C removes.
4. **Recommendation with reason.** `Recommend: <letter>` + explicit reason tied to findings.

**Why:** User flagged 2026-05-01 hard - skipping RSA fingerprint check ("not verified, low priority") then giving recommendation was unacceptable. Audit goal is full verification. Cutting corners defeats the point.

**How to apply:** Every audited file. Even if extractor reports 0 claims, manually re-read file and verify every concrete claim (paths, UUIDs, perms, fingerprints, hostnames, account fields, dates that imply state). If something can be checked, check it.
