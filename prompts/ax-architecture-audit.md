# AI Experience Architecture Audit

Copy-pasteable prompts for auditing an existing Python CLI against the architectural baseline established in `deep_research/05-synthesis.md` (Vertical Slice Command Bus + non-bypassable governance kernel + agent-legibility KPIs).

Each prompt is self-contained: give it to an agent with read access to the target repo. Prompts are ordered from cheapest/highest-signal to deepest. Run them in sequence or in parallel — they share no state.

**How to use:** run each prompt with the agent's working directory set to the target repo — the prompts operate on the current repository (CWD). Each prompt writes its output to a file under `./docs/ax_arch_audit/` in the repo (create the directory if it doesn't exist). Do **not** summarize the output in chat — only report the path written and a one-line status.

---

## Prompt 1 — Repository Snapshot & Agent-Legibility Baseline

```text
You are auditing the Python CLI repository the current repository (working directory) for **agent legibility** — the property that an AI coding agent with a ~200k-token context window can navigate, modify, and verify the system without losing coherence.

Do **not** propose changes. Produce a factual snapshot only.

Report the following, with file paths and line counts as evidence:

1. **Entry points:** every `console_scripts` / `[project.scripts]` / `__main__` / Typer/Click/argparse root.
2. **Command surface:** total command count, max nesting depth, and the 10 deepest command paths.
3. **Top-level layout:** tree of `src/` (or repo root) to depth 2, with LOC per directory.
4. **Agent-memory files present:** `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `.agents/`, `.aiwg/`, `.nexus/`, ADR directories. For each, note size and last-modified date.
5. **Test layout:** co-located with features vs. centralized `tests/`; ratio of test files to source files.
6. **Dependency manager:** `uv`, Poetry, pip-tools, bare `requirements.txt`. Whether lockfile is committed.

**Output contract:** write a single Markdown document with the six sections above to `./docs/ax_arch_audit/01-snapshot.md` (create `./docs/ax_arch_audit/` if missing; overwrite if it exists). No recommendations. No prose outside the sections. In chat, reply only with the path written and a one-line status.
```

---

## Prompt 2 — Vertical Slice vs. Horizontal Layer Diagnosis

```text
Audit the current repository (working directory) to determine whether it is organized by **vertical slices** (one directory per feature containing handler + models + tests) or **horizontal layers** (`services/`, `models/`, `utils/`, `commands/` split across the tree).

Method:

1. Pick 5 user-visible commands at random (list them with file paths).
2. For each command, list **every file** touched by its execution path (handler → domain logic → I/O → persistence). Trace imports, don't guess.
3. Compute **Feature-Locality Score (FLS) = 1 / (number of distinct top-level directories touched)** for each command. Report the mean and the worst case.
4. Compute **Locality Index Lᵢ = 1 / (files × max_depth)** for each command.
5. Flag any command where FLS < 0.5 or Lᵢ < 0.1 — these are the high-cost-to-modify surfaces.

**Output contract:** write the full result to `./docs/ax_arch_audit/02-vertical-slice.md` — a table with columns `command | files_touched | directories_touched | max_depth | FLS | Lᵢ | verdict`, ending with a 3-sentence diagnosis (vertical-slice, horizontal-layer, or mixed). In chat, reply only with the path written and a one-line status.
```

---

## Prompt 3 — Governance Kernel Coverage

```text
In an agent-first CLI, cross-cutting concerns (auth, logging, evidence capture, idempotency, retries, error policy) must flow through a **single non-bypassable pipeline** — an "ActionRunner" / "Governance Kernel" / "Base Command". Feature code must not re-implement or bypass it.

Audit the current repository (working directory) and answer:

1. Does a single governance pipeline exist? Name the file and class/function.
2. What concerns does it cover? (auth, structured logging, audit/evidence emission, retries, timeouts, idempotency keys, error normalization, config loading)
3. **Governance Coverage %** — of all command handlers, what fraction actually routes through this pipeline? Show the numerator and denominator with file paths.
4. List every handler that **bypasses** the pipeline (direct `print`, direct `boto3.client(...)`, bare `try/except`, ad-hoc `logging.getLogger`, direct env-var reads inside handlers).
5. List every place cross-cutting concerns are **re-implemented** locally (per-command retry loops, per-command logging setup, per-command auth).

**Output contract:** write the full result to `./docs/ax_arch_audit/03-governance-kernel.md` — the five numbered sections above, followed by a one-line verdict: `KERNEL_PRESENT_AND_ENFORCED | KERNEL_PRESENT_BUT_BYPASSABLE | NO_KERNEL`. In chat, reply only with the path written and the verdict.
```

---

## Prompt 4 — Canonical Anti-Pattern Sweep

```text
Scan the current repository (working directory) for the six anti-patterns that deep research identified as agent-hostile. For each, report **present / absent**, file paths, and severity (`blocker | high | medium | low`):

1. **Centralized command registry** — a single `main.py` / `cli.py` switchboard that must be edited for every new feature (causes dropped wiring). Evidence: length of the dispatch block, number of `if/elif` or `add_command` calls.
2. **`utils/` or `common/` junk drawer** — a catch-all module with unrelated helpers. Evidence: file list, top-3 most-imported helpers, whether contents are cohesive.
3. **Shared horizontal service layer** — a `services/` directory imported by many features (destroys locality). Evidence: fan-in counts.
4. **Implicit global state / env-var configuration** — modules reading `os.environ` or module-level singletons at import time. Evidence: grep hits outside the config loader.
5. **Manual error handling inside feature code** — `try/except` blocks in handlers that should be delegated to the kernel. Evidence: count per handler file.
6. **Deep command hierarchies (>3 levels)** — e.g. `cli foo bar baz qux`. Evidence: list offenders.

