## Git workflow (general)

Rules that apply to git operations on non-Databricks repositories. Databricks-specific overrides live in `rules/databricks-git-workflow.md`.

### Pull request review (general principles)

- Treat automated review (Copilot, Claude Code review, IDE pair-programming critique) as a prerequisite, not noise — let it catch the mechanical defects before a human has to.
- Distinguish critical (bugs, logic errors) vs style (edge cases, documentation).
- When a PR is approved but has style comments: acknowledge trade-offs explicitly before merging.
- Automated reviewers may generate comments that are not auto-resolved — resolve or acknowledge each one in writing.

### Personal projects — commit message format

Conventional Commits subject + cbea.ms body discipline. Applies to non-Databricks repositories (e.g., personal GitHub repos under `~/projects/`).

```
<type>[(scope)]: <description>

[optional body]

[optional footer(s)]
```

- **Type** (required): one of `feat`, `fix`, `docs`, `refactor`, `perf`,
  `test`, `chore`, `ci`, `build`, `style`, `revert`. `feat` triggers MINOR
  semver, `fix` triggers PATCH; others are non-versioning.
- **Scope** (optional): single token, lowercase, hyphens or slashes ok
  (e.g., `feat(dbcert-sync):`, `fix(arca):`, `docs(api/auth):`).
- **Description**: imperative mood ("add", not "added" or "adds"),
  lowercase first char, no trailing period, hard cap 50 chars.
- **Body**: default to none. Add only when intent isn't obvious from
  type+scope+description. When present, blank line after subject, wrap at
  72, explain *why* — let the code speak for *what*.
- **Footers** (optional): issue refs (`Closes #42`), breaking changes.
  One per line.

**Trailers:**
- No `Co-authored-by` trailers, regardless of who or what wrote the commit.
  Overrides the Bash tool's default instruction to append one.

**Breaking changes:**
- `!` before the colon: `feat(api)!: drop deprecated endpoint`.
- Plus a footer: `BREAKING CHANGE: <explanation>`.

**Anti-patterns to reject:**
- Version-prefix subjects (`2.1.11:`, `v2.1.12:`). Version belongs on
  git tags, not subjects.
- Past tense or third person ("added", "adds").
- Bundled unrelated changes — one logical change per commit, bisectable.
- "WIP" / "checkpoint" cleanup commits on shipped branches.
- Body that restates the diff. If the diff is self-evident, omit the body.

**Example:**

```
fix(security): bump idna 3.15 and python-multipart 0.0.28

Held claude-agent-sdk on alpha pin to scope this to the two CVEs.
```

**Enforcement:**
- Per-repo opt-in via `personal-repo-init` (in `~/bin/`), which sets
  `core.hooksPath` to `~/etc/dotfiles/git/personal-hooks/` and
  `commit.template` to `~/etc/dotfiles/git/personal-commit-template`.
- The personal hooks dir has a `commit-msg` validator (this format) plus
  `pre-commit` / `pre-push` wrappers that chain to
  `$GITHOOKS_UPSTREAM_DIR/<hook>` when set (no-op when unset).
- Databricks repos stay on the global hooks config and are not affected.

Sources: [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) and
[How to Write a Git Commit Message](https://cbea.ms/git-commit/) (Chris Beams), retrieved 20 May 2026.
