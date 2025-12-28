# Google Calendar MCP Server Setup

## Overview
This directory contains the setup and configuration for the Google Calendar MCP server (`@cocal/google-calendar-mcp`), enabling Claude Code to manage Google Calendar events, schedules, and appointments.

## Bun Compatibility Assessment

### ✅ CONFIRMED: Fully Compatible with Bun

The `@cocal/google-calendar-mcp` package runs successfully with Bun:

- **Test Result**: `bunx --bun @cocal/google-calendar-mcp --help` works perfectly
- **Dependencies**: All dependencies are pure JavaScript/TypeScript with no Node-specific native bindings
- **MCP SDK**: `@modelcontextprotocol/sdk` is runtime-agnostic
- **Google APIs**: Standard HTTP-based libraries that work with any JavaScript runtime
- **Performance**: Bun's faster startup time improves MCP server initialization

### Dependencies Analysis
```json
{
  "@google-cloud/local-auth": "^3.0.1",      // Pure JS, OAuth flow
  "@modelcontextprotocol/sdk": "^1.12.1",   // Runtime agnostic
  "google-auth-library": "^9.15.0",         // HTTP-based auth
  "googleapis": "^144.0.0",                  // REST API client
  "open": "^7.4.2",                          // Browser launcher (cross-platform)
  "zod": "^3.22.4",                          // Pure JS schema validation
  "zod-to-json-schema": "^3.24.5"           // Pure JS converter
}
```

**No Node-specific dependencies detected** ✅

## Installation Options

### Option 1: Direct Bun Execution (Recommended for PAI)

This is the preferred method for PAI stack compliance:

1. Add to `.claude/.mcp.json`:
```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "bunx",
      "args": [
        "--bun",
        "@cocal/google-calendar-mcp"
      ],
      "env": {
        "GOOGLE_OAUTH_CREDENTIALS": "/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json"
      },
      "description": "Google Calendar management with event creation, search, and scheduling"
    }
  }
}
```

**Advantages**:
- No orphaned processes
- Lifecycle managed by Claude Code
- Fast Bun startup time
- Native PAI stack integration
- Automatic cleanup on session end

### Option 2: Docker Container (Best for Isolation)

For environments requiring strict process isolation or running on servers:

```bash
cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/docker
docker compose up -d  # Works with OrbStack, Docker Desktop, or Podman
```

**Note**: OrbStack is recommended for macOS (faster and lighter than Docker Desktop).

See `docker/DOCKER.md` for detailed container setup.

### Option 3: NPX Fallback

If Bun compatibility issues arise (unlikely):

```json
{
  "google-calendar": {
    "command": "npx",
    "args": [
      "@cocal/google-calendar-mcp"
    ],
    "env": {
      "GOOGLE_OAUTH_CREDENTIALS": "/absolute/path/to/credentials.json"
    }
  }
}
```

## Setup Process

### Step 1: Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google Calendar API:
   - Navigate to "APIs & Services" → "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

### Step 2: Create OAuth Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. Application type: **Desktop app**
4. Name: "Claude Code Calendar Access"
5. Download the JSON file
6. Save as: `/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json`

### Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" → "OAuth consent screen"
2. User type: **External** (for personal) or **Internal** (for workspace)
3. Add your email as a test user
4. Scopes required (automatically handled by package):
   - `https://www.googleapis.com/auth/calendar.events`
   - `https://www.googleapis.com/auth/calendar`

**Note**: Test mode allows 7-day token refresh. For production:
- Submit app for verification (if external users needed)
- Or keep in test mode for personal use (100 test users max)

### Step 4: Run Initial Authentication

```bash
# Using Bun (recommended)
bunx --bun @cocal/google-calendar-mcp auth

# Or with Docker
cd docker && docker compose run --rm gcal-mcp auth

# Multi-account support
bunx --bun @cocal/google-calendar-mcp auth work
bunx --bun @cocal/google-calendar-mcp auth personal
```

This will:
1. Open browser for Google OAuth consent
2. Save refresh token to `tokens/token.json`
3. Token auto-refreshes for 7 days in test mode

### Step 5: Add to MCP Configuration

Edit `/Users/donjacobsmeyer/PAI/.claude/.mcp.json` and add the server configuration (see Option 1 above).

### Step 6: Restart Claude Code

The MCP server will automatically start when Claude Code initializes.

