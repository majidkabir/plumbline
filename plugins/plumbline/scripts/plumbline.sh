#!/bin/sh
# plumbline — deterministic backbone of the workflow.
# Gates, branch handling, format checks and PR creation live here so they
# never depend on a model following instructions.
#
# usage: plumbline.sh <check|begin|lint|save|finish|status|init> [step] [title]
#
# "Approved" means: the deliverable is merged into the default branch.
# POSIX sh + awk + git only. gh is optional (used to open the PR).

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PLUGIN_ROOT=$(dirname "$SCRIPT_DIR")
LINT="$SCRIPT_DIR/lint.awk"

REQ=docs/req
STD=docs/standards
F_REGISTER=$REQ/register.md
F_QUALITY=$REQ/quality-report.md
F_QUESTIONS=$REQ/questions.md
F_ASSUME=$REQ/assumptions.md
F_BASELINE=$REQ/baseline.md
F_STACK=$STD/stack.md
UNFILLED='plumbline:unfilled'

die() { printf 'plumbline: %s\n' "$*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }

root() {
  r=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
  cd "$r" || die "cannot enter $r"
}

has_remote() { git remote get-url origin >/dev/null 2>&1; }

# The ref that defines "approved". Remote default branch when there is a
# remote, otherwise the local main/master (local mode).
base_ref() {
  if has_remote; then
    b=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
    if [ -n "$b" ]; then say "$b"; return; fi
    for c in origin/main origin/master; do
      if git rev-parse -q --verify "$c" >/dev/null 2>&1; then say "$c"; return; fi
    done
  fi
  for c in main master; do
    if git rev-parse -q --verify "$c" >/dev/null 2>&1; then say "$c"; return; fi
  done
  die "no default branch found (expected main or master with at least one commit)"
}

refresh() {
  if has_remote; then git fetch -q origin 2>/dev/null || true; fi
}

approved() { git cat-file -e "$BASE:$1" 2>/dev/null; }

approved_blob() { git rev-parse -q --verify "$BASE:$1" 2>/dev/null; }

stamp_of() { # value of based_on_register in a file's front matter
  awk '/^based_on_register:/ { print $2; exit }' "$1" 2>/dev/null
}

input_files() { # requirement sources: text files only
  find "$REQ/input" -type f \( -name '*.md' -o -name '*.txt' \) ! -name 'README.md' 2>/dev/null | sort
}

# ---------------------------------------------------------------- steps

known_step() {
  case "$1" in
    init|req-register|req-quality|req-clarify|req-resolve|req-baseline) return 0 ;;
  esac
  return 1
}

# Paths a step is allowed to change. Anything else fails `finish`.
allowed_paths() {
  case "$1" in
    init)         say "$STD/ $REQ/input/ .claude/settings.json" ;;
    req-register) say "$F_REGISTER $REQ/input/" ;;
    req-quality)  say "$F_QUALITY" ;;
    req-clarify)  say "$F_QUESTIONS $F_ASSUME" ;;
    req-resolve)  say "$F_REGISTER $F_QUALITY $F_QUESTIONS $F_ASSUME" ;;
    req-baseline) say "$F_BASELINE" ;;
  esac
}

is_allowed() { # is_allowed <step> <path>
  for a in $(allowed_paths "$1"); do
    case "$a" in
      */) case "$2" in "$a"*) return 0 ;; esac ;;
      *)  [ "$2" = "$a" ] && return 0 ;;
    esac
  done
  return 1
}

changed_paths() { # tracked changes + untracked files, one path per line
  { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard; } | sort -u
}

outside_changes() { # changed paths the step may not touch
  changed_paths | while IFS= read -r p; do
    [ -n "$p" ] || continue
    is_allowed "$1" "$p" || say "$p"
  done
}

need_approved() { # need_approved <path> <producing command>
  approved "$1" || FAIL="${FAIL}
  - $1 is not approved yet (not merged into ${BASE}). Run /plumbline:$2, review the PR and merge it."
}

need_fresh_report() {
  approved "$F_QUALITY" || return 0
  want=$(approved_blob "$F_REGISTER")
  got=$(git show "$BASE:$F_QUALITY" 2>/dev/null | awk '/^based_on_register:/ { print $2; exit }')
  [ "$want" = "$got" ] || FAIL="${FAIL}
  - $F_QUALITY is stale: the register changed after it was scored. Run /plumbline:req-quality again."
}

