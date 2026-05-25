# Claude Code - Global Instructions

Instructions that apply to ALL sessions, regardless of project directory.

**Table of contents:**
- Communication style → `.claude/rules/communication-style.md`
- Factual accuracy and claims → `.claude/rules/factual-accuracy.md`
- Coding guardrails (plan-before-code, comments, security, file safety, reviewing agent-authored changes) → `.claude/rules/coding-guardrails.md`
- Git workflow (general / personal projects) → `.claude/rules/git-workflow.md`
- Work patterns (below)
- Domain-specific guidelines (`CLAUDE_domain-specific.md`)

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

### Coding and security guardrails

See `.claude/rules/coding-guardrails.md` for: plan-before-code rules, code-comment hierarchy, security rules (OWASP, sensitive data, destructive ops, agent-workflow security), file editing safety, and the playbook for reviewing agent-authored changes.

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

Save Markdown output under `~/Downloads/ai/<subfolder>/` per the directory table in CLAUDE_domain-specific.md. Filename format: `<action>_<topic>.md` (e.g., `analyze_authentication.md`); for ticket analysis use `<ticket-number>_<topic>.md` (e.g., `BL-15861_scim_analysis.md`). Exception: if a plugin/skill defines its own output path, don't override it.

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

### Git workflow

See `.claude/rules/git-workflow.md` for general PR review principles and the Conventional Commits format used in personal repositories. Databricks-specific git overrides live in the domain-specific section.

### CLAUDE.md updates

**Before adding any new rule:**
- Grep `~/.claude/CLAUDE.md` + `~/.claude/rules/` for a similar rule. If one exists, UPDATE it instead of duplicating.
- Pair the addition with 1 candidate removal. If nothing is removable, the new rule must be <5 lines.
- `claude-build` enforces a 900-line total cap across CLAUDE.md + rules/*.md; a build that breaches the cap exits non-zero.

**Self-modification:**
- When user says "Always do this..." or "Never do this...", update the appropriate file:
  - Communication style → `~/etc/dotfiles/.claude/rules/communication-style.md`
  - Factual accuracy → `~/etc/dotfiles/.claude/rules/factual-accuracy.md`
  - Coding/security/review → `~/etc/dotfiles/.claude/rules/coding-guardrails.md`
  - Git (general) → `~/etc/dotfiles/.claude/rules/git-workflow.md`
  - Databricks operations → `~/etc/dotfiles/.claude/rules/databricks-operations.md` (note: SSOT in Dropbox)
  - Git (Databricks) → `~/etc/dotfiles/.claude/rules/databricks-git-workflow.md` (note: SSOT in Dropbox)
  - Work patterns → `~/etc/dotfiles/.claude/CLAUDE.md`
  - Domain-specific → `~/etc/dotfiles/.claude/CLAUDE_domain-specific.md`
- Follow existing formatting and style
- Add to the most relevant subsection or create new subsection if needed

**Sync workflow (source of truth in dotfiles):**
1. Determine which source file to update (see above)
2. Run `claude-build` to regenerate `~/.claude/CLAUDE.md` and sync `rules/` from sources
3. Check `.gitignore` before attempting git operations (domain-specific file is intentionally not tracked)
4. Notify user that dotfiles are ready to review and commit
5. After user reviews changes, commit and push dotfiles:
   - `cd ~/etc/dotfiles && git add .claude/ && git commit -m "Update CLAUDE.md: [brief description]" && git push`

### Conflict resolution across CLAUDE.md files

Global + project CLAUDE.md files are concatenated; there is no automatic override. If a project rule conflicts with a global rule, ask the user which applies in this context (don't pick silently or try to follow both).

### Custom skills execution

When a skill or plugin is invoked, follow its instructions exactly. Do not override skill-specified output paths/formats with global preferences, and do not ask clarifying questions unless the skill explicitly requires user input.

### Custom scripts and aliases

Check `~/.bashrc`, `~/.aliases.d`, and `~/bin` for existing scripts before writing new ones. Confirm with the user before invoking any discovered alias or script (per coding-guardrails.md Destructive operations).

### Self-improvement loop

After any user correction, append a concise (1-2 line) entry to `memory/MEMORY.md` so the auto-memory layer can surface it next session. Remove entries that are obsolete.
