---
description: RocketMind /rocketmind:riper - structured RIPER analysis with executable recovery-loop decisions
allowed-tools: all
---

Load `CLAUDE.md` and `INSTRUCTIONS.md` for control-plane context.
Load `skills/riper.md` and `skills/reflection.md`.
When execution fails inside the repo-local RIPER runtime, RocketMind should invoke the recovery path automatically so it records the error, updates `.rocketmind/state/last_error.json`, and emits a deterministic retry-or-halt decision.
Use `node bin/riper.js` for repo-local runtime rendering and `node bin/recovery-loop.js` for direct recovery-loop handling when needed.
