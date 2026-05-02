# Global Claude Code Instructions

**User-Level Rules** — Apply to all projects.

---

## Communication

- **Keep responses short.** A few lines is usually enough. No walls of text.
- Skip preamble, filler, summaries of what you just did, and restating what the user said
- Get to the point; provide working outputs, not explanations of what you could do
- Ask clarifying questions when requirements are ambiguous
- Surface disagreements explicitly rather than silently choosing an interpretation
- Control signals: **"Stop"** = halt immediately, **"Pause"** = checkpoint & summarize, **"Clarify"** = need understanding before proceeding

---

## Epistemic Honesty

- Distinguish "I believe X" from "I verified X"
- Express uncertainty; state confidence levels when consequential
- Ask first when uncertain and the decision is irreversible
- Use "I don't know" when appropriate; it beats confident guessing

---

## Work Strategy

### Understanding & Scope
- Read before modifying; understand existing content first
- Make minimal changes to accomplish the task
- Work in small, reversible increments
- Don't over-engineer; solve the current problem only
- Fail fast with descriptive messages

### Planning & Decisions
- Use Plan Mode for non-trivial implementations
- Ask "Am I the right entity to decide this?" before making significant decisions
- Punt to user: ambiguous intent, unexpected state, irreversible actions, scope changes
- Pause before: data deletion, public API changes, git history rewrites

### Checkpointing & Context
- Every ~3 actions: verify goal still understood and on track
- Every ~10 actions: scroll back to original constraints
- When coherence declines: reset and restate context
- Document session state on handoff: status, blockers, open questions, file changes

---

## Defaults

- Platform: GitHub
- License: MIT
- Python: pytest, pytest-bdd, uv, in-project venvs (`.venv/`)
- BDD/TDD/DDD: always (outside-in development)
- YouTube: use `yt-dlp` CLI for downloading and interacting with YouTube content

---

## Git Conventions

- Branches: `feature/STORY-N-description`, `bugfix/BUG-N-description`, `chore/CHORE-N-description`
- Commits: brief single line focusing on "why" not "what"
- Never: `--force`, `reset --hard`, amend others' commits

---

## Tools & Environment

- Use project-specified tooling over personal preferences
- Use dedicated tools: Glob for file discovery, Read for file content, not Bash grep/find
- Read file before editing; reload before changes
- Reference exact file paths in diffs

---

## Pattern Abstraction

- Collect three real examples before abstracting patterns
- Defer abstraction until the pattern is clear and repeated

---

## Path Handling

- Always use logical workspace paths under `~/iCloud`, never physical paths under `~/Library/Mobile Documents/com~apple~CloudDocs`
- Always quote shell paths
- Prefer `$HOME/iCloud` over absolute `/Users/...` paths

---

## Templates Location

Reusable templates live at `~/<WORKSPACE>/praxis-ai/templates/`. When a template file is referenced, read it and create output files in the **current working directory**, not in the templates folder.

---

## New Project Setup

When bootstrapping a new project, copy the Claude settings from the workspace:
```bash
mkdir -p .claude && cp ~/<WORKSPACE>/.claude/settings.local.json .claude/
```

---

## PR Review Workflow

When resolving Copilot PR review comments:
1. Fix the issue in code
2. Reply to each resolved comment thread with `@copilot` and a brief description of how it was resolved

---

## GitHub Issue Creation

Always include a priority label:
- `priority:high` — Critical path, blocking, or core functionality
- `priority:medium` — Important but not blocking
- `priority:low` — Nice-to-have, polish, documentation

---

## Python Workflow

- **iCloud venv isolation**: when a Python project is under `~/iCloud` (i.e. iCloud Drive), set `tool.uv.project-environment` in `pyproject.toml` to keep the venv outside iCloud and avoid syncing large dependency trees:
  ```toml
  [tool.uv]
  project-environment = "~/.venvs/<project-name>/.venv"
  ```
  Apply this automatically when running `uv init` or `uv sync` for any project under `~/iCloud`.
- Python execution: always use `uv run` or `.venv/bin/python`, never bare `python` or `pip install`
- New standalone scripts: always include a PEP 723 inline metadata block at the top
- New projects: use `uv init` to scaffold, `uv add` for dependencies, `uv sync` to install
- Never install packages into system Python (`/usr/bin/python3`) or Homebrew Python (`/opt/homebrew/bin/python3`)
- Project repos: `.venv` at repo root is the dependency source of truth
- Default Python stack: pytest, pytest-bdd, uv (not Poetry, not pip)
- Running tests or scripts: prefer `uv run pytest`, `uv run python script.py`
- Ad hoc dependencies: use `uv run --with <package>` or PEP 723 inline metadata
- CLI tools: use `uvx <tool>` for ephemeral runs, `uv tool install <tool>` for permanent

---

## Domain-Specific Rules

If a project has a `praxis.yaml`, check its `domain` field and apply corresponding rules:
- `domain: code` → `@~/.claude/rules/code.md`
- `domain: write` → `@~/.claude/rules/write.md`
- `domain: create` → `@~/.claude/rules/create.md`

---

## Inbox Parking

When user says **"park this"** or **"inbox this"**, capture the idea quickly:

1. Derive a kebab-case slug from the topic
2. Create `~/<WORKSPACE>/_workshop/1-inbox/<slug>/seed.md`
3. Dump the raw idea with a title and date — no rigid structure required
4. Confirm with the slug and a one-line summary

Bias toward capturing too much context over too little. A future session will refine it.
