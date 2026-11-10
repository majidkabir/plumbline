# Requirements rules

Company rules for writing and judging requirements. Edit them to match your
standards; every Stage 1 agent reads this file.

## Statement rules

- One statement has one actor, one behaviour or constraint, and one outcome.
- A statement containing "and", "or", or a list is split into several.
- Name the actor by role ("the dispatcher"), never "the user" when roles differ.
- Use "must" for obligations. Avoid "should be able to".

## Types

- functional: something the system does for an actor.
- nfr: a quality the system has (performance, availability, security, usability).
- constraint: a limit on the solution (technology, law, budget, deadline).
- data: what is stored, for how long, who owns it.
- integration: an exchange with another system.

## Priority

- must, should, could. Taken from the source wording only.
- unknown when the source does not say. Never guess a priority.

## Words that make a requirement unclear

Any of these in a statement caps Clarity at 1 until it is replaced by something
measurable or observable:

fast, quick, slow, easy, simple, intuitive, user-friendly, modern, flexible,
scalable, robust, secure, reliable, efficient, seamless, appropriate, adequate,
reasonable, sufficient, minimal, optimal, as needed, if possible, etc., and so
on, some, several, many, few, often, usually, normally, real-time, support,
handle, manage, process (without saying what happens).

## Scores

Each requirement is scored 0, 1 or 2 on six checks.

| Score | Meaning |
|---|---|
| 0 | Blocker. Work on this requirement cannot start. |
| 1 | Usable only after a question is answered or an assumption is confirmed. |
| 2 | Ready. |

| Check | 0 | 1 | 2 |
|---|---|---|---|
| Clarity | Two readers would build different things | One term or phrase is open to interpretation | Only one reading |
| Completeness | Actor, trigger or outcome is missing | Error or edge cases are missing | Actor, trigger, outcome and failure behaviour are present |
| Consistency | Contradicts another requirement or a standard | Overlaps or duplicates another requirement | No conflict |
| Testability | No pass/fail test can be written | A test needs a number or threshold that is not given | A pass/fail test can be written as it stands |
| Feasibility | Cannot be done within the stack or constraints | Unknown until a spike or missing information | Doable with the stated stack |
| Scope | Does not serve the stated goal | Goes beyond what the goal needs | Serves the stated goal |
