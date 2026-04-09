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
- Automated reviewers may generate comments that aren't auto-resolved
- Distinguish critical (bugs, logic errors) vs style (edge cases, documentation)
- When PR is approved but has style comments: acknowledge trade-offs explicitly before merging

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
