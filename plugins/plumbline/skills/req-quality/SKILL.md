---
name: req-quality
description: Stage 1.2 of plumbline - score every requirement in the approved register for clarity, completeness, consistency, testability, feasibility and scope, list the gaps, and open the quality report as a pull request.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plumbline.sh *)
---

Gate: !`"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh check req-quality`

You are the coordinator for this step. You run the script and launch the
subagents; you do not score requirements or edit the report yourself. Three
reviewers work separately so that none of them grades its own work.

1. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh begin req-quality`. If it
   fails, show the user the message and stop.
2. Launch these two subagents at the same time:
   - `plumbline:fresh-eyes` with the task: "Read only docs/req/register.md and
     report what you would have to guess, following your instructions."
   - `plumbline:feasibility-checker` with the task: "Score the feasibility of
     every active requirement in docs/req/register.md, following your instructions."
3. Launch `plumbline:requirements-critic` with the task: "Write
   docs/req/quality-report.md, following your instructions." Paste both replies
   from step 2 into the task in full, under the headings "Implementer guesses"
   and "Feasibility scores". Do not summarise or filter them. Add this only if
   it is not empty, as extra guidance from the user: $ARGUMENTS
4. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh lint req-quality`. If it
   reports errors, send the error lines unchanged to a `plumbline:requirements-critic`
   subagent and ask it to fix exactly those. Repeat at most three times. If
   errors remain, show them to the user and stop without finishing.
5. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh finish req-quality "Requirements quality report"`.

Then tell the user, in a few lines:
- the pull request link
- how many requirements are blocked, need clarification and are ready, and how
  many gaps were found (take the numbers from the script's summary line)
- the two or three most serious findings, one line each
- next: review the scores, change any they disagree with, merge the PR. Then
  `/plumbline:req-clarify`, or `/plumbline:req-baseline` if nothing scored
  below 2 and there are no gaps.
