# Agent Experience Reliability Audit

A prompt for surveying a Python codebase whose coding-agent feature-implementation success rate has been declining, then producing prioritized recommendations to raise that rate back up.

## When to use this

- Repo size roughly 10k–200k LOC (sweet spot ~50k).
- Recent agent-authored PRs have required more rework, more reverts, or more human follow-up than they used to.
- You want a diagnosis grounded in architectural evidence, not vibes.

## How to run it

1. `cd` to the **root of the target repository**. The prompt uses the current working directory as the repo — no path-substitution needed.
2. Start a **fresh** coding-agent session in that directory (Claude Code, Cursor, Copilot CLI, etc.). A clean context matters: the audit reads the codebase from scratch.
3. Paste the prompt block below as the first message, verbatim.
4. Approve shell access when the agent asks — it will run `rg`, `git log`, and may try `pydeps` or `import-linter` if installed.
5. Wait. Expect 15–45 minutes depending on repo size and how deeply the agent traces failure forensics.

## What you'll get

A single file at `./docs/ax_audit/audit-<YYYY-MM-DD>.md` containing:

- **TL;DR** — the single biggest reliability lever plus the top two supporting ones.
- **Findings** — per-task short-form results, each with `file:line` citations.
- **Root-cause ranking** — top 5 with evidence.
- **Recommendations** — ordered by (expected lift) ÷ (effort), each with a first concrete step.
- **Explicitly-rejected ideas** — what didn't apply and why.
- **Open questions** — things only you can answer.

If a same-day audit already exists, the agent will append a `-<N>` suffix rather than overwrite.

## Tips

- Run it **before** planning your next major feature. Use the output to decide what to ratchet first.
- Re-run quarterly. Reliability drift is gradual; the same audit 90 days later surfaces new regressions.
- If recommendations feel generic, re-run with the instruction "use only evidence from the last 30 merged PRs" to force specificity.

---

## The prompt

Copy everything between the fences, verbatim, into a fresh agent session at your repo root.

````text
You are auditing this repository — the current working directory — to diagnose why spec-driven feature implementation by coding agents has been getting less reliable over time, and to produce a prioritized action list that would plausibly raise the success rate of future feature work.

Resolve the repo root with `pwd` at the start. That path is the only input; everything else is derived from the code, git history, and instruction files present in-tree.

## Priors: what drives agent reliability in Python codebases

Test each of these against the repo. Discard the ones that don't fit. Do not apply every principle — the goal is targeted diagnosis, not a lecture.

### A. Architecture shape
- Layered / "lasagna" architectures are hostile to agents. A feature in layered code typically touches ~27 files across horizontal tiers; in Vertical Slice Architecture (feature-folder), ~5. Agent context-window efficiency, reasoning accuracy, and failure rate all degrade as touchpoints-per-feature rise.
- Bounded Contexts are context-window hygiene. An undifferentiated codebase forces the agent to read too much to act safely.
- Skeleton/Tissue governance: abstract bases and interfaces are human-authored and agent-untouchable; concrete implementations are the tissue the agent fills in. Without this boundary, agents wander into architectural refactors during ordinary feature work.
- Rule of Three: premature abstraction is worse than duplication. Agents reason poorly about clever generic code.

### B. Ubiquitous Language
- Terminology drift is a silent reliability killer. If the same concept has three different names in the code, the agent will synthesize three different implementations.
- A glossary or domain document is cheap insurance. Without one, every session re-derives the domain model from code.
- Pydantic / JSON Schema validation at I/O boundaries acts as a semantic firewall against drift in agent-produced I/O.

### C. Agent-context scaffolding
- Three-layer instruction hierarchy (global → project → nested/local). Missing `CLAUDE.md` / `AGENTS.md` means no constitution. Missing nested files means the agent reads everything every time.
- Progressive disclosure beats monolithic instructions. Research shows monolithic instruction files cost roughly −3% task-success and +20% tokens vs. layered router + nested domain-specific skills.
- Trigger-action rules ("When modifying X, always Y") beat generic advice ("follow best practices").
- Explicit negatives ("do NOT do X") are more reliable than positive preferences.
- Information-dense keywords (`ultrathink`, `proactively`, `mirror`, explicit anchors) are worth paragraphs of hedging.

### D. Spec-driven implementation
- EARS acceptance criteria and BDD scenarios make failure *detectable*. Without them, "success" is "looks right to the reviewer" — and reviewer vigilance decays with repeated agent PRs.
- Spec-as-artifact (versioned, testable) is the lever — the spec itself is the object of review, not the implementation.
- Plan-then-Execute raises success rates meaningfully over Direct-Execute. Absence of a planning step per feature is a failure mode.

### E. Decision memory
- Machine-parseable ADRs (JSON-LD + architectural-fitness tests) act as build-time guardrails against AI-induced drift. Without ADRs, agents re-litigate decided questions and silently diverge from past choices.
- `AGENTS.md` / `.sdlc/` encode conventions that would otherwise be re-derived each session.

### F. Verification
- Slice tests hitting real dependencies beat mocked unit tests. Mocks pass while the slice is broken.
- Multi-stage review (spec check + quality check + behavior check) catches what a single pass misses.
- Architectural fitness functions give a continuous verdict on decay.

