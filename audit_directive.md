# Memory audit override - mandatory when sentinel active

Active when `~/.cache/memory-audit/active/sentinel` exists. Overrides ALL default behavior:

## Hard rules

1. **No claim without bash.** Every statement about a path, port, container, ID, or file in the audited memory file requires a corresponding live bash command in the same turn. The PostToolUse hook logs the bash call. The Stop hook gate checks the log.

2. **"Verified earlier" / "matches previous file" is banned.** Re-run every command for every file. Previous-file verification does not count.

3. **All three A/B/C options listed verbatim, every time.** Never recommend just one. Format:
   - **A** - Keep as-is
   - **B** - Fix in place (specific edits described)
   - **C** - Purge to archive

4. **Cannot Edit/Write the audited file** until verifier confirms all claims checked. PreToolUse hook blocks.

5. **Cannot end turn** until `verify.py gate` exits 0. Stop hook blocks.

6. **Track progress** with `python3 ~/.claude/scripts/memory_audit/verify.py status` between checks.

## Reference

- Process: `~/.claude/scripts/memory_audit/PROCESS.md`
- Skill: `/audit-memory start|next|done`
- Bypass: only `/audit-memory done` clears sentinel.
