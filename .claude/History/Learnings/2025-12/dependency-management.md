# PAI Dependency Management - Learning Doc

**Date**: 2025-12-26
**Context**: Discovered observability dashboard wasn't working due to missing dependencies

## The Problem

When trying to start the Observability dashboard, it appeared to start but the client wasn't accessible. Investigation revealed that neither the server nor client had their dependencies installed via `bun install`.

## Root Cause

The PAI system contains several TypeScript/JavaScript projects that require dependency installation before first use:

1. **Observability Server** - Express + WebSocket server for agent monitoring
2. **Observability Client** - Vite + Vue frontend for the dashboard
3. **Setup Tool** - Interactive PAI configuration wizard

These projects were copied to `~/.claude/` but dependencies weren't automatically installed.

## Projects Requiring Dependencies

| Project | Path | Package Manager | Purpose |
|---------|------|-----------------|---------|
| Observability Server | `~/.claude/Skills/Observability/apps/server` | bun | Backend API |
| Observability Client | `~/.claude/Skills/Observability/apps/client` | bun | Frontend UI |
| Setup Tool | `~/.claude/Tools/setup` | bun | Interactive setup |

## Standalone Tools (No Dependencies)

These use Bun's built-in modules and don't need `bun install`:

- **Voice Server** (`~/.claude/voice-server/server.ts`)
- **All Hooks** (`~/.claude/Hooks/*.ts`)
- **Most Scripts** (shell scripts and standalone TypeScript)

## Solution Created

Created a utility script: `~/.claude/Tools/check-dependencies.sh`

### Usage

```bash
# Check dependency status
~/.claude/Tools/check-dependencies.sh

# Install all missing dependencies
~/.claude/Tools/check-dependencies.sh install
```

## How to Validate a Tool is Working

### For Web Services (Observability, Voice Server)

```bash
# Check if ports are listening
lsof -i :PORT | grep LISTEN

# Test HTTP endpoint
curl http://localhost:PORT/health

# Check running processes
ps aux | grep bun | grep -v grep
```

### For CLI Tools

```bash
# Check dependencies exist
test -d path/to/project/node_modules && echo "OK" || echo "Missing"

# Try running the tool
cd path/to/project
bun run dev  # or appropriate command
```

## Best Practices Learned

1. **Always check for package.json** - If it exists, dependencies likely need installing
2. **Validate before declaring success** - Check actual network ports, not just script output
3. **Document dependency requirements** - Update READMEs with installation steps
4. **Create health check utilities** - Make validation reproducible

## Prevention

Added to PAI setup checklist:
- [ ] Run dependency checker after initial PAI installation
- [ ] Add dependency installation to setup.sh script
- [ ] Document in skill READMEs when dependencies are required

## Related Files

- `/Users/donjacobsmeyer/PAI/.claude/Tools/check-dependencies.sh` - Dependency checker
- `/Users/donjacobsmeyer/PAI/.claude/Skills/Observability/SKILL.md` - Observability docs
- `/Users/donjacobsmeyer/PAI/.claude/settings.json` - Fixed PAI_DIR template issue same session

## Key Takeaway

**Before using any PAI tool for the first time, check if it has a `package.json` and run `bun install` in that directory.**
