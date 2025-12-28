#!/bin/bash
# PAI Dependency Checker & Installer
# Usage:
#   ./check-dependencies.sh          # Check status
#   ./check-dependencies.sh install  # Install all missing deps

set -e

PROJECTS=(
  "$HOME/.claude/Skills/Observability/apps/server|Observability Server"
  "$HOME/.claude/Skills/Observability/apps/client|Observability Client"
  "$HOME/.claude/Tools/setup|Setup Tool"
)

check_status() {
  echo "=== PAI Dependency Status ==="
  echo

  local missing=0

  for entry in "${PROJECTS[@]}"; do
    IFS='|' read -r path name <<< "$entry"

    echo "[$name]"
    echo "  Path: $path"

    if [ ! -f "$path/package.json" ]; then
      echo "  Status: ⚠️  No package.json found"
    elif [ -d "$path/node_modules" ]; then
      pkg_count=$(ls -1 "$path/node_modules" 2>/dev/null | wc -l | xargs)
      echo "  Status: ✅ Dependencies installed ($pkg_count packages)"
    else
      echo "  Status: ❌ Dependencies NOT installed"
      missing=$((missing + 1))
    fi
    echo
  done

  echo "=== Standalone Tools (No Dependencies Required) ==="
  echo "[Voice Server] ~/.claude/voice-server/server.ts"
  echo "[Hooks] ~/.claude/Hooks/*.ts"
  echo

  if [ $missing -gt 0 ]; then
    echo "⚠️  $missing project(s) missing dependencies"
    echo "Run: $0 install"
    return 1
  else
    echo "✅ All projects have dependencies installed"
    return 0
  fi
}

install_all() {
  echo "=== Installing Dependencies ==="
  echo

  for entry in "${PROJECTS[@]}"; do
    IFS='|' read -r path name <<< "$entry"

    if [ ! -f "$path/package.json" ]; then
      continue
    fi

    if [ -d "$path/node_modules" ]; then
      echo "⏭️  Skipping $name (already installed)"
      continue
    fi

    echo "📦 Installing $name..."
    echo "   Path: $path"
    cd "$path"
    bun install
    echo "   ✅ Done"
    echo
  done

  echo "✅ All dependencies installed!"
}

case "${1:-check}" in
  install)
    install_all
    ;;
  check|status|*)
    check_status
    ;;
esac
