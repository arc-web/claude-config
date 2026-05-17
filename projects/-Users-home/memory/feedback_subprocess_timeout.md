---
name: Subprocess timeout rule
description: Never write blocking subprocess reads without a timeout - will hang forever if child dies or writes to wrong fd
type: feedback
originSessionId: cc608d55-7c73-4963-a2ee-9f4bd8ff93a9
---
Never use byte-by-byte blocking reads (`proc.stdout.read(1)`) on subprocesses. Always use `proc.communicate(timeout=N)` or `asyncio` with a timeout.

**Why:** smoke_test.py ran at 100% CPU for 10+ hours because the MCP server wrote to stderr instead of stdout. The read loop blocked forever with no timeout, no detection.

**How to apply:** Any time writing a script that spawns a subprocess and reads its output - use `communicate(timeout=10)` or `select` with a timeout. Verify the binary path exists before spawning. Test with a 5-second timeout minimum.
