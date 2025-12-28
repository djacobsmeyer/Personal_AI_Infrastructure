# OrbStack Setup for Google Calendar MCP

## Why OrbStack?

OrbStack is the recommended container runtime for PAI on macOS:

- **Faster**: ~2-3x faster than Docker Desktop
- **Lighter**: ~1/10th the resource usage
- **Compatible**: 100% Docker CLI compatible
- **Better UX**: Native macOS integration
- **Free**: No licensing restrictions

## Installation

```bash
# Install via Homebrew (if not already installed)
brew install orbstack
```

## Usage with Calendar MCP

All Docker commands work identically:

```bash
# Build the container
cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/docker
docker compose build

# Start the service
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f

# Stop the service
docker compose down
```

## Verification

Check that OrbStack is running:

```bash
# Should show OrbStack context
docker context ls

# Should show OrbStack version
docker version | grep -i orbstack
```

## Advantages for MCP Servers

1. **Fast Startup**: Containers start in <1 second
2. **Low Overhead**: Minimal CPU/memory impact when idle
3. **Auto-sleep**: Containers sleep when not in use (saves resources)
4. **Native Integration**: Feels like native macOS processes
5. **No VM Overhead**: Uses macOS virtualization framework

## Configuration

No changes needed! The existing `docker-compose.yml` works as-is:

```yaml
# This works perfectly with OrbStack
services:
  gcal-mcp:
    build: .
    container_name: gcal-mcp
    # ... rest of configuration
```

## Troubleshooting

### OrbStack Not Running

```bash
# Start OrbStack
open -a OrbStack
```

### Switch from Docker Desktop

```bash
# Stop Docker Desktop
# (via System Preferences → Applications)

# OrbStack automatically becomes the Docker provider
docker context use orbstack

# Verify
docker info | grep -i orbstack
```

## Performance Comparison

| Metric | Docker Desktop | OrbStack |
|--------|---------------|----------|
| Startup Time | ~30s | ~2s |
| Memory Usage | ~2GB idle | ~200MB idle |
| CPU Usage | 5-10% idle | <1% idle |
| Container Start | ~2-3s | ~500ms |
| Disk Space | ~5GB | ~500MB |

## Resources

- [OrbStack Website](https://orbstack.dev/)
- [OrbStack Documentation](https://docs.orbstack.dev/)
- [Docker CLI Compatibility](https://docs.orbstack.dev/docker/)

---

**Bottom Line**: Use OrbStack for all containerized MCP servers in PAI. It's faster, lighter, and provides a better experience while maintaining 100% Docker compatibility.
