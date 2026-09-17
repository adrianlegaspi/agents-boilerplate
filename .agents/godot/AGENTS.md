# Godot expansion

Stack-specific rules to layer on top of [AGENTS.md](../../AGENTS.md) when the
project is a Godot game. These add to the base rules, they do not replace
them.

## Scenes are the architecture — don't code around the engine

Godot projects are built with scenes and resources first, script second.
Defaulting to "just write a script that builds everything at runtime" throws
away the engine's own tooling (Inspector, live preview, designer-tunable
values) and produces scenes that are unreadable in the editor.

**No empty or stub scenes.** A scene whose entire content is a root node plus
a script that constructs everything in `_ready()` is not done. Before
considering a scene finished, it should have, authored in the editor:

- the real node hierarchy (meshes, collision shapes, areas, timers, markers,
  cameras, lights, UI controls)
- property values set on those nodes (transforms, shapes, collision
  layers/masks, particle params, anchors)
- child scene instances for anything reusable, rather than nodes created ad
  hoc in code
- signal connections made in the editor when the connection is static and
  known at author time
- a result that's inspectable and playable directly from the editor (F6 on
  that scene), not only through the full game loop

If you open a scene in the editor and can't tell what it is, it fails this
bar.

**Preference order when building a feature:**

1. Scene composition — instanced `.tscn` children over `add_child(Node.new())`.
2. Editor-authored nodes and values — set in the Inspector, not in `_ready()`.
3. Built-in nodes for the job — `Area3D`/`Area2D`, `Timer`, `AnimationPlayer`,
   `AnimationTree`, particle nodes, `NavigationRegion`, `AudioStreamPlayer*`,
   `CanvasLayer`, `Control` anchors/containers — before writing custom logic
   that reimplements what one of these already does.
4. Custom `Resource` (`.tres`) files for structured data (stats, config,
   tables) so non-programmers can tune values without touching code.
5. Signals and groups over polling and over hard node-path lookups.
6. GDScript, for behavior that genuinely can't be expressed as structure or
   data.

Concretely: a distinct object type (enemy, item, weapon, UI panel) usually
wants its own scene, with a data `Resource` for its tunable stats, rather
than one generic node driven by a large `match`/`if` chain keyed on a type
enum.

## GDScript conventions

- Use **static typing** everywhere it's expressible: `var hp: int = 100`,
  `func fire() -> void:`. Untyped code loses editor autocomplete and a whole
  class of caught-at-edit-time errors.
- Naming: `snake_case` for files, directories, functions, variables, signals,
  and exported properties. `PascalCase` for classes, node type names, and
  scene files. `CONSTANT_CASE` for constants and enum values.
- Add `class_name` to any script that gets instantiated elsewhere or used in
  a type check/annotation — otherwise it's just a plain `Node` to the rest of
  the codebase.
- `@export` every tunable value (physics constants, scores, weights, timings)
  instead of hardcoding it — that's what lets values be tuned without a code
  change and a re-deploy. Use `@export_group` once a script's Inspector
  panel gets crowded.
- Prefer `@onready` plus `%UniqueName` or a short `$Path` over long
  `get_node("../../Foo/Bar")` chains scattered through a file — the latter
  breaks silently when the scene tree is reorganized.
- Put physics/movement logic in `_physics_process`; put purely visual or
  animation logic in `_process`. Mixing the two causes frame-rate-dependent
  bugs in physics code.
- Prefer signals over direct references between unrelated systems (e.g. a
  hazard and the player, a spawner and a UI manager). Direct node references
  between systems that don't own each other create coupling that breaks the
  moment either scene's structure changes.
- Each scene should own exactly one system's responsibility. A scene that's
  simultaneously doing input handling, game state, and rendering is a sign
  it should be split.

## Performance (relevant on mobile / lower-end targets)

- Watch draw call count, active particle systems, and live physics body
  count — these are the usual first bottlenecks, not raw script execution.
- Prefer `GPUParticles*` over CPU particles where the target hardware
  supports it.
- Don't run expensive logic (pathfinding, wide-radius queries, complex
  math) in `_process`/`_physics_process` for objects that don't need
  per-frame updates — gate it behind a `Timer` or an event instead.

## Testing (GUT or equivalent)

- Test pure logic — score/damage calculations, data-table lookups,
  probability/weight sampling, state-machine transitions — not the engine
  itself. Don't write tests for scene rendering, physics simulation, or
  thin wrappers around a single engine call; Godot's own test suite already
  covers that ground.
- Mirror the source layout under a test root, e.g.
  `src/combat/damage_calculator.gd` → `tests/unit/test_damage_calculator.gd`.
- For a bug fix: write one test that fails before the fix and passes after,
  named after the bug scenario rather than the fix
  (`test_merge_does_not_double_trigger_on_simultaneous_contact`, not
  `test_merge_fix`).
- Keep one behavior per test — no multi-assert tests covering unrelated
  scenarios.

## Working with an MCP Godot editor server

If the project has a Godot MCP server configured (e.g. `godot-mcp-pro`),
prefer its tools for scene/node/resource manipulation over hand-writing
`.tscn`/`.tres` text — the editor tools keep UIDs, resource references, and
the scene format consistent in ways manual text edits easily corrupt.

Verify visually before claiming a visual or gameplay feature works: take an
editor or in-game screenshot (or run the scene and check the output log)
rather than asserting it from reading the script alone.

## Repo hygiene specific to Godot

- `.gitignore` should exclude `.godot/` (the local editor cache — regenerated
  automatically, never commit it) and any export-preset files containing
  signing keys or credentials.
- Don't commit editor-generated `.import` metadata churn alongside unrelated
  changes — regenerate it locally rather than hand-editing.
- A staging directory (e.g. `tmp/`) for inbound art/audio/model assets before
  they're wired in is a useful convention: check it before requesting new
  assets, and when one is used, move it to its real production path with a
  proper name, update every reference, and delete the source from the
  staging directory so it doesn't linger as an orphaned duplicate.
