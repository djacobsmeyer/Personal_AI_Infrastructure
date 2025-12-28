# Google Calendar MCP - Quick Start Guide

## 5-Minute Setup

### Step 1: Get OAuth Credentials (2 minutes)

1. Go to: https://console.cloud.google.com/
2. Create/select project
3. Enable Google Calendar API:
   - APIs & Services → Library → "Google Calendar API" → Enable
4. Create credentials:
   - Credentials → Create → OAuth client ID
   - Application type: **Desktop app**
   - Download JSON
5. Save to: `/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json`

### Step 2: Configure OAuth Consent (1 minute)

1. OAuth consent screen → External
2. Add your email as test user
3. Save

### Step 3: Authenticate (1 minute)

```bash
cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar

# Using Bun (recommended)
bunx --bun @cocal/google-calendar-mcp auth

# Or with Docker
cd docker && docker compose run --rm google-calendar-mcp auth
```

Browser will open → Allow permissions → Token saved to `tokens/token.json`

### Step 4: Add to Claude Code (1 minute)

Edit `/Users/donjacobsmeyer/PAI/.claude/.mcp.json` and add:

```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "bunx",
      "args": ["--bun", "@cocal/google-calendar-mcp"],
      "env": {
        "GOOGLE_OAUTH_CREDENTIALS": "/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json"
      },
      "description": "Google Calendar management"
    }
  }
}
```

**Note**: If you already have other MCP servers, just add the `"google-calendar"` block inside `"mcpServers"`.

### Step 5: Restart Claude Code

Quit and restart Claude Code completely.

### Step 6: Test

Ask Claude:
- "List my calendar events for today"
- "Create a meeting tomorrow at 2pm"
- "When am I free on Friday?"

## Verification Checklist

- [ ] credentials.json exists in credentials/
- [ ] OAuth consent screen configured with test user
- [ ] Authentication completed (token.json exists in tokens/)
- [ ] .mcp.json updated with correct absolute paths
- [ ] Claude Code restarted
- [ ] Calendar queries work in Claude Code

## Common Issues

### "Credentials not found"
→ Ensure absolute path in .mcp.json:
```json
"GOOGLE_OAUTH_CREDENTIALS": "/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json"
```

### "Token expired"
→ Re-authenticate:
```bash
bunx --bun @cocal/google-calendar-mcp auth
```

### "Permission denied"
→ Fix file permissions:
```bash
chmod 600 credentials/credentials.json
chmod 600 tokens/token.json
```

### MCP server not appearing
→ Validate JSON syntax:
```bash
cat /Users/donjacobsmeyer/PAI/.claude/.mcp.json | jq .
```

## Next Steps

- See `README.md` for detailed documentation
- See `DOCKER.md` for containerized deployment
- See `.mcp-config-template.json` for advanced configurations

## Bun vs Node

✅ **Bun is fully compatible and recommended**:
- Faster startup time
- Native PAI stack alignment
- All dependencies are pure JavaScript
- No Node-specific APIs required

Use `bunx --bun` instead of `npx` for optimal performance.

## Multi-Account Setup

For separate work/personal calendars:

```bash
# Authenticate each account
bunx --bun @cocal/google-calendar-mcp auth work
bunx --bun @cocal/google-calendar-mcp auth personal

# Add separate MCP servers in .mcp.json
```

See `.mcp-config-template.json` option 4 for configuration.

## Security Notes

- Never commit credentials.json or token.json to git
- Use absolute paths in environment variables
- Set file permissions: `chmod 600` on sensitive files
- Tokens auto-refresh for 7 days (test mode)

## Support

- Full docs: `README.md`
- Docker setup: `docker/DOCKER.md`
- GitHub: https://github.com/nspady/google-calendar-mcp/issues
