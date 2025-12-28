# Google Calendar MCP - Troubleshooting Guide

## Diagnostic Commands

Run these to diagnose issues:

```bash
cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar

# 1. Verify Bun installation
bun --version

# 2. Test package availability
bunx --bun @cocal/google-calendar-mcp version

# 3. Check credentials exist
ls -la credentials/credentials.json

# 4. Check tokens exist
ls -la tokens/token.json

# 5. Validate .mcp.json syntax
cat /Users/donjacobsmeyer/PAI/.claude/.mcp.json | jq .

# 6. Test authentication
bunx --bun @cocal/google-calendar-mcp auth

# 7. Check file permissions
ls -la credentials/ tokens/
```

## Error Categories

### 1. Authentication Errors

#### "Error loading credentials"

**Symptoms**: Server fails to start, credential file not found

**Causes**:
- File doesn't exist at specified path
- Relative path used instead of absolute
- Incorrect file permissions

**Solutions**:
```bash
# Verify file exists
ls -la /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json

# Check it's valid JSON
cat credentials/credentials.json | jq .

# Ensure absolute path in .mcp.json
grep GOOGLE_OAUTH_CREDENTIALS /Users/donjacobsmeyer/PAI/.claude/.mcp.json

# Fix permissions
chmod 600 credentials/credentials.json
```

#### "Invalid credentials.json format"

**Symptoms**: Authentication fails with format error

**Causes**:
- Wrong credential type downloaded
- Corrupted JSON file
- Service account credentials instead of OAuth

**Solutions**:
```bash
# Validate JSON structure
cat credentials/credentials.json | jq '.installed // .web'

# Should contain:
# - client_id
# - client_secret
# - redirect_uris
# - auth_uri
# - token_uri

# Re-download from Google Cloud Console
# Ensure "Desktop app" type, NOT "Web application" or "Service account"
```

#### "Token expired or invalid"

**Symptoms**: Calendar operations fail with 401/403 errors

**Causes**:
- Token refresh failed
- Token older than 7 days (test mode)
- Credentials revoked in Google Console

**Solutions**:
```bash
# Delete token and re-authenticate
rm tokens/token.json
bunx --bun @cocal/google-calendar-mcp auth

# Check token file exists after auth
ls -la tokens/token.json

# Verify OAuth consent screen has your email as test user
```

#### "Browser won't open for OAuth"

**Symptoms**: Auth command runs but no browser window

**Causes**:
- Running in headless environment
- Browser path not found
- SSH session without X11 forwarding

**Solutions**:
```bash
# For Docker: Use host browser
docker compose run --rm -e DISPLAY=$DISPLAY google-calendar-mcp auth

# For SSH: Enable X11 forwarding
ssh -X user@host

# Manual URL copy method (if available in package)
# Check package docs for manual auth URL
```

### 2. Configuration Errors

#### "MCP server not appearing in Claude Code"

**Symptoms**: Server not listed in available MCP tools

**Causes**:
- JSON syntax error in .mcp.json
- Server not enabled in settings
- Claude Code not restarted
- Environment variables not set

**Solutions**:
```bash
# Validate JSON syntax
cat /Users/donjacobsmeyer/PAI/.claude/.mcp.json | jq .

# Check enableAllProjectMcpServers is true
grep enableAllProjectMcpServers /Users/donjacobsmeyer/PAI/.claude/settings.json

# Verify server configuration
jq '.mcpServers["google-calendar"]' /Users/donjacobsmeyer/PAI/.claude/.mcp.json

# Restart Claude Code completely (Quit + Reopen)
```

#### "Environment variable not set"

**Symptoms**: Credentials path not found

**Causes**:
- Missing env block in .mcp.json
- Relative path instead of absolute
- Shell expansion in JSON (${HOME}, etc.)

**Solutions**:
```json
// CORRECT: Absolute path, no shell variables
{
  "env": {
    "GOOGLE_OAUTH_CREDENTIALS": "/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json"
  }
}

// WRONG: Relative path
{
  "env": {
    "GOOGLE_OAUTH_CREDENTIALS": "./credentials/credentials.json"
  }
}

// WRONG: Shell expansion (doesn't work in JSON)
{
  "env": {
    "GOOGLE_OAUTH_CREDENTIALS": "${HOME}/.claude/MCP/google-calendar/credentials/credentials.json"
  }
}
```

#### "Syntax error in .mcp.json"

**Symptoms**: All MCP servers fail to load

**Causes**:
- Missing comma in JSON
- Trailing comma before closing brace
- Unescaped quotes
- Comments in JSON (not allowed)

