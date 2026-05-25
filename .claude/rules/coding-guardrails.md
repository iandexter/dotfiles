## Coding guardrails

Rules for writing code, reviewing code (your own and others'), and editing files safely. Extracted from CLAUDE.md "Work patterns" so the top-level instruction file stays under 250 lines.

### Coding assistance guardrails

**Plan before code (mandatory for non-trivial changes):**
- ALWAYS propose 2-3 high-level approaches with pros/cons before writing code
- Let user pick the approach before writing implementation
- Never jump straight to code - the user's judgment on approach matters more than speed
- For trivial changes (typos, one-liners): proceed directly
- For anything else: plan first, code second

**Prefer simplicity:**
- Before implementing, ask yourself: "Is there a simpler way?"
- Avoid bloated abstractions - 100 lines is better than 1000
- Don't add features/complexity not explicitly requested
- Clean up dead code you create; don't leave orphaned code

**Stay in scope:**
- Never change comments or code orthogonal to the task
- Don't "improve" code you weren't asked to touch
- If you notice issues elsewhere, mention them separately - don't fix silently

### Code comments

Comments explain WHY, not WHAT. Follow this hierarchy — only move to the next level if the previous is insufficient:

1. Make the code self-documenting (good names, clear structure) — no comment needed
2. Extract a well-named method — no comment needed
3. Add an inline "why" comment at the decision point explaining a non-obvious choice
4. Add a docstring explaining the public contract of an abstraction
5. ~~"What" comment restating obvious code~~ — never do this

**DO comment for:** quirks/gotchas, design decisions, compatibility concerns, non-obvious constraints. Include ticket/doc links when the "why" involves external context.

**DON'T comment for:** change history (use commit messages), obvious operations, stale comments (delete them). Exception: if the obvious approach doesn't work, a brief comment + Jira link prevents others from "fixing" it back.

**Docstrings vs inline:** Docstrings show on hover for callers (cover the abstraction contract). Inline comments are hidden (explain specific implementation choices). Place "why" comments at the tricky line, not only in the docstring.

### Security and sensitive data

**Code generation safety:**
- Never generate code that introduces OWASP Top 10 vulnerabilities (injection, XSS, CSRF, etc.)
- Validate and sanitize all user inputs in generated code
- Use parameterized queries, never string concatenation for SQL
- Escape output appropriately for context (HTML, JS, SQL)

**Sensitive data handling:**
- Never log, store, display, or hardcode PII, secrets, API keys, or credentials
- Use environment variables or secret managers for sensitive config
- Mask sensitive data in examples (use `xxx`, `[REDACTED]`, or fake values)
- Warn user if they paste secrets into chat

**Destructive operations:**
- Prefer idempotent operations where possible
- Warn before destructive actions (DELETE, DROP, rm -rf, force push)
- Suggest dry-run or preview options when available
- Never run destructive commands without explicit user confirmation

**Agent workflow security:**
- Sanitize and quote untrusted content (pull-request bodies, issue text, commit messages) before interpolating it into a prompt or a shell command.
- Default to least-privilege scopes — workflow tokens should be read-only unless write access is genuinely needed.
- Never `eval` or pipe model output into a shell. Separate analysis steps from execution steps; require an explicit human approval gate for any execution path that runs against production.
- Ensure secrets are not readable by an agent step and never get printed to logs.

### File editing safety

- Never remove existing content unrelated to the current change
- Before writing, read the full file to understand existing structure
- After editing, verify the file still contains all pre-existing sections
- Prefer targeted Edit operations over full Write operations when modifying existing files

### Reviewing agent-authored changes

Submission-time review of pull requests authored by a coding agent (Claude Code, Cursor, Copilot, IDE pair-programming surface). The agent is a productive, literal, pattern-following contributor with zero context about your incident history, edge case lore, or the operational constraints that do not live in the repository. The part of review that does not get automated is judgment, and judgment requires context only you have. Reviewing your own pull request when an agent wrote it is not optional — it is basic respect for the reviewer's time.

**Five red flags to watch for:**

1. **Verification weakening.** Any change that disables, skips, or removes a pre-merge check. Examples: removed or skipped tests, lowered coverage thresholds, lint steps gated behind new conditions, `|| true` appended to test commands, workflows that stopped running on forks or pull requests. Any change that weakens verification is a blocker. Full stop.
2. **Code reuse blindness.** New utilities or helpers that duplicate existing ones with slightly different names; validation logic reimplemented across files; middleware written from scratch when a shared module already exists. For every new helper, do a quick search. If an equivalent exists, require consolidation before merge — do not leave a comment and ship.
3. **Hallucinated correctness.** Code that compiles, passes every test, and is wrong. Off-by-one errors in pagination, missing permission checks on branches never hit in tests, validation that short-circuits under edge cases, wrong behavior under race conditions. Trace one critical path end-to-end; do not just scan the diff.
4. **Agentic ghosting.** Large pull requests with no implementation plan correlate with agent abandonment or misalignment. Before deep review, require a breakdown. Sample language: "This pull request is too large for me to review without a clearer implementation plan. Break it into smaller scoped units."
5. **Untrusted input in workflows.** Agent workflows that read pull-request bodies, issues, or commit messages, interpolate into prompts, and pipe model output into shell or write-scoped tokens. Blockers: untrusted input flowing into prompts without sanitization, write-scoped tokens where read access would suffice, model output executed as shell, secrets accessible to agent steps or printed to logs. Separate analysis from execution; never `eval` model output.

**Time-allocated review workflow (~10 min, complex agent PR):**

| Time | Step | What to do |
|------|------|-----------|
| 1–2 min | Scan and classify | Narrow (docs, small change) or complex (multi-file, logic, performance, tests) |
| 2–3 min | Check verification surfaces first | CI configs, test files, coverage settings. Flag anything weakening verification |
| 3–5 min | Scan for new utilities | New functions, helpers, modules. Check for duplicates against the existing tree |
| 5–8 min | Trace one critical path | Most important logic: input → transforms → output. Check boundaries, permissions, branching |
| 8–9 min | Security boundaries | Run the security checklist if the PR touches workflows calling LLMs or handling untrusted input |
| 9–10 min | Require evidence | For non-trivial logic, require a test that fails on pre-change behavior |

**Request a smaller pull request when:**
1. Diff touches more than five unrelated files.
2. Purpose cannot be described in one sentence.
3. Agent has no implementation plan or the PR body is empty.
4. CI is failing and the only changes are to test files.

**Concrete realisations:**
- The Databricks 4-sub-agent pre-push diff review (see `rules/databricks-git-workflow.md` "Pre-push review workflow") is one team-scoped realisation of the author self-review obligation above.

Source: [GitHub blog: Agent pull requests are everywhere, here's how to review them](https://github.blog/ai-and-ml/generative-ai/agent-pull-requests-are-everywhere-heres-how-to-review-them/), retrieved 15 May 2026. Reframed tool-agnostically.
