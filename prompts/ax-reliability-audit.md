# Repo Agent-Reliability Audit

**Purpose**: survey a ~50k-LOC Python repository whose spec-driven feature-implementation success rate by coding agents has been declining, diagnose the causes, and produce a prioritized action list that would plausibly raise that success rate.

**Target repo**: the current working directory. Resolve it with `pwd` at the start of the run and treat that path as the repo root for every subsequent command.

**Wiki context**: you have access to `/Users/jayers/Library/Mobile Documents/com~apple~CloudDocs/NotebookLM/Deep-Research-Reports/wiki/` — 68 ingested deep-research reports. Read the specific reports cited below when a finding depends on their content; don't cite a slug you haven't read.

---

## 1. Prior art: what the wiki says drives agent reliability

These are the strongest priors from the corpus. Test each against the repo; discard the ones that don't fit.

### A. Architecture shape

- **Layered / "lasagna" is hostile to agents.** Bogard's VSA finding: a feature in layered architecture touches ~27 files across horizontal tiers; in Vertical Slice Architecture, ~5. Agent context-window efficiency, reasoning, and failure rate all degrade with touchpoints-per-feature. ([[reports/jimmy-bogard-vertical-slice-architecture]], [[reports/ddd-vs-vsa]])
- **Bounded Contexts ≈ context-window hygiene.** Undifferentiated codebases force agents to read too much to act safely. DDD subdomain lines are now load-bearing for agent locality. ([[reports/ddd-code-base-decomp]], [[reports/ddd-dict-for-agents]])
- **Skeleton/Tissue governance.** Abstract bases/interfaces are human-defined and agent-untouchable; concrete implementations are the tissue the agent fills in. Without this boundary, agents wander into architectural refactors during feature work. ([[reports/jimmy-bogard-vertical-slice-architecture]])
- **Rule of Three.** Premature abstraction is worse than duplication — agents reason poorly about clever generic code. ([[reports/ddd-vs-vsa]])

### B. Ubiquitous Language

- **Terminology drift is a silent reliability killer.** If the same concept has three names in the code, the agent will synthesize three different implementations. ([[reports/ddd-dict-for-agents]])
- **A glossary / UL document is cheap insurance.** Without one, every agent session re-derives the domain model from code.
- **Schema validation at boundaries (Pydantic, JSON Schema) acts as a semantic firewall** against drift in agent I/O.

### C. Agent-context scaffolding

- **Three-layer instruction hierarchy** (global → project → nested/local). Missing `CLAUDE.md`/`AGENTS.md` = no constitution. Missing nested files = agent reads everything every time. ([[reports/claude-projects]], [[reports/claudemd-best-practices]])
- **Progressive disclosure beats monolithic instructions.** ETH Zurich "redundancy tax": monolithic `CLAUDE.md` costs −3% task-success and +20% tokens vs. layered router + nested skills. ([[reports/progressive-disclosure-architectures]])
- **Trigger-action rules > generic advice.** "When modifying X, always Y" ≫ "follow best practices." ([[reports/claudemd-best-practices]])
- **Explicit negatives > positives.** "Do NOT do X" is more reliable than "prefer Y." ([[reports/claudemd-best-practices]])
- **Information-Dense Keywords** (`ultrathink`, `proactively`, `mirror`, locational anchors) are worth paragraphs of hedging. ([[reports/information-dense-keywords]])

### D. Spec-driven implementation

- **EARS acceptance criteria + BDD scenarios make failure detectable.** Without them, "success" is "looks right to the reviewer" — and reviewer vigilance decays over time (the AI slot-machine effect). ([[reports/spec-driven-dev-tools]], [[reports/ai-slot-machine]])
- **Spec-as-artifact** (versioned, testable) is the lever. Kiro's EARS + PBT + Agent Hooks or Spec-Kit's `constitution.md` + slash-command pipeline are the reference patterns.
- **Plan-then-Execute raises success ~92% vs. ~85% Direct-Execute.** ([[reports/architectures-and-observability-for-agentic-ai-systems]])

### E. Decision memory

- **Machine-parseable ADRs** (JSON-LD + schema + ArchUnit-style tests + MCP) act as build-time guardrails against AI-induced drift. Without ADRs, agents re-litigate decided questions and silently diverge from past decisions. ([[reports/machine-parseable-architecture-decision-records-as-persistent-memory-for-ai-codi]])
- **`AGENTS.md` / `.sdlc/`** encode conventions that would otherwise have to be re-derived each session. ([[reports/agentic-repos]])

### F. Verification

- **Slice tests hitting real dependencies beat mocked unit tests.** Mocks pass while the slice is broken. ([[reports/ddd-vs-vsa]])
- **Multi-subagent review (Spec + Quality + Visual)** catches what a single pass misses. ([[reports/superpower-best-prac]])
- **Fitness functions (Bronze-Silver-Gold)** give a continuous verdict on architectural decay. ([[reports/systems-architecture]])

### G. The reality floor

- **SWE-bench Pro ≈ 59% vs. Verified ≈ 80.9%.** Multi-file, multi-step tasks are where agents fail. A 50k-LOC repo is firmly in Pro territory for any non-trivial feature. ([[reports/compute-advantage]])
- **Understanding debt + vigilance decrement.** Under vibe coding, felt productivity is +20% while measured is −19%. "The agent got worse" often means "the reviewer got laxer over 50k LOC of accumulated surface area." ([[reports/ai-slot-machine]])

