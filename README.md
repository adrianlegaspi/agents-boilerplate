# boilerplate

Reusable starting material for new projects: baseline instructions for AI
coding agents, stack-specific expansions, a generic `.gitignore` per stack and
a commit message hook. `apply.sh` installs all of it into a target project.

## Layout

```
AGENTS.md                      Baseline rules, stack independent
CLAUDE.md                      Pointer to AGENTS.md for Claude Code
apply.sh                       Harness that installs this into a project
.agents/                       Stack expansions, one subfolder per stack
  godot/                       AGENTS.md expansion + generic .gitignore
  node/                        AGENTS.md expansion + generic .gitignore
.githooks/
  commit-msg                   Conventional Commits check
  install.sh                   Points core.hooksPath at .githooks
```

`AGENTS.md` sits at the root because that is the filename agents discover.
Everything layered on top of it is centralized under `.agents/`, so a project
can refresh its stack rules as one unit.

## Usage

```sh
./apply.sh <target-dir>            # stack detected from the target
./apply.sh -s node <target-dir>    # or named explicitly
./apply.sh -f <target-dir>         # also refresh AGENTS.md and CLAUDE.md
```

The stack is detected from `package.json` or `project.godot`. The harness:

1. Copies the matching expansion to `<target>/.agents/<stack>/`.
2. Writes `AGENTS.md` and `CLAUDE.md`, unless they already exist. A project
   may have appended its own rules, so replacing them needs `-f`.
3. Merges the stack `.gitignore` into the target's as a marked block, leaving
   any entries the project already had.
4. Copies `.githooks/` and sets `core.hooksPath` when the target is a git
   repo.

Re-running is safe. It refreshes the managed pieces in place, so pulling
updates from this repo into an existing project is just another run.

## Commit message hook

[.githooks/commit-msg](./.githooks/commit-msg) enforces the
[Conventional Commits](https://www.conventionalcommits.org/) rules described
in [AGENTS.md](./AGENTS.md): `type(scope): subject`, lowercase subject, no
trailing period, 72 character limit and a blank line before any body. Merge,
revert, fixup and squash messages are left alone.

Git hooks are not active by default, so a clone that did not go through
`apply.sh` needs `./.githooks/install.sh` once.
