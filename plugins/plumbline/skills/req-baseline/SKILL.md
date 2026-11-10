---
name: req-baseline
description: Stage 1.4 of plumbline - write the requirements baseline (acceptance criteria, measurable NFR targets, glossary, out-of-scope list) from the approved register and decisions, and open it as the sign-off pull request.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plumbline.sh *)
---

Gate: !`"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh check req-baseline`

You are the coordinator for this step. You run the script and launch the
subagents; you do not write acceptance criteria yourself.

1. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh begin req-baseline`. If it
   fails, show the user the message and stop.
2. Launch `plumbline:acceptance-writer` with the task: "Write
   docs/req/baseline.md, following your instructions." Add this only if it is
   not empty, as extra guidance from the user: $ARGUMENTS
3. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh lint req-baseline`. If it
   reports errors, send the error lines unchanged to a `plumbline:acceptance-writer`
   subagent and ask it to fix exactly those. Repeat at most three times. If
   errors remain, show them to the user and stop without finishing.
4. Launch `plumbline:fresh-eyes` with the task: "Read only docs/req/baseline.md.
   For each requirement, report what you would have to guess to write an
   automated test from its acceptance criteria or target."
5. If it reported guesses, launch `plumbline:acceptance-writer` once more with
   the task: "A tester reading only docs/req/baseline.md would have to guess the
   points below. Fix each one that the approved register, answers and
   assumptions let you fix. Reply with the ones you could not fix." Paste the
   guesses in full. Then run the lint command from step 3 again.
6. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh finish req-baseline "Requirements baseline"`.

Then tell the user, in a few lines:
- the pull request link
- how many requirements are covered
- every open point the writer could not resolve, one line each. These are real
  holes: the user either accepts them or runs another clarification round.
- that merging this PR signs off the requirements, and that later changes go
  through a new clarification round and never by editing the baseline alone.
