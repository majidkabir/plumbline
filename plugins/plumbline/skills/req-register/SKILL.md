---
name: req-register
description: Stage 1.1 of plumbline - turn the raw requirement sources in docs/req/input/ into an atomic, traceable requirements register and open it as a pull request for review.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plumbline.sh *)
---

Gate: !`"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh check req-register`

You are the coordinator for this step. You run the script and launch the
subagent; you do not write or edit the register yourself. The subagent works
from the files alone so that nothing from this conversation leaks into it.

1. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh begin req-register`. If it
   fails, show the user the message and stop.
2. Launch the `plumbline:requirements-analyst` subagent with this task:
   "Write docs/req/register.md from the sources in docs/req/input/, following
   your instructions." Add this only if it is not empty, as extra guidance from
   the user: $ARGUMENTS
3. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh lint req-register`. If it
   reports errors, send the error lines unchanged to a `plumbline:requirements-analyst`
   subagent and ask it to fix exactly those. Repeat at most three times. If
   errors remain, show them to the user and stop without finishing.
4. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh finish req-register "Requirements register"`.

Then tell the user, in a few lines:
- the pull request link
- how many requirements there are, and how many are derived (those need a
  conscious yes or no)
- what to check: nothing dropped, nothing sharpened, one behaviour per statement
- next: merge the PR to approve it, then run `/plumbline:req-quality`.

Vague requirements in the register are expected. Do not comment on their
quality; the next step does that.