**Solutions**:
```bash
# Validate JSON
jq . /Users/donjacobsmeyer/PAI/.claude/.mcp.json

# If error, check line number and fix syntax
# Common issues:
# - Missing comma between server definitions
# - Extra comma after last item
# - Unmatched braces/brackets

# Backup before editing
cp /Users/donjacobsmeyer/PAI/.claude/.mcp.json /Users/donjacobsmeyer/PAI/.claude/.mcp.json.backup
```

### 3. Bun-Specific Issues

#### "bunx command not found"

**Symptoms**: Shell can't find bunx

**Causes**:
- Bun not installed
- Bun not in PATH
- Shell hasn't reloaded PATH

**Solutions**:
```bash
# Install Bun
curl -fsSL https://bun.sh/install | bash

# Add to PATH (if not automatic)
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
which bunx
bunx --version
```

#### "Package not found by Bun"

**Symptoms**: bunx can't resolve @cocal/google-calendar-mcp

**Causes**:
- NPM registry connection issue
- Package name typo
- Bun cache corruption

**Solutions**:
```bash
# Clear Bun cache
bun pm cache rm @cocal/google-calendar-mcp

# Force reinstall
bunx --bun @cocal/google-calendar-mcp version

# Test with npx as fallback
npx @cocal/google-calendar-mcp version

# Check NPM registry
npm view @cocal/google-calendar-mcp version
```

#### "Native module compatibility error"

**Symptoms**: Error about C++ bindings or native modules

**Causes**:
- Rare: Some dependency has Node-specific native module
- Usually shouldn't happen with this package

**Solutions**:
```bash
# Fallback to Node
npx @cocal/google-calendar-mcp version

# Update .mcp.json to use npx instead of bunx
{
  "command": "npx",
  "args": ["@cocal/google-calendar-mcp"]
}

# Report issue to package maintainer
```

### 4. Docker-Specific Issues

#### "Container won't start"

**Symptoms**: docker compose up fails

**Causes**:
- Docker not running
- Build failed
- Port conflicts
- Volume mount permissions

**Solutions**:
```bash
# Check Docker is running
docker info

# Rebuild container
docker compose build --no-cache

# Check logs
docker compose logs google-calendar-mcp

# Test manual run
docker compose run --rm google-calendar-mcp version
```

#### "Permission denied in container"

**Symptoms**: Can't read credentials or write tokens

**Causes**:
- File ownership mismatch
- Incorrect volume permissions
- SELinux blocking access

**Solutions**:
```bash
# Fix ownership (host)
chown -R 1001:1001 credentials/ tokens/

# Set permissions (host)
chmod 755 credentials/ tokens/
chmod 600 credentials/credentials.json

# Test with root (debugging only)
docker compose run --rm --user root google-calendar-mcp ls -la /app/credentials

# Check SELinux (if on Linux)
ls -Z credentials/
# Add :z or :Z to volume mounts if needed
```

#### "Network timeout during auth"

**Symptoms**: OAuth flow can't reach Google

**Causes**:
- Container network mode is 'none'
- Firewall blocking
- DNS resolution failure

**Solutions**:
```bash
# Ensure bridge mode for auth
grep network_mode docker-compose.yml
# Should be: network_mode: bridge

# Test DNS
docker compose run --rm google-calendar-mcp ping -c 3 google.com

# Test HTTPS
docker compose run --rm google-calendar-mcp wget -O- https://accounts.google.com
```

#### "Health check failing"

**Symptoms**: Container marked unhealthy

**Causes**:
- Version command failing
- Container can't run bunx
- Resource constraints

**Solutions**:
```bash
# Manual health check
docker compose exec google-calendar-mcp bunx --bun @cocal/google-calendar-mcp version

# Check resource usage
docker stats gcal-mcp

# View health check logs
docker inspect gcal-mcp | jq '.[0].State.Health'

# Restart container
docker compose restart google-calendar-mcp
```

### 5. Runtime Errors

#### "Calendar API not enabled"

**Symptoms**: 403 errors when accessing calendar

**Causes**:
- Google Calendar API not enabled in project
- Wrong project selected

**Solutions**:
1. Go to: https://console.cloud.google.com/
2. Select correct project
3. APIs & Services → Library
4. Search "Google Calendar API"
5. Click "Enable"

#### "Access not granted"

**Symptoms**: Insufficient permissions errors

**Causes**:
- Didn't grant all scopes during OAuth
- Scopes changed in code
- Consent screen not configured

**Solutions**:
```bash
# Re-authenticate with all scopes
rm tokens/token.json
bunx --bun @cocal/google-calendar-mcp auth

# Verify scopes in OAuth consent screen
# Required scopes:
# - https://www.googleapis.com/auth/calendar.events
# - https://www.googleapis.com/auth/calendar
```

