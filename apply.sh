#!/bin/sh
#
# Boilerplate harness: installs the agent instructions, the stack .gitignore
# and the commit-msg hook into a target project.
#
#   ./apply.sh [-s stack] [-f] <target-dir>
#
#   -s stack   node | godot (default: detected from the target)
#   -f         replace AGENTS.md and CLAUDE.md even if they already exist
#
# Safe to re-run: it refreshes .agents/, .githooks/ and the managed .gitignore
# block in place and leaves everything else alone.

set -e

src=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
stack=""
force=0

usage() {
  echo "usage: $0 [-s stack] [-f] <target-dir>" >&2
  echo "  available stacks: $(ls "$src/.agents" | tr '\n' ' ')" >&2
  exit 2
}

while getopts 's:fh' opt; do
  case "$opt" in
    s) stack=$OPTARG ;;
    f) force=1 ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

target=$1
[ -n "$target" ] || usage
[ -d "$target" ] || { echo "error: no such directory: $target" >&2; exit 1; }
target=$(CDPATH= cd -- "$target" && pwd)

[ "$target" != "$src" ] || { echo "error: target is the boilerplate itself" >&2; exit 1; }

# Detect the stack from whatever manifest the target already has.
if [ -z "$stack" ]; then
  if [ -f "$target/package.json" ]; then
    stack=node
  elif [ -f "$target/project.godot" ]; then
    stack=godot
  else
    echo "error: could not detect the stack, pass -s" >&2
    usage
  fi
fi

expansion="$src/.agents/$stack"
[ -d "$expansion" ] || { echo "error: unknown stack: $stack" >&2; usage; }

echo "applying boilerplate ($stack) to $target"

# 1. Stack expansion, always refreshed so a re-run picks up updates.
mkdir -p "$target/.agents/$stack"
cp "$expansion/AGENTS.md" "$target/.agents/$stack/AGENTS.md"
echo "  .agents/$stack/  updated"

# 2. Baseline rules and the Claude Code pointer. A project may have appended
#    its own rules to these, so they are not clobbered without -f.
install_doc() {
  if [ -f "$target/$1" ] && [ "$force" -eq 0 ]; then
    echo "  $1  kept (exists, use -f to replace)"
  else
    cp "$2" "$target/$1"
    echo "  $1  written"
  fi
}

install_doc AGENTS.md "$src/AGENTS.md"
install_doc CLAUDE.md "$src/CLAUDE.md"

# 3. .gitignore, merged as a marked block so local entries survive a re-run.
ignore="$target/.gitignore"
begin="# --- boilerplate:$stack (managed, edits are overwritten) ---"
end="# --- end boilerplate:$stack ---"
tmp="$ignore.boilerplate.tmp"

if [ -f "$ignore" ]; then
  awk -v s="$begin" -v e="$end" '
    $0 == s { skip = 1 }
    skip != 1 { print }
    $0 == e { skip = 0 }
  ' "$ignore" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' > "$tmp"
  [ -s "$tmp" ] && printf '\n' >> "$tmp"
else
  : > "$tmp"
fi

{ echo "$begin"; cat "$expansion/.gitignore"; echo "$end"; } >> "$tmp"
mv "$tmp" "$ignore"
echo "  .gitignore  block refreshed"

# 4. Commit message hook.
mkdir -p "$target/.githooks"
cp "$src/.githooks/commit-msg" "$target/.githooks/commit-msg"
cp "$src/.githooks/install.sh" "$target/.githooks/install.sh"
chmod +x "$target/.githooks/commit-msg" "$target/.githooks/install.sh"

if git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$target" config core.hooksPath .githooks
  echo "  .githooks/  installed and enabled"
else
  echo "  .githooks/  copied (not a git repo yet, run .githooks/install.sh after git init)"
fi

echo "done"