---

## 2. Survey tasks

Execute in order. Use `rg`, `ast-grep`, `pydeps`, `import-linter`, `git log`. Every finding needs a `file:line` citation or a concrete metric — no vibes.

### Task 1 — Shape & size
- Total LOC by module; top-20 largest files.
- Import-graph depth and cycle count.
- File-count per feature: sample the last 10 merged PRs, count touched files, report mean/median/max.
- Directory layout: layered (`models/`, `services/`, `views/`), VSA (feature-folder), modular-monolith (package-per-domain), or mixed?
- Count of abstract bases / Protocols / ABCs; note which are human-authored vs. apparently accreted.

### Task 2 — Ubiquitous Language audit
- `GLOSSARY.md` / `docs/domain.md` present? In sync with code?
- Pick the top 10 domain nouns from README/docs. Search the codebase for each; count synonyms and inconsistent casings. Report any noun with ≥2 spellings.
- Pydantic / JSON Schema used at I/O boundaries, or do raw `dict`/JSON payloads flow internally?

### Task 3 — Agent-context scaffolding audit
- Presence & LOC of: `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.sdlc/`, `.github/agents/`, `SKILL.md`, `.cursorrules`, nested `CLAUDE.md` per module.
- Quality grade: generic platitudes vs. trigger-action rules; presence of explicit negatives; IDK usage.
- Hierarchy present (global → project → nested)?
- Progressive disclosure: split by domain, or one monolithic file?

### Task 4 — Spec-driven gates
- `specs/`, `.kiro/`, `memory/constitution.md`, `*.feature`, EARS-formatted ACs?
- Sample 5 recent feature PRs: was there a spec artifact at merge? Did tests encode the spec, or merely mirror the implementation?

### Task 5 — ADRs & decision memory
- `docs/adr/` or `decisions/` present? Prose or machine-parseable?
- Any architectural-fitness layer (`import-linter`, `contracts`, custom ArchUnit-like)?

### Task 6 — Tests
- Test:prod LOC ratio.
- Fraction of tests using mocks/patches vs. real-dependency slice tests.
- Coverage per domain (if configured).
- Integration tests per feature slice, or only unit tests per class?

### Task 7 — Recent-failure forensics
- Pull the last 10–20 merged PRs. For each: authored-by-agent? Reverted or follow-up-fixed? If yes, classify the failure mode: missing context / wrong abstraction / UL drift / silent mock / architectural violation / other.
- Produce a Pareto histogram of failure modes.

### Task 8 — Lasagna index
- For each recent feature PR: files touched, layers crossed (each of models+services+views counts as one), abstract-base modifications.
- Report touchpoints-per-feature. Mean >10 suggests the repo's shape itself is depressing the agent's success rate.

### Task 9 — Boundary integrity
- Anti-Corruption-Layer pattern at external-service boundaries?
- External schemas validated at ingress, or raw data propagating inward?

---

## 3. Diagnostic synthesis

Combine findings into a causal model. For each observed failure mode, map it to the principle(s) it violates:

| Observed symptom | Evidence (file:line / metric) | Violated principle | Wiki ref |
| --- | --- | --- | --- |

Then produce a **root-cause ranking** — five top causes with high confidence, not fifteen weakly-supported ones. Cite reasoning.

---

## 4. Deliverable

Write `./docs/ax_audit/audit-<YYYY-MM-DD>.md` (create the directory if missing). If a prior audit for the same date already exists, append a `-<N>` suffix rather than overwriting. Sections:

1. **TL;DR** — 3-5 sentences: single biggest reliability lever + top two supporting levers.
2. **Findings** — per-task short-form results with citations.
3. **Root-cause ranking** — top 5, each with evidence + wiki grounding.
4. **Recommendations** — ordered by (expected reliability lift) ÷ (effort). For each:
   - One-line description
   - Why it helps (wiki citation)
   - Estimated effort (hrs / days / weeks)
   - Expected lift (low / medium / high / game-changing)
   - First concrete step (a single PR or commit that moves the needle)
5. **Explicitly-rejected ideas** — things the wiki suggests but that don't apply here; state why.
6. **Open questions for the repo owner** — what static analysis couldn't determine.

---

## 5. Operating rules

- **Ultrathink** before writing the deliverable. Don't start from a template.
- **Proactively** read the wiki pages cited above. Don't just repeat a slug.
- **Evidence before assertion.** If you can't cite `file:line` or a metric, mark the claim "hypothesis, unverified."
- **No ground-up rewrites.** The owner has 50k LOC of sunk work. Recommendations must be incremental and reversible — ratchets, not revolutions.
- **Do NOT recommend every principle in the wiki.** The redundancy-tax finding applies to your output too: five targeted recommendations beat twenty generic ones.
- **Prefer conventions over new dependencies.** `CLAUDE.md` hierarchy, `import-linter` rules, ADRs, glossary — these are cheap ratchets. Introducing a new framework is a last resort.
- **Watch for the slot-machine pattern in your own analysis.** If a hypothesis "feels right" but you have no file-level evidence, mark it unverified.

---

Begin with Task 1.
