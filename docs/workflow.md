# The workflow

The full design. Stage 1 is implemented; the rest is the plan.

Rules that hold for every stage:

- One step, one deliverable, one human review. Anything that can be split into
  a smaller step to do or to review is split.
- Each step reads only approved files, never the conversation.
- Traceability runs end to end: requirement, feature, component, task, test, PR.
- No local patches. A problem found later is raised against the deliverable
  that owns it, which is then approved again.
- Company standards live in `docs/standards/` and every agent reads them.

## Stages

0. **Standards pack.** Stack, conventions, NFR defaults, templates.
1. **Requirements analysis.** The main gate.
   1. Register: atomic statements with IDs and verbatim sources.
   2. Quality report: six scores per requirement, gap scan, fresh-context pass.
   3. Clarification: closed questions and assumptions, in rounds, until nothing is blocked.
   4. Baseline: acceptance criteria, measurable NFRs, glossary, out of scope. Sign-off.
2. **Feature list.** Features traced to requirement IDs.
3. **Architecture.**
   1. System: context, modules and boundaries, integrations, decision records.
   2. Database: entities, ownership per module, schema, migration approach.
   3. API: contracts first (OpenAPI, AsyncAPI).
   4. Quality: test strategy, observability, security, a check for each NFR.
4. **Planning.** Feature dependency graph, then phases that are each a shippable slice.
5. **Component design.** One short document per component, reviewed separately.
6. **UX and UI.** User flows, screens and wireframes, then a clickable prototype approved before any code.
7. **Tasks.** One slice per feature: a backend task and a frontend task sharing the same API contract and acceptance criteria. Each task lists what it depends on and which files it owns.
8. **Build loop, per task.** Tests, code, reviews by aspect, PR with a risk score. Minor PRs merge themselves; major ones wait for a person.

## Parallel work

Tasks whose dependencies are merged form a wave and run together, each in its
own git worktree. Two tasks that own overlapping files never share a wave.
Shared files (migrations, contracts, build files) are changed by small
foundation tasks that run first, one at a time. Backend and frontend build
against the approved API contract, the frontend against a mock generated from
it. Merging is serial: rebase, full test run, merge.

## Approval

Deliverables: merging the pull request is the approval.

Code: a risk score built mostly from fixed rules (paths touched, size, new
dependencies, coverage change) decides. Changes to migrations, auth, CI, public
APIs and the risk policy itself are always major.