**Output contract:** write the result to `./docs/ax_arch_audit/04-anti-patterns.md` — one table with columns `anti_pattern | present | severity | evidence_paths | notes`. No remediation suggestions. In chat, reply only with the path written and a one-line status.
```

---

## Prompt 5 — Failure-Mode Risk Assessment

```text
The deep research identified four reproducible agentic failure modes. Score the current repository (working directory) on each with evidence, on a scale `low | medium | high`:

1. **Dropped wiring** — new feature code that never gets registered because the central registry is fragile. Look for: manual registration lists, missing tests that assert the command is discoverable.
2. **Dropped cross-cutting** — agents forgetting to add logging/auth/evidence when copying a handler. Look for: kernel bypass, inconsistent concern coverage across handlers (see Prompt 3).
3. **Compounding rework** — hidden coupling through `utils/`, shared mutable state, or implicit contracts that make every change cascade. Look for: import fan-in, circular imports, god-modules >500 LOC.
4. **Zombie deprecation** — old code paths left behind because removal is unsafe. Look for: `# deprecated`, `# TODO remove`, unused exports, dual code paths gated by flags.

For each, cite at least two concrete file:line evidence points.

**Output contract:** write the result to `./docs/ax_arch_audit/05-failure-modes.md` — four sections, each with `score`, `evidence`, and a single-sentence rationale. End with an overall risk rating `GREEN | YELLOW | RED`. In chat, reply only with the path written and the rating.
```

---

## Prompt 6 — Agent-Memory & Repository-as-Record Check

```text
An agent-first repo treats the repository itself as the system of record: ADRs, rules, plans, and learnings live in-tree as versioned Markdown.

Audit the current repository (working directory):

1. Does `AGENTS.md` (or equivalent root entry point) exist? If yes, does it point to the rest of the agent memory? Score `present | stub | missing`.
2. Are there ADRs (`docs/adr/`, `docs/decisions/`, etc.)? Count and list the 5 most recent.
3. Are there agent rules / guardrails files? Count and list.
4. Are plans / specs versioned in-repo, or only in Slack/Jira/Notion? Evidence.
5. Is `README.md` addressed to humans, agents, or both? Quote the first 200 words.

**Output contract:** write the result to `./docs/ax_arch_audit/06-agent-memory.md` — a 5-row table `artifact | status | path | notes`, followed by a 2-sentence verdict on repository-as-record maturity. In chat, reply only with the path written and a one-line status.
```

---

## Prompt 7 — Feature-Addition Touch-Point Simulation

```text
Simulate adding a new feature to the current repository (working directory). Pick a realistic feature based on the repo's domain — ask the user if unsure. Do **not** write the code. Instead, enumerate **every file** that would need to be created or modified, in order:

1. New files (handler, models, tests, docs).
2. Existing files modified (CLI registry, `__init__.py`, config schema, shared types, docstrings, integration test manifests, etc.).
3. Non-obvious touch points (release notes, man pages, MCP manifests, generated docs, CI configs).

Report the **Touch Point Count** and compare to the target (≤ 5 total, with ≤ 1 modification outside the new feature directory).

**Output contract:** write the result to `./docs/ax_arch_audit/07-touch-points.md` — two ordered lists (created, modified) with justifications, a total count, and a one-line verdict: `MEETS_TARGET | EXCEEDS_TARGET_BY_N`. In chat, reply only with the path written and the verdict.
```

---

## Prompt 8 — Consolidated Audit Report

```text
Read the outputs of Prompts 1–7 from `./docs/ax_arch_audit/01-snapshot.md` through `./docs/ax_arch_audit/07-touch-points.md` in the current repository. Produce a single **Brownfield Audit Report** with:

1. **Executive summary** (5 bullets, non-technical).
2. **KPI scorecard:** FLS, mean Lᵢ, Governance Coverage %, MFRET (estimate), Touch Points for typical feature, Command Depth. Mark each `GREEN / YELLOW / RED` vs. targets from the synthesis doc.
3. **Top 3 blockers** to agent-maintainability, each with file evidence and the architectural principle violated.
4. **Migration-order recommendation** — which of the four failure modes to address first, and why, given this repo's specifics. Do **not** prescribe tooling (out of scope).
5. **Open questions for the maintainer** — anything that requires human judgment before migration can proceed.

**Output contract:** write the full report to `./docs/ax_arch_audit/08-report.md` — the five sections above, ≤ 1500 words total, with every claim linked to evidence from `./docs/ax_arch_audit/01-..07-`. In chat, reply only with the path written and the overall RAG rating from the KPI scorecard.
```

---

## Usage notes

- Run Prompts 1–6 in parallel (they share no state). Run Prompt 7 after 1–4 are done. Run Prompt 8 last with all prior outputs attached.
- Prompts 2, 3, and 7 are the highest-signal; if you only run three, run those.
- Prompts intentionally do **not** propose tooling or migration plans — tooling is deferred per the project's scope lock (see `README.md`).
- The KPI targets (FLS ≥ 0.5, Lᵢ ≥ 0.1, Governance Coverage = 100%, MFRET < 5, Touch Points = 1, Command Depth ≤ 3) come from `deep_research/05-synthesis.md` §"The Metrics That Matter".