## Security Considerations

### Credential Storage

- **credentials.json**: Contains OAuth client ID and secret
  - Sensitivity: Medium (public client credentials)
  - Location: `credentials/credentials.json`
  - Permissions: `chmod 600`

- **token.json**: Contains user refresh token and access token
  - Sensitivity: HIGH (grants calendar access)
  - Location: `tokens/token.json`
  - Permissions: `chmod 600`
  - Auto-generated after first auth

### Best Practices

1. **Never commit credentials to git**:
   ```bash
   echo "credentials/*.json" >> .gitignore
   echo "tokens/*.json" >> .gitignore
   ```

2. **Use absolute paths**: Required for MCP environment variables
   ```json
   "GOOGLE_OAUTH_CREDENTIALS": "/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json"
   ```

3. **Restrict file permissions**:
   ```bash
   chmod 600 credentials/credentials.json
   chmod 600 tokens/token.json
   ```

4. **Multi-account isolation**: Use account IDs for separate auth flows
   ```bash
   bunx @cocal/google-calendar-mcp auth work
   bunx @cocal/google-calendar-mcp auth personal
   ```

## Available MCP Tools

Once configured, Claude Code can use these tools:

- `calendar_create_event`: Create new calendar events
- `calendar_update_event`: Modify existing events
- `calendar_delete_event`: Remove events
- `calendar_list_events`: Search and filter events
- `calendar_get_event`: Get event details
- `calendar_quick_add`: Natural language event creation
- `calendar_list_calendars`: View available calendars
- `calendar_create_calendar`: Create new calendars
- `calendar_check_availability`: Find free/busy times

## Troubleshooting

### Authentication Errors

**Problem**: "Error loading credentials"
```bash
# Check file exists and path is absolute
ls -la /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json

# Verify JSON format
cat credentials/credentials.json | jq .
```

**Problem**: "Token expired or invalid"
```bash
# Re-authenticate
bunx --bun @cocal/google-calendar-mcp auth

# Or delete token and re-auth
rm tokens/token.json
bunx --bun @cocal/google-calendar-mcp auth
```

### Bun-Specific Issues

**Problem**: Package not found
```bash
# Clear Bun cache
bun pm cache rm @cocal/google-calendar-mcp

# Force reinstall
bunx --bun @cocal/google-calendar-mcp --version
```

**Problem**: Native module errors (unlikely but possible)
```bash
# Fallback to Node
npx @cocal/google-calendar-mcp auth
```

### MCP Server Not Appearing

1. Check `.mcp.json` syntax:
   ```bash
   cat /Users/donjacobsmeyer/PAI/.claude/.mcp.json | jq .
   ```

2. Verify environment variable:
   ```bash
   echo $GOOGLE_OAUTH_CREDENTIALS
   ```

3. Check Claude Code logs for MCP initialization errors

4. Restart Claude Code completely

### Permission Denied

```bash
# Fix file permissions
chmod 600 /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json
chmod 600 /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/tokens/token.json
chmod 755 /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar
```

## Testing the Installation

After setup, test with Claude Code:

1. Ask Claude: "List my calendar events for today"
2. Ask Claude: "Create a meeting tomorrow at 2pm for 1 hour"
3. Ask Claude: "When am I free tomorrow afternoon?"

## Version Information

- Package: `@cocal/google-calendar-mcp@2.2.0`
- Runtime: Bun 1.3.5 (tested and working)
- Platform: macOS Darwin 25.2.0
- Protocol: MCP 1.12.1+

## Migration from Node to Bun

If migrating from Node-based setup:

1. Keep existing `credentials.json` and `tokens/*.json`
2. Update `.mcp.json` to use `bunx` instead of `npx`
3. Add `--bun` flag to args
4. Restart Claude Code
5. No re-authentication needed (tokens remain valid)

## Support Resources

- GitHub: https://github.com/nspady/google-calendar-mcp
- Issues: https://github.com/nspady/google-calendar-mcp/issues
- MCP Docs: https://modelcontextprotocol.io/
- Google Calendar API: https://developers.google.com/calendar

## Next Steps

1. Complete Google Cloud Console setup
2. Download OAuth credentials
3. Run initial authentication
4. Add to `.mcp.json`
5. Restart Claude Code
6. Test with calendar queries

See `DOCKER.md` for containerized deployment guide.
