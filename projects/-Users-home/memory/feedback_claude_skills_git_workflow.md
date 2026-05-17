---
name: Claude skills git workflow - auto-commit on edit
description: Any edit to ~/.claude/skills/ must be immediately committed and pushed to arc-web/claude-skills. Never leave skill edits uncommitted.
type: feedback
originSessionId: 8cab95d3-0c83-4722-af67-bc247670d7d7
---
~/.claude/skills is a symlink to ~/ai/tools/ai/claude-skills (arc-web/claude-skills on GitHub).

All skills including web-* live in ~/ai/tools/ai/claude-skills (arc-web/claude-skills). web-* skills follow the same web-*/SKILL.md directory pattern as all other skills.

**Rule:** Any time a file under ~/.claude/skills/ is created or edited, commit immediately:

```bash
cd ~/ai/tools/ai/claude-skills
git add <changed file(s)>
```

```bash
git commit -m "<type>: <skill-name> - <what changed>"
git push
```

Do this without being asked. Do not finish the turn with uncommitted skill changes.

**For significant structural changes** (new skill, major rewrite): create a branch + PR instead of pushing directly to main.

**For small edits** (typo fix, adding a checklist item, updating a token value): commit directly to main.

**ads/ is excluded** - symlink to external repo (AgriciDaniel/claude-ads). Never commit it.

**Why:** Skill files are agent configuration. An uncommitted skill edit is a silent change with no recovery path. The user should never have to ask for this.
