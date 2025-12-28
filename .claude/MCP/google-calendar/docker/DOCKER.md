# Docker Deployment Guide for Google Calendar MCP

## Overview

This guide covers containerized deployment of the Google Calendar MCP server using Docker and Bun runtime. This approach provides:

- **Process Isolation**: Clean separation from host system
- **Resource Limits**: CPU and memory controls
- **Reproducibility**: Consistent environment across systems
- **Security**: Non-root execution, read-only credentials
- **Reliability**: Auto-restart policies and health checks

## Architecture

```
┌─────────────────────────────────────────┐
│ Claude Code                             │
│  ├─ Spawns MCP clients                 │
│  └─ Communicates via stdio             │
└───────────────┬─────────────────────────┘
                │
                │ stdio/socket
                │
┌───────────────▼─────────────────────────┐
│ Docker Container: gcal-mcp              │
│  ├─ Bun Runtime (Alpine Linux)         │
│  ├─ @cocal/google-calendar-mcp@2.2.0   │
│  ├─ Mounted credentials (read-only)    │
│  └─ Mounted tokens (read-write)        │
└─────────────────────────────────────────┘
```

## Prerequisites

- **OrbStack** (recommended for macOS) or Docker Desktop 28.5.2+ or Podman
  - OrbStack is faster, lighter, and fully Docker-compatible
  - All `docker` and `docker compose` commands work identically
- Bun 1.3.5+ (for local testing)
- Google OAuth credentials (see main README.md)

## Quick Start

### 1. Build the Container

```bash
cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/docker
docker compose build
```

### 2. Place Credentials

Ensure your OAuth credentials are in place:
```bash
ls -la ../credentials/credentials.json
```

### 3. Initial Authentication

Run the auth flow in the container:
```bash
docker compose run --rm google-calendar-mcp auth
```

This will:
- Start the container with network access
- Open browser for OAuth consent
- Save token to `../tokens/token.json`
- Exit and clean up container

### 4. Start the Service

```bash
docker compose up -d
```

### 5. Verify Health

```bash
docker compose ps
docker compose logs google-calendar-mcp
```

## Configuration for Claude Code

### Option A: Stdio Connection (Direct)

Add to `.claude/.mcp.json`:

```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "docker",
      "args": [
        "compose",
        "-f",
        "/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/docker/docker-compose.yml",
        "run",
        "--rm",
        "google-calendar-mcp"
      ],
      "description": "Google Calendar management (containerized)"
    }
  }
}
```

**Advantages**:
- Claude Code manages container lifecycle
- Clean startup/shutdown
- No background processes
- Resource limits enforced

**Disadvantages**:
- Slower startup (container boot time)
- Higher resource usage per session

### Option B: Long-Running Service (Recommended)

Keep container running and connect via socket/stdio:

1. Start service:
```bash
docker compose up -d
```

2. Configure Claude Code with exec into running container:
```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "gcal-mcp",
        "bunx",
        "--bun",
        "@cocal/google-calendar-mcp",
        "start"
      ],
      "description": "Google Calendar management (containerized service)"
    }
  }
}
```

**Advantages**:
- Fast connection (no container boot)
- Lower resource usage
- Single container instance
- Persistent token caching

**Disadvantages**:
- Requires manual container management
- Need to ensure container is running

## Container Management

### Start Service
```bash
docker compose up -d
```

### Stop Service
```bash
docker compose down
```

### View Logs
```bash
docker compose logs -f google-calendar-mcp
```

### Restart Service
```bash
docker compose restart
```

### Update to Latest Version
```bash
docker compose pull
docker compose up -d --force-recreate
```

### Shell Access (Debugging)
```bash
docker compose exec google-calendar-mcp sh
```

## Security Configuration

### File Permissions

The container runs as non-root user `mcp` (UID 1001):

```bash
# Set proper ownership
chown -R 1001:1001 ../credentials ../tokens

# Restrict permissions
chmod 600 ../credentials/credentials.json
chmod 600 ../tokens/token.json
chmod 755 ../credentials ../tokens
```

### Network Isolation

By default, the container uses `bridge` network for OAuth flow. After authentication, you can switch to isolated mode:

Edit `docker-compose.yml`:
```yaml
# For post-auth operation (more secure)
network_mode: none

# For auth flow (required for browser OAuth)
network_mode: bridge
```

### Read-Only Credentials

Credentials are mounted read-only to prevent accidental modification:
```yaml
volumes:
  - ../credentials:/app/credentials:ro  # Read-only
```

### Security Best Practices

1. **Limit container privileges**:
   - No new privileges: `no-new-privileges:true`
   - Non-root user execution
   - Minimal base image (Alpine)