#### "Rate limit exceeded"

**Symptoms**: 429 errors from Google API

**Causes**:
- Too many requests
- Quota exceeded
- Default quota limits

**Solutions**:
1. Check quotas: https://console.cloud.google.com/apis/api/calendar-json.googleapis.com/quotas
2. Request quota increase if needed
3. Implement request throttling
4. Wait for quota reset (usually per minute/day)

### 6. File System Issues

#### "No such file or directory"

**Symptoms**: Credentials or token path not found

**Causes**:
- Directory doesn't exist
- Typo in path
- Incorrect working directory

**Solutions**:
```bash
# Create directories
mkdir -p /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/{credentials,tokens}

# Verify paths
ls -la /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/

# Use absolute paths everywhere
pwd  # Check current directory
```

#### "Permission denied"

**Symptoms**: Can't read/write files

**Causes**:
- Incorrect file permissions
- Wrong ownership
- Directory not writable

**Solutions**:
```bash
# Fix file permissions
chmod 600 credentials/credentials.json
chmod 600 tokens/token.json
chmod 755 credentials/ tokens/

# Fix ownership
chown -R $(whoami):$(id -gn) credentials/ tokens/

# Verify
ls -la credentials/ tokens/
```

## Debugging Workflow

### Step 1: Isolate the Issue

```bash
# Test package directly (bypasses Claude Code)
bunx --bun @cocal/google-calendar-mcp version

# Test authentication
bunx --bun @cocal/google-calendar-mcp auth

# Test with environment variable
GOOGLE_OAUTH_CREDENTIALS=/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json \
  bunx --bun @cocal/google-calendar-mcp version
```

### Step 2: Check Dependencies

```bash
# Bun version
bun --version  # Should be 1.3.5+

# Docker version (if using containers)
docker --version  # Should be 28.5.2+

# Package version
npm view @cocal/google-calendar-mcp version  # Should be 2.2.0
```

### Step 3: Validate Configuration

```bash
# JSON syntax
jq . /Users/donjacobsmeyer/PAI/.claude/.mcp.json

# Environment variables
jq '.mcpServers["google-calendar"].env' /Users/donjacobsmeyer/PAI/.claude/.mcp.json

# File existence
test -f /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json && echo "EXISTS" || echo "MISSING"
```

### Step 4: Test Components

```bash
# 1. Test Bun execution
bunx --bun @cocal/google-calendar-mcp version

# 2. Test with credentials
GOOGLE_OAUTH_CREDENTIALS=/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json \
  bunx --bun @cocal/google-calendar-mcp auth

# 3. Test full startup
GOOGLE_OAUTH_CREDENTIALS=/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json \
  bunx --bun @cocal/google-calendar-mcp start
```

### Step 5: Check Logs

```bash
# Claude Code logs (if available)
# Location varies by installation

# Docker logs
docker compose logs -f google-calendar-mcp

# System logs
# macOS: Console.app or log stream
```

## Clean Reinstall

If all else fails:

```bash
cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar

# 1. Backup credentials and tokens
cp credentials/credentials.json ~/credentials-backup.json
cp tokens/token.json ~/tokens-backup.json 2>/dev/null || true

# 2. Clear Bun cache
bun pm cache rm @cocal/google-calendar-mcp

# 3. Remove tokens (will need to re-auth)
rm -f tokens/token.json

# 4. Test fresh install
bunx --bun @cocal/google-calendar-mcp version

# 5. Re-authenticate
bunx --bun @cocal/google-calendar-mcp auth

# 6. Restart Claude Code

# 7. Restore credentials if needed
cp ~/credentials-backup.json credentials/credentials.json
cp ~/tokens-backup.json tokens/token.json 2>/dev/null || true
```

## Getting Help

If issues persist:

1. **Check package repository**: https://github.com/nspady/google-calendar-mcp/issues
2. **Search existing issues**: Your problem may already be documented
3. **Create detailed bug report**:
   - Bun version: `bun --version`
   - Package version: `bunx @cocal/google-calendar-mcp version`
   - OS: `uname -a`
   - Error messages: Full stack trace
   - Configuration: Sanitized .mcp.json excerpt

4. **PAI-specific support**: Check PAI documentation and community

## Prevention Checklist

- [ ] Always use absolute paths in configuration
- [ ] Validate JSON syntax before saving
- [ ] Set proper file permissions (600 for credentials/tokens)
- [ ] Keep credentials out of version control
- [ ] Restart Claude Code after configuration changes
- [ ] Test authentication after credential changes
- [ ] Monitor token expiration (7 days in test mode)
- [ ] Keep package updated: `bunx @cocal/google-calendar-mcp@latest`
