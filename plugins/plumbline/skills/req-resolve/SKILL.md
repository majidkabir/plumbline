---
name: req-resolve
description: Stage 1.3 of plumbline, closing a round - apply the human's answers and assumption decisions to the register, re-score the requirements, raise any follow-up questions, and open the result as one pull request.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plumbline.sh *)
---

Gate: !`"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh check req-resolve`

You are the coordinator for this step. You run the script and launch the
subagents in order; you do not edit the deliverables yourself. Each subagent
reads the files the previous one wrote.

1. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh begin req-resolve`. If it
   fails, show the user the message and stop.
2. Launch `plumbline:requirements-analyst` with the task: "Update
   docs/req/register.md after a clarification round, following the section of
   your instructions on updating. Apply every open question in
   docs/req/questions.md that has an answer, and every assumption in
   docs/req/assumptions.md whose decision is confirmed and that no requirement
   cites yet. Each answered question must end up cited by at least one
   requirement. Do not touch anything else."
3. Launch these two subagents at the same time:
   - `plumbline:fresh-eyes` with the task: "Read only docs/req/register.md and
     report what you would have to guess, following your instructions."
   - `plumbline:feasibility-checker` with the task: "Score the feasibility of
     every active requirement in docs/req/register.md, following your instructions."
4. Launch `plumbline:requirements-critic` with the task: "Rewrite
   docs/req/quality-report.md for the updated register, following your
   instructions." Paste both replies from step 3 in full, under the headings
   "Implementer guesses" and "Feasibility scores".
5. Launch `plumbline:clarifier` with the task: "Update docs/req/questions.md
   and docs/req/assumptions.md after a round, following the section of your
   instructions on being run again. Set `State: resolved` on every open question
   that has an answer. Then cover every finding in docs/req/quality-report.md
   that is still below 2 and every gap."
6. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh lint req-resolve`. Send any
   error lines unchanged to the subagent that owns the file named in the error
   (register: analyst; quality report: critic; questions, assumptions and
   coverage: clarifier) and ask it to fix exactly those. Repeat at most three
   times. If errors remain, show them to the user and stop without finishing.
7. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh finish req-resolve "Clarification round: answers applied"`.

Then tell the user, in a few lines:
- the pull request link
- which requirements changed, were added or were dropped, by ID
- the new counts from the script's summary lines: blocked, need clarification,
  ready, open questions, pending assumptions
- next, depending on those counts:
  - nothing blocked, no open blocker question, no pending assumption: merge the
    PR, then run `/plumbline:req-baseline`
  - otherwise: answer the new questions (in the PR or here, as in
    `/plumbline:req-clarify`), merge, and run `/plumbline:req-resolve` again.

If the user answers new questions in this conversation, write the answers onto
the `- Answer:` and `- Decision:` lines exactly as given, change nothing else,
and run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh save req-resolve "Answers to clarification questions"`.
