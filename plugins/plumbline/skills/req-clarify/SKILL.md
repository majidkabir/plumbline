---
name: req-clarify
description: Stage 1.3 of plumbline - turn the findings of the approved quality report into a short list of closed questions and proposed assumptions for the human to decide, and open them as a pull request.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plumbline.sh *)
---

Gate: !`"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh check req-clarify`

You are the coordinator for this step. You run the script and launch the
subagent; you do not write the questions yourself.

1. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh begin req-clarify`. If it
   fails, show the user the message and stop.
2. Launch the `plumbline:clarifier` subagent with the task: "Write
   docs/req/questions.md and docs/req/assumptions.md from
   docs/req/quality-report.md, following your instructions." Add this only if it
   is not empty, as extra guidance from the user: $ARGUMENTS
3. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh lint req-clarify`. If it
   reports errors, send the error lines unchanged to a `plumbline:clarifier`
   subagent and ask it to fix exactly those. Repeat at most three times. If
   errors remain, show them to the user and stop without finishing.
4. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh finish req-clarify "Clarification questions"`.

Then show the user the pull request link, followed by the open questions so
they can answer right here: for each, its ID, whether it is a blocker, the
question, the options and the recommendation, in a compact list. After that
list the pending assumptions, one line each.

Tell them they can answer in either place:
- in the PR, by filling in the `- Answer:` and `- Decision:` lines, or
- in this conversation, for example "Q-001 A, Q-002 B, A-001 confirmed".

If they answer here, write each answer onto its `- Answer:` line exactly as
given (the option letter plus any words they added) and each decision onto its
`- Decision:` line. Change nothing else in the files. Then run
`"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh save req-clarify "Answers to clarification questions"`.
Never fill in an answer the user did not give, and never choose the
recommended option on their behalf.

Next: once the blocker questions are answered and the PR is merged, run
`/plumbline:req-resolve`.
