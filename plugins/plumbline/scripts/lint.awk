# plumbline format checks. One awk program, selected with -v mode=...
#
# modes: ids | statements | register | quality | questions | assumptions |
#        coverage | baseline
# -v require=... turns a state into a failure (used by the gates):
#   quality:     noblockers
#   questions:   answered | noopenblockers
#   assumptions: decided
#
# Deliverables are made of blocks:
#   ### R-001            (or Q-001, A-001)
#   - Key: value
# Portable awk only (works with mawk and BSD awk).

function trim(s) { sub(/^[ \t\r]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
function norm(s) { gsub(/[ \t\r\n]+/, " ", s); return trim(s) }
function err(m)  { print "error: " m; bad = 1 }
function basename(p) { sub(/^.*\//, "", p); return p }

# collect every R-nnn / G-nnn token of s into set[]
function tokens(s, set,    t) {
  while (match(s, /[RG]-[0-9]+/)) {
    t = substr(s, RSTART, RLENGTH); set[t] = 1
    s = substr(s, RSTART + RLENGTH)
  }
}

BEGIN {
  if (mode == "register") {
    nin = split(ENVIRON["PL_INPUTS"], inf, "\n")
    for (i = 1; i <= nin; i++) {
      if (inf[i] == "") continue
      h = ""
      while ((getline line < inf[i]) > 0) h = h " " line
      close(inf[i])
      hay[basename(inf[i])] = norm(h)
    }
    nqa = split(ENVIRON["PL_QA"], qaf, "\n")
    for (i = 1; i <= nqa; i++) {
      if (qaf[i] == "") continue
      while ((getline line < qaf[i]) > 0)
        if (line ~ /^### [QA]-[0-9]+/) { split(line, w, " "); qa[w[2]] = 1 }
      close(qaf[i])
    }
  }
  if (mode == "quality") {
    nid = split(ENVIRON["PL_IDS"], idl, "\n")
    for (i = 1; i <= nid; i++) if (idl[i] != "") { split(idl[i], w, " "); want[w[1]] = 1; nwant++ }
  }
  if (mode == "baseline") {
    nreg = split(ENVIRON["PL_REG"], rl, "\n")
    for (i = 1; i <= nreg; i++) if (rl[i] != "") {
      split(rl[i], w, "\t"); rtype[w[1]] = w[2]; rstmt[w[1]] = norm(w[3]); rorder[++nr] = w[1]
    }
  }
  fileno = 0
}

FNR == 1 { fileno++; id = ""; section = "" }

# ------------------------------------------------------------ coverage
mode == "coverage" {
  if (fileno == 1) {
    if ($0 ~ /^\| *R-[0-9]+/) {
      split($0, c, "|"); rid = trim(c[2])
      for (k = 3; k <= 8; k++) if (trim(c[k]) + 0 < 2) need[rid] = 1
    }
    if ($0 ~ /^- G-[0-9]+/) { split($0, w, " "); g = w[2]; sub(/[^0-9G-].*$/, "", g); need[g] = 1 }
  } else {
    if ($0 ~ /^## /) section = substr($0, 4)
    if ($0 ~ /^- Requirements:/ || section ~ /^Deferred/) tokens($0, cov)
  }
  next
}

# ------------------------------------------------------- quality table
mode == "quality" {
  if ($0 ~ /^\| *R-[0-9]+/) {
    n = split($0, c, "|"); rid = trim(c[2])
    if (rid in row) err("duplicate row for " rid)
    row[rid] = 1; rows++
    if (n < 10) err(rid ": row needs 8 columns (ID, six scores, Finding)")
    low = 2
    for (k = 3; k <= 8; k++) {
      v = trim(c[k])
      if (v != "0" && v != "1" && v != "2") err(rid ": score '" v "' must be 0, 1 or 2")
      else if (v + 0 < low) low = v + 0
    }
    if (low < 2 && trim(c[9]) == "") err(rid ": a score below 2 needs a Finding")
    if (low == 0) { nb++; blist = blist " " rid } else if (low == 1) nc++; else nready++
  }
  if ($0 ~ /^- G-[0-9]+/) ngap++
  next
}

# --------------------------------------------------- block deliverables
/^## / { id = ""; section = substr($0, 4); sect[section] = 1; next }

/^### [RQA]-[0-9]+/ {
  id = $2
  if (id in seen) err("duplicate id " id)
  seen[id] = 1; order[++nblk] = id
  next
}

id != "" && /^- [A-Za-z][A-Za-z ]*:/ {
  p = index($0, ":")
  key = substr($0, 3, p - 3)
  F[id, key] = trim(substr($0, p + 1)); has[id, key] = 1
}

id != "" { text[id] = text[id] " " $0 }

# ----------------------------------------------------------------- END
function need_field(i, k) {
  if (!((i, k) in has) || F[i, k] == "") { err(i ": missing '" k "'"); return 0 }
  return 1
}
function need_enum(i, k, list,    a, n, j) {
  if (!need_field(i, k)) return
  n = split(list, a, "|")
  for (j = 1; j <= n; j++) if (F[i, k] == a[j]) return
  err(i ": " k " '" F[i, k] "' must be one of " list)
}
function active(i) { return !((i, "State") in has) || F[i, "State"] != "dropped" }

END {
  if (mode == "ids") {
    for (j = 1; j <= nblk; j++) { i = order[j]; if (active(i)) print i " " F[i, "Type"] }
    exit 0
  }
  if (mode == "statements") {
    for (j = 1; j <= nblk; j++) { i = order[j]; if (active(i)) print i "\t" F[i, "Type"] "\t" F[i, "Statement"] }
    exit 0
  }

  if (mode == "register") {
    if (nblk == 0) err("no requirements found (expected '### R-001' blocks)")
    for (j = 1; j <= nblk; j++) {
      i = order[j]
      if (i !~ /^R-/) { err(i ": only R- ids belong in the register"); continue }
      need_enum(i, "Type", "functional|nfr|constraint|data|integration")
      need_enum(i, "Priority", "must|should|could|unknown")
      need_enum(i, "Origin", "stated|derived|clarified")
      if ((i, "State") in has) need_enum(i, "State", "active|dropped")
      need_field(i, "Statement")
      if (!need_field(i, "Source")) continue
      src = F[i, "Source"]; o = F[i, "Origin"]
      if (o == "stated") {
        nstated++
        a = index(src, "\""); q = ""
        if (a > 0) {
          rest = substr(src, a + 1); b = 0
          for (k = length(rest); k > 0; k--) if (substr(rest, k, 1) == "\"") { b = k; break }
          if (b > 0) q = norm(substr(rest, 1, b - 1))
        }
        if (length(q) < 8) { err(i ": Source needs a verbatim quote in straight double quotes"); continue }
        named = 0; found = 0
        for (f in hay) if (index(src, f) > 0) { named = 1; if (index(hay[f], q) > 0) found = 1 }
        if (!named) err(i ": Source must name the input file the quote comes from")
        else if (!found) err(i ": quote not found verbatim in the named input file: \"" q "\"")
      } else if (o == "derived") {
        nderived++
        delete tk; tokens(src, tk); ok = 0
        for (t in tk) if (t != i && (t in seen)) ok = 1
        if (!ok) err(i ": a derived requirement must name the requirement it follows from")
      } else if (o == "clarified") {
        nclar++
        ok = 0; s = src
        while (match(s, /[QA]-[0-9]+/)) { if (substr(s, RSTART, RLENGTH) in qa) ok = 1; s = substr(s, RSTART + RLENGTH) }
        if (!ok) err(i ": a clarified requirement must name an existing question or assumption (Q-/A- id)")
      }
      if (!active(i)) ndropped++
    }
    print "summary register: " nblk " requirements (" nstated + 0 " stated, " nderived + 0 " derived, " nclar + 0 " clarified, " ndropped + 0 " dropped)"
    exit bad
  }

  if (mode == "quality") {
    if (rows == 0) err("no score rows found (expected '| R-001 | 2 | ... |')")
    if (nwant > 0) {
      for (i in want) if (!(i in row)) err(i ": in the register but not scored")
      for (i in row) if (!(i in want)) err(i ": scored but not an active requirement in the register")
    }
    print "summary quality: " rows + 0 " scored, " nb + 0 " blocked (a 0 score), " nc + 0 " need clarification, " nready + 0 " ready, " ngap + 0 " gaps"
    if (require == "noblockers" && nb > 0) { print "blocked:" blist; bad = 1 }
    exit bad
  }

  if (mode == "questions") {
    for (j = 1; j <= nblk; j++) {
      i = order[j]
      if (i !~ /^Q-/) { err(i ": only Q- ids belong in questions.md"); continue }
      need_enum(i, "Severity", "blocker|normal")
      need_enum(i, "State", "open|resolved")
      need_field(i, "Requirements"); need_field(i, "Question"); need_field(i, "Why it matters")
      need_field(i, "Options"); need_field(i, "Recommended")
      if (!((i, "Answer") in has)) err(i ": missing 'Answer' line (leave it empty until answered)")
      if (F[i, "State"] == "open") {
        nopen++
        if (F[i, "Severity"] == "blocker") {
          nob++; oblist = oblist " " i
          if (F[i, "Answer"] == "") { nun++; unlist = unlist " " i }
        }
      }
    }
    if (nopen > 10) err("more than 10 open questions in one round (" nopen "). Keep the 10 with the highest impact and move the rest under '## Deferred'.")
    print "summary questions: " nblk + 0 " total, " nopen + 0 " open, " nob + 0 " open blockers, " nun + 0 " unanswered blockers"
    if (require == "answered" && nun > 0) { print "unanswered:" unlist; bad = 1 }
    if (require == "noopenblockers" && nob > 0) { print "open blockers:" oblist; bad = 1 }
    exit bad
  }

  if (mode == "assumptions") {
    for (j = 1; j <= nblk; j++) {
      i = order[j]
      if (i !~ /^A-/) { err(i ": only A- ids belong in assumptions.md"); continue }
      need_field(i, "Requirements"); need_field(i, "Assumption"); need_field(i, "Risk if wrong")
      need_enum(i, "Decision", "pending|confirmed|rejected")
      if (F[i, "Decision"] == "pending") { npend++; plist = plist " " i }
    }
    print "summary assumptions: " nblk + 0 " total, " npend + 0 " pending"
    if (require == "decided" && npend > 0) { print "pending:" plist; bad = 1 }
    exit bad
  }

  if (mode == "coverage") {
    for (i in need) if (!(i in cov)) err(i ": scored below 2 (or is a gap) but no question, assumption or deferred item covers it")
    if (!bad) print "summary coverage: every finding is covered by a question, an assumption or a deferred item"
    exit bad
  }

  if (mode == "baseline") {
    if (!("Glossary" in sect)) err("missing '## Glossary' section")
    if (!("Out of scope" in sect)) err("missing '## Out of scope' section")
    for (j = 1; j <= nr; j++) {
      i = rorder[j]
      if (!(i in seen)) { err(i ": active in the register but missing from the baseline"); continue }
      if (norm(F[i, "Statement"]) != rstmt[i]) err(i ": Statement differs from the register. Change the register through /plumbline:req-resolve, not here.")
      t = rtype[i]
      if (t == "nfr") { need_field(i, "Target"); need_field(i, "Measured by") }
      else if (t == "constraint") need_field(i, "Verified by")
      else if (text[i] !~ /Given/ || text[i] !~ /When/ || text[i] !~ /Then/) err(i ": needs at least one Given / When / Then acceptance criterion")
    }
    for (j = 1; j <= nblk; j++) if (!(order[j] in rstmt)) err(order[j] ": in the baseline but not an active requirement in the register")
    print "summary baseline: " nblk + 0 " requirements with acceptance criteria or targets"
    exit bad
  }
}