2. **Resource constraints**:
   - CPU limit: 0.5 cores
   - Memory limit: 256MB
   - Prevents resource exhaustion

3. **Logging limits**:
   - Max file size: 10MB
   - Max files: 3
   - Prevents disk space issues

## Volume Management

### Backup Tokens

```bash
# Backup refresh token
docker run --rm -v gcal-mcp-tokens:/data -v $(pwd):/backup \
  alpine tar czf /backup/tokens-backup.tar.gz -C /data .
```

### Restore Tokens

```bash
# Restore from backup
docker run --rm -v gcal-mcp-tokens:/data -v $(pwd):/backup \
  alpine tar xzf /backup/tokens-backup.tar.gz -C /data
```

### Inspect Volumes

```bash
docker volume inspect gcal-mcp_credentials
docker volume inspect gcal-mcp_tokens
```

## Health Checks

The container includes automatic health monitoring:

```yaml
healthcheck:
  test: ["CMD", "bunx", "--bun", "@cocal/google-calendar-mcp", "version"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 5s
```

Check health status:
```bash
docker compose ps
docker inspect gcal-mcp --format='{{.State.Health.Status}}'
```

## Resource Monitoring

### Real-Time Stats
```bash
docker stats gcal-mcp
```

### Resource Limits
```bash
docker inspect gcal-mcp | jq '.[0].HostConfig.Memory'
docker inspect gcal-mcp | jq '.[0].HostConfig.NanoCpus'
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose logs google-calendar-mcp

# Verify credentials exist
docker compose run --rm google-calendar-mcp ls -la /app/credentials

# Test manual start
docker compose run --rm google-calendar-mcp version
```

### Authentication Issues

```bash
# Re-run auth flow
docker compose run --rm google-calendar-mcp auth

# Check token file
docker compose run --rm google-calendar-mcp ls -la /app/tokens

# Verify permissions
docker compose run --rm google-calendar-mcp cat /app/credentials/credentials.json
```

### Network Problems During Auth

```bash
# Ensure bridge network mode
grep network_mode docker-compose.yml

# Test network connectivity
docker compose run --rm google-calendar-mcp ping -c 3 google.com
```

### Permission Denied Errors

```bash
# Fix ownership (run on host)
sudo chown -R 1001:1001 ../credentials ../tokens

# Or run as root temporarily
docker compose run --rm --user root google-calendar-mcp sh
```

### Health Check Failing

```bash
# Manual health check
docker compose exec google-calendar-mcp bunx --bun @cocal/google-calendar-mcp version

# Check container logs
docker compose logs --tail 50 google-calendar-mcp

# Restart unhealthy container
docker compose restart google-calendar-mcp
```

## Performance Optimization

### Build Caching

Use BuildKit for faster builds:
```bash
DOCKER_BUILDKIT=1 docker compose build
```

### Multi-Architecture Support

Build for different platforms:
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t gcal-mcp:latest .
```

### Layer Optimization

The Dockerfile uses multi-stage builds to minimize image size:
- Base: Bun runtime (Alpine)
- Dependencies: Global package install
- Production: Minimal final image

Current image size: ~150MB (vs 1GB+ for Node-based)

## Migration from Direct Execution

If migrating from direct `bunx` execution:

1. Ensure credentials and tokens are in correct directories
2. Build container: `docker compose build`
3. Test authentication: `docker compose run --rm google-calendar-mcp auth`
4. Update `.mcp.json` to use docker command
5. Start service: `docker compose up -d`
6. Restart Claude Code

No re-authentication needed if tokens already exist.

## Production Deployment

For production environments:

1. **Use secrets management**:
   ```yaml
   secrets:
     google_credentials:
       file: ./credentials/credentials.json
   ```

2. **Enable monitoring**:
   - Integrate with Prometheus/Grafana
   - Export container metrics
   - Alert on health check failures

3. **Implement backup strategy**:
   - Automated token backups
   - Credential rotation policy
   - Disaster recovery plan

4. **Use orchestration** (Kubernetes/Docker Swarm):
   ```yaml
   deploy:
     replicas: 1
     restart_policy:
       condition: on-failure
       delay: 5s
       max_attempts: 3
   ```

## Podman Alternative

For rootless container execution with Podman:

```bash
# Build with Podman
podman-compose build

# Run service
podman-compose up -d

# Configure Claude Code
{
  "command": "podman",
  "args": ["exec", "-i", "gcal-mcp", "bunx", "--bun", "@cocal/google-calendar-mcp"]
}
```

Podman provides enhanced security through rootless operation.

## Next Steps

1. Review security configuration
2. Test authentication flow
3. Configure Claude Code connection
4. Set up monitoring and logging
5. Implement backup strategy

For non-containerized setup, see main `README.md`.
