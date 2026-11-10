---
name: init
description: Set up a project for the plumbline workflow - company standards, the requirements input folder and the team's plugin settings. Run once per project.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plumbline.sh *)
---

Set this project up for plumbline. Run the commands exactly as written; the
script creates the branch, checks the files and opens the pull request.

1. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh begin init`. If it fails,
   show the user the message and stop.
2. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh init`. It copies the default
   standards into `docs/standards/` and never overwrites an existing file.
3. Merge the keys from `${CLAUDE_PLUGIN_ROOT}/templates/settings-snippet.json`
   into `.claude/settings.json` (create the file if needed). Keep every key that
   is already there. This makes the plugin load for everyone on the team.
4. Fill in `docs/standards/stack.md` with what is certain:
   - anything the user gave here: $ARGUMENTS
   - anything the repository proves (build files, Dockerfiles, CI config).
   Leave a line empty when you are not sure. Never guess a stack. Delete the
   first line (the `plumbline:unfilled` marker) only if no line under "Stack"
   and "Architecture constraints" is empty.
5. Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh finish init "plumbline: project setup"`.

Then tell the user, in a few lines:
- the pull request link (or the branch, if no PR was opened)
- which lines of `stack.md` are still empty and need them
- that the other files in `docs/standards/` hold example company rules they
  should adjust in the same PR
- next: merge the PR, put the requirement sources in `docs/req/input/` as
  `.md` or `.txt`, then run `/plumbline:req-register`.
