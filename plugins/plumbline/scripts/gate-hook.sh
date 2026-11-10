#!/bin/sh
# UserPromptExpansion hook: stop a gated /plumbline:req-* command before it
# expands when its prerequisites are not approved. Exit 2 blocks the command
# and shows stderr to the user. Every other command passes through untouched.

input=$(cat | tr -d '\n')
name=$(printf '%s' "$input" | sed -n 's/.*"command_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
name=${name#plumbline:}

case "$name" in
  req-register|req-quality|req-clarify|req-resolve|req-baseline) ;;
  *) exit 0 ;;
esac

dir=${CLAUDE_PROJECT_DIR:-.}
cd "$dir" 2>/dev/null || exit 0
"$(dirname "$0")/plumbline.sh" check "$name" >/dev/null || exit 2
exit 0
