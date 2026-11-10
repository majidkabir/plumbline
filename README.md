# plumbline

A Claude Code plugin that takes a new piece of software from raw requirements
to reviewed pull requests, one human-approved deliverable at a time.

Every command does one step, writes one deliverable, opens it as a pull
request and stops. Merging the PR is the approval. The next command refuses to
run until the previous deliverable is merged.

**Status:** Stage 1 (requirements analysis) works. Stages 2 to 8 are designed
in [docs/workflow.md](docs/workflow.md) and not built yet.

## Install

In the project you want to build:

```
/plugin marketplace add majidkabir/plumbline
/plugin install plumbline@plumbline
/plumbline:init
```

`init` adds the marketplace to `.claude/settings.json`, so the rest of the team
gets the plugin when they open the project.

You need git, a POSIX shell (Git Bash on Windows) and, for automatic pull
requests, the GitHub CLI `gh`. Without a remote it works in local mode: merging
the step's branch into `main` is the approval.

## Stage 1: requirements

| Command | Deliverable | You review |
|---|---|---|
| `/plumbline:init` | `docs/standards/` | Stack, constraints and company rules |
| `/plumbline:req-register` | `docs/req/register.md` | Nothing dropped, nothing sharpened |
| `/plumbline:req-quality` | `docs/req/quality-report.md` | Scores and gaps |
| `/plumbline:req-clarify` | `docs/req/questions.md`, `assumptions.md` | You answer and decide |
| `/plumbline:req-resolve` | all four, updated | Your answers applied, new scores |
| `/plumbline:req-baseline` | `docs/req/baseline.md` | Sign-off |
| `/plumbline:status` | | Where you are and what is next |

`req-clarify` and `req-resolve` repeat until no requirement is blocked.

Put the raw requirements in `docs/req/input/` as `.md` or `.txt` before
`req-register`.

## What keeps it honest

These are enforced by a script, not by asking a model to behave:

- **Gates.** A step runs only when its inputs are merged into the default
  branch. A hook blocks the command before it starts.
- **Verbatim sources.** Every stated requirement quotes its source, and the
  quote must exist word for word in the named input file.
- **Write scope.** A step can only change its own files. Anything else fails
  the step.
- **Complete scoring.** Every requirement is scored on six checks, and every
  score below 2 must be covered by a question, an assumption or a deferred item.
- **Staleness.** The quality report records which version of the register it
  scored. Change the register and the report must be redone before you continue.
- **No silent decisions.** The baseline cannot be signed off while a
  requirement scores 0, a blocker question is open or an assumption is pending.

Separate agents do the writing and the judging. The agent that writes the
register does not score it, and a reviewer that sees only the register reports
what a developer would have to guess.

## Company standards

`init` copies defaults into `docs/standards/`. They are yours to edit:

- `stack.md`: stack and architecture constraints. Feasibility is judged against it.
- `requirements-rules.md`: statement rules, vague words, what each score means.
- `gap-checklist.md`: areas requirement documents tend to leave out.
- `nfr-baselines.md`: default targets, proposed as assumptions when sources are silent.

To change the defaults for every new project, fork this repo, edit
`plugins/plumbline/templates/standards/` and point
`templates/settings-snippet.json` at your fork.

## Layout

```
.claude-plugin/marketplace.json
plugins/plumbline/
  skills/      one per command
  agents/      analyst, critic, feasibility checker, fresh eyes, clarifier, acceptance writer
  hooks/       gate hook
  scripts/     plumbline.sh (gates, branches, PRs), lint.awk (format checks)
  templates/   default standards, PR review checklists
```
