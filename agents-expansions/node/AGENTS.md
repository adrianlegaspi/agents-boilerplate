# Node expansion

Stack-specific rules to layer on top of [AGENTS.md](../../AGENTS.md) when the
project is a Node.js project. Copy this file's content into the project's own
`AGENTS.md` (or link to it) — it doesn't replace the base rules, it adds to
them.

## Package manager

- Use whichever package manager the project already committed a lockfile
  for (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`).
  Don't introduce a second one — mixed lockfiles cause divergent dependency
  trees between contributors and CI.
- Never hand-edit a lockfile. Let the package manager regenerate it via its
  own install/update commands (see AGENTS.md's "generated or tool-owned
  files" rule).
- Pin exact versions for anything security-sensitive or prone to breaking
  changes; otherwise follow whatever range style (`^`, `~`, exact) the
  existing `package.json` already uses.

## Project conventions

- Match the module system already in use (`"type": "module"` / ESM vs
  CommonJS `require`) — don't mix `import` and `require` in the same
  package without a specific reason (e.g. a `.cjs`/`.mjs` boundary).
- Follow the existing TypeScript strictness level (`strict` in
  `tsconfig.json`) rather than loosening it to make new code compile.
- Naming: `camelCase` for variables and functions, `PascalCase` for
  classes/types/interfaces/components, `kebab-case` or `camelCase` for
  filenames — match whichever the codebase already uses consistently.
- Keep `package.json` scripts as the entry point for common tasks (build,
  test, lint, dev) rather than telling contributors to run the underlying
  tool directly.

## Environment & secrets

- Config and secrets come from environment variables, loaded via whatever
  the project already uses (`dotenv`, `process.env` directly, a framework's
  built-in config loader) — don't add a second env-loading mechanism.
- `.env`, `.env.local`, and any other real env files stay gitignored. Commit
  `.env.example` with placeholder values so contributors know what's
  required.

## Dependencies

- Prefer a well-maintained existing dependency in `package.json` over adding
  a new one for the same job (e.g. don't add `moment` when `date-fns` is
  already a dependency).
- Check `engines` in `package.json` before using a language/runtime feature
  newer than the declared minimum Node version.
- Run the project's audit command (`npm audit`, `pnpm audit`, etc.) only
  when asked or when it's part of the project's own CI gate — not
  proactively on every change.

## Testing

- Use whichever test runner is already configured (Jest, Vitest, Mocha,
  node's built-in `node:test`, etc.) — don't introduce a second one.
- Mirror the source layout for test files unless the project's existing
  convention is co-located `*.test.ts`/`*.spec.ts` files next to the
  source — match what's already there.
- Mock network/filesystem/time at the boundary (fetch, fs, `Date.now`), not
  internal application logic, so tests exercise real behavior.

## Repo hygiene specific to Node

- `.gitignore` should exclude `node_modules/`, build output directories
  (`dist/`, `build/`, `.next/`, etc.), and any framework-specific cache
  directories — never commit `node_modules/`, it's fully reproducible from
  the lockfile.
- Don't commit editor/OS artifacts (`.DS_Store`, `Thumbs.db`) or local
  environment overrides.
