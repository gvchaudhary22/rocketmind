<!-- GENERATED FILE - DO NOT EDIT MANUALLY -->
<!-- Source: templates/*.tpl.md + rocketmind.registry.json -->
<!-- Regenerate: node bin/generate-instructions.js --human-views -->

# RocketMind Workflows
> Standard execution paths for the framework

## All Workflows
<!-- GENERATED:START workflows_list -->
- `/rocketmind:discover` [collaborative] — inputs: problem statement, target user hypothesis → outputs: DISCOVERY.md
- `/rocketmind:new-project` [collaborative] — inputs: scope, users, constraints, existing systems → outputs: PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md
- `/rocketmind:plan` [collaborative] — inputs: STATE.md, ROADMAP.md, REQUIREMENTS.md → outputs: PHASE-{N}-PLAN.md
- `/rocketmind:build` [autonomous] — inputs: PHASE-{N}-PLAN.md, ARCH.md, STATE.md → outputs: task outputs, SUMMARY.md, PHASE-{N}-VERIFICATION.md
- `/rocketmind:verify` [audit] — inputs: PHASE-{N}-PLAN.md, build outputs → outputs: PHASE-{N}-UAT.md
- `/rocketmind:ship` [audit] — inputs: PHASE-{N}-UAT.md, review output, CHANGELOG.md, README.md → outputs: release summary, CHANGELOG.md update, documentation updates, STATE.md update
- `/rocketmind:launch` [collaborative] — inputs: release artifacts, target audience, launch channels → outputs: LAUNCH-PLAN.md, GTM-CHECKLIST.md, ANNOUNCEMENT-DRAFT.md
- `/rocketmind:quick` [collaborative] — inputs: task description → outputs: focused task result, verification, state update
- `/rocketmind:forge` [collaborative] — inputs: task description → outputs: new agent file, registry update
- `/rocketmind:review` [audit] — inputs: changed files, ARCH.md, REQUIREMENTS.md → outputs: review report
- `/rocketmind:audit` [audit] — inputs: changed files, dependency graph → outputs: security audit report
- `/rocketmind:eval` [audit] — inputs: README.md, registry, runtime adapters, workflow docs → outputs: EVAL-REPORT.md, eval-report.json
- `/rocketmind:resume` [collaborative] — inputs: STATE.md, pre-compact snapshot, git log → outputs: reconstructed context
- `/rocketmind:next` [collaborative] — inputs: STATE.md, ROADMAP.md → outputs: next action
- `/rocketmind:progress` [audit] — inputs: STATE.md, ROADMAP.md → outputs: project status summary
- `/rocketmind:map-codebase` [audit] — inputs: repo tree, source files, STATE.md → outputs: CODEBASE-MAP.md
- `/rocketmind:monitor` [audit] — inputs: health endpoints, metrics, alerts → outputs: HEALTH-REPORT.md
- `/rocketmind:debug` [collaborative] — inputs: bug description, failing test or reproduction → outputs: root cause analysis, fix, regression test
- `/rocketmind:deploy` [audit] — inputs: environment, release artifacts → outputs: deployment summary
- `/rocketmind:rollback` [audit] — inputs: failed deployment, release metadata → outputs: rollback summary
- `/rocketmind:milestone` [audit] — inputs: shipped phases, state, release tags → outputs: milestone archive
- `/rocketmind:help` [collaborative] — inputs: none → outputs: command reference
- `/rocketmind:riper` [collaborative] — inputs: task description, context → outputs: RIPER analysis
- `/rocketmind:worktree` [collaborative] — inputs: parallel task plan → outputs: worktree setup guidance
- `/rocketmind:cost` [audit] — inputs: session usage → outputs: token and cost estimate
- `/rocketmind:promote` [collaborative] — inputs: local patterns, agents, skills → outputs: core repository PR, registry update
- `/rocketmind:ask` [collaborative] — inputs: question about project state → outputs: answer from STATE.md or context.db with source citation
- `/rocketmind:clarify` [collaborative] — inputs: pending clarification requests, operator answer → outputs: clarification queue, clarification resolution
<!-- GENERATED:END workflows_list -->

## Registry Discipline
- Workflow definitions live in `rocketmind.registry.json`.
- `/rocketmind:*` command docs are human-readable wrappers over the canonical workflow definitions.
- A workflow should define its required inputs, outputs, and verification gate.

## Wave Execution Pattern
1. Plan the phase as a set of dependency-ordered waves.
2. Put independent tasks in the same wave.
3. Give each subagent a fresh context bundle.
4. Collect summaries after each wave.
5. Verify the full phase before shipping.
6. Update state after completion and before compaction.

## Artifact Chain
- `/rocketmind:discover` produces `DISCOVERY.md`.
- `/rocketmind:new-project` produces `PROJECT.md`, `REQUIREMENTS.md`, and `ROADMAP.md`.
- Planning produces `PHASE-{N}-PLAN.md`.
- Execution produces task outputs and `SUMMARY.md`.
- Verification produces `PHASE-{N}-VERIFICATION.md` and `PHASE-{N}-UAT.md`.
- Shipping updates state and release metadata.

## Reasoning Framework Hierarchy
Two named frameworks operate at different levels — their precedence is explicit:

- **RIPER** (`skills/riper.md`) is the **outer loop** governing the full task lifecycle (Research → Innovate → Plan → Execute → Review). It applies to every non-trivial task.
- **RALPH** (`skills/reflection.md`) is the **inner recovery loop** — an error-correction reflex that fires automatically inside RIPER's Execute step when an attempt fails. You never invoke RALPH directly.

See `skills/riper.md` → *Relationship to RALPH* for the full hierarchy explanation and a side-by-side comparison table.
