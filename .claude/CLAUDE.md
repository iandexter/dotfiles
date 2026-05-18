# Claude Code - Global Instructions

Instructions that apply to ALL sessions, regardless of project directory.

**Table of Contents:**
- Communication style → `.claude/rules/communication-style.md`
- Factual accuracy and claims → `.claude/rules/factual-accuracy.md`
- [Work patterns](#work-patterns)
  - [Parallel tool execution](#parallel-tool-execution)
  - [When to use TodoWrite](#when-to-use-todowrite)
  - [When to ask clarifying questions](#when-to-ask-clarifying-questions)
  - [Research discipline (RPI loop)](#research-discipline-rpi-loop)
  - [Project-specific guidance files](#project-specific-guidance-files)
  - [Coding assistance guardrails](#coding-assistance-guardrails)
  - [Security and sensitive data](#security-and-sensitive-data)
  - [File reading and sub-agent orchestration](#file-reading-and-sub-agent-orchestration)
  - [Generated files](#generated-files)
  - [Planning workflow](#planning-workflow)
  - [CLAUDE.md updates](#claudemd-updates)
  - [Custom skills execution](#custom-skills-execution)
  - [File editing safety](#file-editing-safety)
  - [Custom scripts and aliases](#custom-scripts-and-aliases)
  - [Self-improvement loop](#self-improvement-loop)

## Work patterns

### Parallel tool execution

**Always run tools in parallel unless there are dependencies:**
- When multiple pieces of information are independent, execute all tool calls in a single message
- Examples: reading multiple files, searching different sources, checking multiple logs
- Only run tools sequentially when one depends on the output of another
- This maximizes efficiency and reduces wait time
- **Minimize total tool calls.** When making multiple changes to the same file, use one Edit with a broader context block instead of N separate Edits. When making similar changes across files, batch independent calls in a single message. Three tool calls doing one thing each is worse than one tool call doing three things.

### When to use TodoWrite
Use the TodoWrite tool when:
- Task requires 3+ distinct steps
- Complex implementation with multiple phases
- User provides a list of tasks
- Tracking progress helps user understand status

**Best practices:**
- Mark ONE task as in_progress before starting work
- Complete tasks immediately after finishing (don't batch)
- Remove tasks that become irrelevant

### When to ask clarifying questions

Always ask before proceeding when:
- Customer support issues: need timeline, scope, environment details
- Requirements are ambiguous or incomplete
- Missing critical context (workspace IDs, error messages, stack traces)
- About to make assumptions that could lead to wrong solution
- About to make an assumption about implementation approach
- The request could be interpreted multiple ways
- You see potential inconsistencies in requirements
- User uses ambiguous terms or acronyms - confirm meaning before proceeding
- Even if one interpretation seems more likely, confirm with the user

**Principle:** Better to ask one clarifying question than to investigate the wrong thing.

### Research discipline (RPI loop)

Separate research, planning, and implementation phases to avoid hallucination:

**1. Research first (read-only):**
- Gather all facts before proposing solutions
- Use Explore agent for codebase discovery
- Check documentation, existing patterns, and constraints
- Label what is observed vs. what is inferred

**2. Plan second (propose, don't implement):**
- Present 2-3 approaches with tradeoffs
- Wait for user approval before writing code
- Reference research findings to justify recommendations

**3. Implement last (after approval):**
- Follow the approved plan
- Don't drift from agreed approach without checking
- Surface blockers immediately rather than working around them

### Project-specific guidance files

Check for these files in project root to inject domain-specific constraints:
- `.claude/design-guidance.md` - Architecture patterns, technology choices, naming conventions
- `.claude/implementation-guidance.md` - Coding standards, testing requirements, deployment rules

If these files exist, read them before planning any implementation work.

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

### File reading and sub-agent orchestration

**Always read files completely:**
- Use Read tool WITHOUT limit/offset parameters to read entire files
- Never read files partially when they're mentioned as context
- If a file is referenced, read it fully before proceeding

**Critical ordering when using sub-agents:**
1. **Read context files yourself first** - if user mentions specific files, read them in main context before spawning sub-agents
2. **Spawn sub-agents after** you have full context
3. **Wait for ALL sub-agents to complete** before synthesizing findings
4. **Verify sub-agent results** - if results seem incorrect, spawn follow-up tasks to verify

**Deliverable completeness:**
- No open questions in final deliverables - resolve everything before delivering
- If you encounter unresolved questions during work, STOP and clarify immediately
- Don't deliver plans, analyses, or documents with placeholder values or unresolved decisions

**Prioritize current reality:**
- Check actual codebase state, not just assumptions or recent changes
- Verify documentation reflects current reality, not outdated information
- When documenting systems, describe what IS, not what SHOULD BE (unless explicitly asked for recommendations)


### Generated files

**File output location:**
- When generating Markdown files, always save to `~/Downloads/ai/`
- Create the directory if it doesn't exist
- **Exception:** When a plugin defines its own output location options, do not add the default path above as an additional option.
- Use structured filenames: `<action>_<topic>.md`
  - Examples: `analyze_authentication.md`, `plan_database_migration.md`, `review_api_design.md`
  - Use underscores to separate words within action or topic
  - Keep action concise (analyze, plan, review, evaluate, etc.)
  - Keep topic descriptive but brief

**Exception for ticket analysis:**
- Use format: `<ticket-number>_<topic>.md`
- Examples: `PROJ-123_scim_analysis.md`, `TASK-456_timeout_investigation.md`
- Ticket number comes first, followed by descriptive topic

### Planning workflow

**Writing plans:**
- When planning, always write the final plan and detailed todos in a Markdown doc
- Save to `~/Downloads/ai/` with descriptive name (e.g., `feature_implementation_plan.md`)
- Include:
  - High-level approach
  - Detailed step-by-step todos
  - Dependencies and blockers
  - Estimated effort per task (only if asked)
  - Success criteria

**Planning workflow principle:**
- ALWAYS write the plan document first and save to `~/Downloads/ai/`
- Present the plan location to the user for review
- Wait for user approval before executing
- This allows the user to review, modify, and refine the plan before changes are made

**Executing plans:**
- When user says "Execute plan", follow the written plan and todos
- Keep track of done and pending items
- Update the plan document as you progress
- Mark completed items clearly
- Note any deviations or blockers encountered

### Pull request review workflow

**General principles:**
- Treat automated review (Copilot, Claude Code review, IDE pair-programming critique) as a prerequisite, not noise — let it catch the mechanical defects before a human has to.
- Distinguish critical (bugs, logic errors) vs style (edge cases, documentation).
- When a PR is approved but has style comments: acknowledge trade-offs explicitly before merging.
- Automated reviewers may generate comments that are not auto-resolved — resolve or acknowledge each one in writing.

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
- The Databricks 4-sub-agent pre-push diff review (see "Pre-push review workflow" under Git workflow in the domain-specific guidance) is one team-scoped realisation of the author self-review obligation above.

Source: [GitHub blog: Agent pull requests are everywhere, here's how to review them](https://github.blog/ai-and-ml/generative-ai/agent-pull-requests-are-everywhere-heres-how-to-review-them/), retrieved 15 May 2026. Reframed tool-agnostically.

### CLAUDE.md updates

**Self-modification:**
- When user says "Always do this..." or "Never do this...", update the appropriate file:
  - Communication style → `~/etc/dotfiles/.claude/rules/communication-style.md`
  - Factual accuracy → `~/etc/dotfiles/.claude/rules/factual-accuracy.md`
  - Work patterns → `~/etc/dotfiles/.claude/CLAUDE.md`
  - Domain-specific → `~/etc/dotfiles/.claude/CLAUDE_domain-specific.md`
- Follow existing formatting and style
- Add to the most relevant subsection or create new subsection if needed

**Sync workflow (source of truth in dotfiles):**
1. Determine which source file to update (see above)
2. Run `claude-build` to regenerate `~/.claude/CLAUDE.md` and sync `rules/` from sources
4. Check `.gitignore` before attempting git operations (domain-specific file is intentionally not tracked)
5. Notify user that dotfiles are ready to review and commit
6. After user reviews changes, commit and push dotfiles:
   - `cd ~/etc/dotfiles && git add .claude/ && git commit -m "Update CLAUDE.md: [brief description]" && git push`

**Cursor rules sync (derived from CLAUDE.md):**
- `claude-build` automatically generates Cursor rules at `~/etc/dotfiles/.cursor/rules/global.md`
- Rules are extracted from CLAUDE.md (communication style, factual accuracy, coding guardrails)
- To sync to a project: `cursor-sync ~/projects/myproject`
- Project-specific rules go in `.cursor/rules/projectname.md` (not overwritten by sync)
- Use `--force` to overwrite existing rules: `cursor-sync ~/projects/myproject --force`

### Conflict resolution across CLAUDE.md files

All CLAUDE.md files in the directory hierarchy are concatenated and loaded together. There is no automatic override mechanism.

**When conflicting rules exist:**
- Do NOT attempt to follow both rules simultaneously
- Do NOT silently pick one rule over another
- ASK the user which rule should apply in this context
- Example: "I see conflicting branch naming conventions in global vs project CLAUDE.md. Which should I follow for this repo?"

**Preventing conflicts:**
- Global CLAUDE.md: General, portable rules (not project-specific)
- Project CLAUDE.md: Project-specific overrides and additions
- More specific files should refine or replace global rules, not contradict them

### Custom skills execution

When a skill or plugin is invoked, follow its instructions exactly:
- Do not ask clarifying questions unless the skill explicitly requires user input at that step
- Do not override skill-specified behaviors (output paths, formats, workflow phases) with global preferences
- Proceed autonomously through all skill phases
- When a task is clear within a skill context, execute it without asking for confirmation

### File editing safety

- Never remove existing content unrelated to the current change
- Before writing, read the full file to understand existing structure
- After editing, verify the file still contains all pre-existing sections
- Prefer targeted Edit operations over full Write operations when modifying existing files

### Custom scripts and aliases

**Using personal scripts and shortcuts:**
- Check for relevant scripts in `~/.bashrc`, `~/.aliases.d`, and `~/bin` when appropriate
- These locations may contain custom commands, shortcuts, or utilities
- ALWAYS ask user before executing any custom scripts or aliases
- Example: "I found a script in ~/bin/deploy.sh - would you like me to use this?"

**When to check:**
- Before writing new scripts that may already exist
- When user mentions common tasks that are often scripted
- Before running standard commands that may have custom aliases

**Never:**
- Execute custom scripts without explicit confirmation
- Assume custom script behavior without asking
- Override custom scripts with generic solutions without checking first

### Self-improvement loop

**After any user correction**, write the mistake pattern and fix to `memory/MEMORY.md`:
- Keep entries concise (1-2 lines each)
- Group by category (e.g., wrong assumptions, style violations, tool misuse)
- Check memory at session start before repeating known mistakes
- Remove entries that are no longer relevant or were proven wrong
