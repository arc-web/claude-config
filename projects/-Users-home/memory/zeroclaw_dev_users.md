---
name: zeroclaw dev user accounts
description: Non-root sudo users on zeroclaw VPS for external dev access; add/revoke pattern
type: project
originSessionId: 68b025a2-e500-42b7-83b4-0dc60a1cf4cc
---
Zeroclaw VPS now has per-dev sudo accounts for external collaborators. First account: `tronstar` = pward17@gmail.com (added 2026-04-28).

**Why:** Solo-dev shop opening up VPS access. Per-user accounts (not shared root key) for clean revoke + audit trail. Devs need full control to assist with agents under /docker/, /opt/.

**How to apply:**
- Add new dev: `adduser --disabled-password --gecos "<name> (<email>)" <user>` then `echo "<user> ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/<user>` (chmod 440), install pubkey at `/home/<user>/.ssh/authorized_keys` (chmod 600, chown user:user, .ssh chmod 700), `usermod -aG docker <user>`.
- Revoke: `deluser --remove-home <user> && rm /etc/sudoers.d/<user>`
- One file per dev under `/etc/sudoers.d/` = surgical revoke.
- SSH host: `srv1422665.hstgr.cloud` (or zeroclaw alias from local ~/.ssh/config).

**Current devs:**
- `tronstar` (uid 1002) - Patrick Ward, pward17@gmail.com, RSA key SHA256:zVTi/nLnWF5G3ZYGbUnL1gJ+xwxTIBQ+ZqU1IdkZ3kg, groups: tronstar+users+docker