# Prerequisites per step. Collects every failure, then reports all of them.
gate() {
  FAIL=""
  case "$1" in
    init) : ;;
    req-register)
      need_approved "$F_STACK" init
      [ -n "$(input_files)" ] || FAIL="${FAIL}
  - no requirement sources found. Put .md or .txt files in $REQ/input/ (convert PDFs or Word files to text first)."
      ;;
    req-quality)
      need_approved "$F_REGISTER" req-register
      if [ -f "$F_STACK" ] && grep -q "$UNFILLED" "$F_STACK"; then
        FAIL="${FAIL}
  - $F_STACK is still the empty template. Fill it in (and delete the '$UNFILLED' marker): feasibility cannot be judged without the stack."
      fi
      ;;
    req-clarify)
      need_approved "$F_REGISTER" req-register
      need_approved "$F_QUALITY" req-quality
      need_fresh_report
      ;;
    req-resolve)
      need_approved "$F_REGISTER" req-register
      need_approved "$F_QUALITY" req-quality
      need_approved "$F_QUESTIONS" req-clarify
      if [ -f "$F_QUESTIONS" ]; then
        out=$(awk -v mode=questions -v require=answered -f "$LINT" "$F_QUESTIONS" 2>&1) || FAIL="${FAIL}
  - blocker questions are still unanswered in $F_QUESTIONS:
$(say "$out" | sed 's/^/      /')"
      fi
      ;;
    req-baseline)
      need_approved "$F_REGISTER" req-register
      need_approved "$F_QUALITY" req-quality
      need_fresh_report
      if approved "$F_QUALITY"; then
        out=$(git show "$BASE:$F_QUALITY" | awk -v mode=quality -v require=noblockers -f "$LINT" 2>&1) || FAIL="${FAIL}
  - the quality report still has blocker scores (0). Resolve them with /plumbline:req-clarify and /plumbline:req-resolve:
$(say "$out" | sed 's/^/      /')"
      fi
      if approved "$F_QUESTIONS"; then
        out=$(git show "$BASE:$F_QUESTIONS" | awk -v mode=questions -v require=noopenblockers -f "$LINT" 2>&1) || FAIL="${FAIL}
  - blocker questions are still open:
$(say "$out" | sed 's/^/      /')"
      fi
      if approved "$F_ASSUME"; then
        out=$(git show "$BASE:$F_ASSUME" | awk -v mode=assumptions -v require=decided -f "$LINT" 2>&1) || FAIL="${FAIL}
  - assumptions are still pending a decision:
$(say "$out" | sed 's/^/      /')"
      fi
      ;;
  esac
  [ -z "$FAIL" ]
}

# ----------------------------------------------------------------- lint

register_ids() { # active requirement ids, with type: "R-001 functional"
  awk -v mode=ids -f "$LINT" "$F_REGISTER"
}

lint_file() { # lint_file <step-file-kind>; prints findings, returns 1 on error
  case "$1" in
    register)
      [ -f "$F_REGISTER" ] || { say "missing $F_REGISTER"; return 1; }
      PL_INPUTS=$(input_files) PL_QA="$F_QUESTIONS
$F_ASSUME" awk -v mode=register -f "$LINT" "$F_REGISTER" ;;
    quality)
      [ -f "$F_QUALITY" ] || { say "missing $F_QUALITY"; return 1; }
      PL_IDS=$(register_ids) awk -v mode=quality -f "$LINT" "$F_QUALITY" ;;
    questions)
      [ -f "$F_QUESTIONS" ] || { say "missing $F_QUESTIONS"; return 1; }
      awk -v mode=questions -f "$LINT" "$F_QUESTIONS" ;;
    assumptions)
      [ -f "$F_ASSUME" ] || { say "missing $F_ASSUME"; return 1; }
      awk -v mode=assumptions -f "$LINT" "$F_ASSUME" ;;
    coverage)
      awk -v mode=coverage -f "$LINT" "$F_QUALITY" "$F_QUESTIONS" "$F_ASSUME" ;;
    baseline)
      [ -f "$F_BASELINE" ] || { say "missing $F_BASELINE"; return 1; }
      PL_REG=$(awk -v mode=statements -f "$LINT" "$F_REGISTER") awk -v mode=baseline -f "$LINT" "$F_BASELINE" ;;
  esac
}