### G. Reality floor
- Multi-file, multi-step tasks are measurably harder than single-file ones. A 50k-LOC repo sits firmly in the "multi-file" regime for any non-trivial feature.
- "The agent got worse" often means "the reviewer got laxer over accumulated surface area." Felt productivity under uncritical AI-assisted work can be +20% while measured productivity is −19%. Look for this pattern in the recent-PR forensics.

---

## Survey tasks

Execute in order. Every finding needs a `file:line` citation or a concrete metric — no vibes.

1. **Shape & size.** Total LOC by module; top-20 largest files. Import-graph depth and cycle count (use `pydeps` / `import-linter` if installed, else read imports manually). For the last 10 merged PRs, count touched files — report mean/median/max. Classify directory layout: layered, VSA, modular-monolith, mixed. Count abstract bases, Protocols, ABCs; note which look human-authored vs. accreted.

2. **Ubiquitous Language audit.** Is there a `GLOSSARY.md` / `docs/domain.md`? In sync with code? Pick the top 10 domain nouns from README/docs and grep for each — count synonyms and inconsistent casings. Report any noun with ≥2 spellings. Check whether Pydantic / JSON Schema is used at I/O boundaries or raw dicts flow internally.

3. **Agent-context scaffolding audit.** Presence and LOC of: `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.sdlc/`, `.github/agents/`, `SKILL.md`, `.cursorrules`, nested `CLAUDE.md` per module. Grade quality: generic platitudes vs. trigger-action rules; presence of explicit negatives; use of information-dense keywords. Is the instruction hierarchy layered or monolithic?

4. **Spec-driven gates.** Look for spec and plan artifacts in any of: `project-planning/`, `docs/superpowers/specs/`, `docs/superpowers/plans/`, `specs/`, `.kiro/`, `memory/constitution.md`, `*.feature`, plus EARS-formatted acceptance criteria anywhere in-tree. (Superpowers-plugin convention: design docs under `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, implementation plans under `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`.) Sample 5 recent feature PRs: was there a spec or plan artifact at merge time? Did the tests encode the spec, or merely mirror the implementation?

5. **ADRs & decision memory.** `docs/adr/` or `decisions/` present? Prose or machine-parseable? Any architectural-fitness layer (`import-linter`, contract tests, custom checks)?

6. **Tests.** Test-to-prod LOC ratio. Fraction of tests using mocks/patches vs. real-dependency slice tests. Coverage per domain if configured. Integration tests per feature slice, or only unit tests per class?

7. **Recent-failure forensics.** Last 10–20 merged PRs. For each: authored-by-agent? Reverted or follow-up-fixed? If yes, classify the failure mode — missing context, wrong abstraction, UL drift, silent mock, architectural violation, other. Produce a Pareto histogram.

8. **Lasagna index.** For each recent feature PR: files touched, layers crossed (each of `models/` + `services/` + `views/` counts as one), abstract-base modifications. Report touchpoints-per-feature. Mean >10 suggests the repo's shape itself is depressing agent success.

9. **Boundary integrity.** Anti-corruption-layer pattern at external-service boundaries? External schemas validated at ingress, or raw data propagating inward?

---

## Diagnostic synthesis

Combine findings into a causal model. Map each observed failure mode to the principle(s) it violates:

| Observed symptom | Evidence (file:line / metric) | Violated principle |

Then produce a **root-cause ranking** — five top causes with high confidence, not fifteen weakly-supported ones.

---

## Deliverable

Write `./docs/ax_audit/audit-<YYYY-MM-DD>.md` (create the directory if missing; if the same-day file already exists, append `-<N>`). Sections:

1. **TL;DR** — 3-5 sentences: the single biggest reliability lever + the top two supporting levers.
2. **Findings** — per-task short-form results with citations.
3. **Root-cause ranking** — top 5, each with evidence and which principle it violates.
4. **Recommendations** — ordered by (expected reliability lift) ÷ (effort). For each:
   - One-line description
   - Why it helps (grounded in the priors above)
   - Estimated effort (hrs / days / weeks)
   - Expected lift (low / medium / high / game-changing)
   - First concrete step — a single PR or commit that moves the needle
5. **Explicitly-rejected ideas** — principles from the priors above that do NOT apply here; say why.
6. **Open questions for the repo owner** — things static analysis could not determine.

---

## Operating rules

- **Ultrathink** before writing the deliverable. Don't start from a template.
- **Evidence before assertion.** If you cannot cite `file:line` or a metric, mark the claim "hypothesis, unverified."
- **No ground-up rewrites.** The owner has sunk work; recommendations must be incremental and reversible — ratchets, not revolutions.
- **Do NOT recommend every principle above.** Five targeted recommendations beat twenty generic ones. The redundancy-tax finding applies to your output too.
- **Prefer conventions over new dependencies.** `CLAUDE.md` hierarchy, `import-linter` rules, ADRs, glossary files — cheap ratchets. Introducing a new framework is a last resort.
- **Watch for the slot-machine pattern in your own analysis.** If a hypothesis "feels right" but you have no file-level evidence, mark it unverified and keep going.

Begin with Task 1.
````