lint_step() {
  rc=0
  case "$1" in
    init)         [ -f "$F_STACK" ] || { say "missing $F_STACK"; rc=1; } ;;
    req-register) lint_file register || rc=1 ;;
    req-quality)  lint_file quality || rc=1 ;;
    req-clarify)  lint_file questions || rc=1; lint_file assumptions || rc=1; lint_file coverage || rc=1 ;;
    req-resolve)  lint_file register || rc=1; lint_file quality || rc=1
                  lint_file questions || rc=1; lint_file assumptions || rc=1; lint_file coverage || rc=1 ;;
    req-baseline) lint_file baseline || rc=1 ;;
  esac
  return $rc
}

# ------------------------------------------------------------- commands

cmd_check() {
  refresh; BASE=$(base_ref)
  if gate "$1"; then
    say "plumbline gate: OK for $1 (approved state read from $BASE)"
  else
    printf 'plumbline gate: /plumbline:%s is blocked.%s\n' "$1" "$FAIL" >&2
    exit 1
  fi
}

cmd_begin() {
  refresh; BASE=$(base_ref)
  gate "$1" || { printf 'plumbline gate: /plumbline:%s is blocked.%s\n' "$1" "$FAIL" >&2; exit 1; }
  bad=$(outside_changes "$1")
  [ -z "$bad" ] || die "uncommitted changes outside this step's files. Commit or stash them first:
$bad"
  branch="plumbline/$1-$(date +%Y%m%d-%H%M%S)"
  git switch -q -c "$branch" "$BASE" 2>/dev/null || git checkout -q -b "$branch" "$BASE" \
    || die "could not create $branch from $BASE (do your local changes conflict with $BASE?)"
  say "branch: $branch (from $BASE)"
  say "this step may only change: $(allowed_paths "$1")"
}

stamp() { # write based_on_register into a deliverable's front matter
  f=$1; h=$(git hash-object "$F_REGISTER")
  awk -v h="$h" '
    NR == 1 && $0 != "---" { print "---"; print "based_on_register: " h; print "---"; print; next }
    /^based_on_register:/ { next }
    { print }
    NR == 1 { print "based_on_register: " h }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

# Check, commit and push the step's files on its branch. Used by finish, and
# on its own to add the human's answers to a PR that is already open.
cmd_save() {
  step=$1; title=${2:-"plumbline: $1"}
  BASE=$(base_ref)
  cur=$(git rev-parse --abbrev-ref HEAD)
  case "$cur" in plumbline/"$step"-*) : ;; *) die "not on a plumbline/$step-* branch (on $cur). Run begin first." ;; esac

  bad=$(outside_changes "$step")
  [ -z "$bad" ] || die "this step changed files it does not own. Revert them:
$bad"

  case "$step" in
    req-quality|req-resolve) [ -f "$F_QUALITY" ] && stamp "$F_QUALITY" ;;
    req-baseline)            [ -f "$F_BASELINE" ] && stamp "$F_BASELINE" ;;
  esac

  SUMMARY=$(lint_step "$step") || { say "$SUMMARY"; die "format check failed. Fix the findings above, then run this again."; }
  say "$SUMMARY"

  for a in $(allowed_paths "$step"); do [ -e "$a" ] && git add -- "$a"; done
  git diff --cached --quiet && die "nothing to commit for $step"
  git commit -q -m "$title" || die "commit failed"

  if has_remote; then
    git push -q -u origin "$cur" || die "push failed"
    say "pushed: $cur"
  fi
}

cmd_finish() {
  step=$1; title=${2:-"plumbline: $1"}
  cmd_save "$step" "$title"
  if ! has_remote; then
    say "local mode (no 'origin' remote): review branch $cur, then merge it into ${BASE} to approve."
    return 0
  fi

  body=$(mktemp)
  {
    say "Deliverable of \`/plumbline:$step\`. **Merging this PR is the approval.**"
    say
    say "Edit the files in this PR freely before merging; the next step reads what is merged."
    say
    if [ -f "$PLUGIN_ROOT/templates/review/$step.md" ]; then cat "$PLUGIN_ROOT/templates/review/$step.md"; say; fi
    say "### Format check"
    say '```'
    say "$SUMMARY"
    say '```'
  } > "$body"
  if command -v gh >/dev/null 2>&1; then
    if url=$(gh pr create --base "${BASE#origin/}" --head "$cur" --title "$title" --body-file "$body" 2>&1); then
      say "pull request: $url"
    else
      say "branch pushed, but the PR could not be opened: $url"
      say "Open it by hand for branch $cur."
    fi
  else
    say "gh is not installed, so open the PR by hand for branch $cur."
  fi
  rm -f "$body"
}

cmd_lint() { lint_step "$1"; }

state_of() { # state_of <path>
  if approved "$1"; then
    who=$(git log -1 --format='%an, %ad' --date=short "$BASE" -- "$1" 2>/dev/null)
    say "approved ($who)"
  elif [ -f "$1" ]; then say "draft (not merged)"
  else say "missing"
  fi
}

cmd_status() {
  refresh; BASE=$(base_ref)
  say "plumbline status (approved = merged into $BASE)"
  say
  say "Stage 1: requirements"
  printf '  %-34s %s\n' "$F_STACK" "$(state_of "$F_STACK")"
  printf '  %-34s %s\n' "$F_REGISTER" "$(state_of "$F_REGISTER")"
  printf '  %-34s %s\n' "$F_QUALITY" "$(state_of "$F_QUALITY")"
  printf '  %-34s %s\n' "$F_QUESTIONS" "$(state_of "$F_QUESTIONS")"
  printf '  %-34s %s\n' "$F_ASSUME" "$(state_of "$F_ASSUME")"
  printf '  %-34s %s\n' "$F_BASELINE" "$(state_of "$F_BASELINE")"
  say
  for k in quality questions assumptions; do
    case "$k" in quality) f=$F_QUALITY ;; questions) f=$F_QUESTIONS ;; assumptions) f=$F_ASSUME ;; esac
    [ -f "$f" ] && lint_file "$k" 2>/dev/null | grep '^summary' | sed 's/^/  /'
  done
  say
  next=""
  for s in init req-register req-quality req-clarify req-resolve req-baseline; do
    case "$s" in
      init) f=$F_STACK ;; req-register) f=$F_REGISTER ;; req-quality) f=$F_QUALITY ;;
      req-clarify) f=$F_QUESTIONS ;; req-resolve) continue ;; req-baseline) f=$F_BASELINE ;;
    esac
    approved "$f" || { next=$s; break; }
  done
  if [ -z "$next" ]; then
    say "next: Stage 1 is signed off."
  elif gate "$next"; then
    say "next: /plumbline:$next"
  else
    say "next: /plumbline:$next, blocked by:$FAIL"
  fi
}

cmd_init() { # copy default standards without overwriting anything
  mkdir -p "$STD" "$REQ/input"
  for f in "$PLUGIN_ROOT"/templates/standards/*.md; do
    t="$STD/$(basename "$f")"
    if [ -e "$t" ]; then say "kept    $t"; else cp "$f" "$t" && say "created $t"; fi
  done
  t="$REQ/input/README.md"
  [ -e "$t" ] || { cp "$PLUGIN_ROOT/templates/input-README.md" "$t" && say "created $t"; }
}

# ----------------------------------------------------------------- main

cmd=${1:-}; step=${2:-}
case "$cmd" in
  status) root; cmd_status ;;
  init)   root; cmd_init ;;
  check|begin|lint|save|finish)
    [ -n "$step" ] || die "usage: plumbline.sh $cmd <step>"
    known_step "$step" || die "unknown step: $step"
    root
    case "$cmd" in
      check)  cmd_check "$step" ;;
      begin)  cmd_begin "$step" ;;
      lint)   cmd_lint "$step" ;;
      save)   cmd_save "$step" "${3:-}" ;;
      finish) cmd_finish "$step" "${3:-}" ;;
    esac ;;
  *) die "usage: plumbline.sh <check|begin|lint|save|finish|status|init> [step] [title]" ;;
esac
