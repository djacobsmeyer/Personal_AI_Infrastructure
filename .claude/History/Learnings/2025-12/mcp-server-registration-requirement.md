# MCP Server Registration: The .claude.json Requirement

**Date:** 2025-12-28
**Context:** Google Calendar MCP server setup
**Lesson:** MCP servers must be registered via CLI, not just .mcp.json files

## The Problem

We configured the Google Calendar MCP server in:
- `/Users/donjacobsmeyer/PAI/.claude/.mcp.json`
- `/Users/donjacobsmeyer/.claude/.mcp.json`

Settings had `enableAllProjectMcpServers: true`, suggesting `.mcp.json` files would be auto-loaded.

**But the server tools were never available in Claude Code sessions.**

## The Root Cause

Claude Code **requires** MCP servers to be registered in `/Users/donjacobsmeyer/.claude.json` using the `claude mcp` CLI command.

The `.mcp.json` files are **NOT** automatically picked up, despite the `enableAllProjectMcpServers` setting.

## The Solution

**Always use `claude mcp add` to register MCP servers:**

```bash
# For stdio servers (most common)
claude mcp add --transport stdio SERVER_NAME \
  --env VAR1=value1 \
  --env VAR2=value2 \
  -- command args...

# Example: Google Calendar
claude mcp add --transport stdio google-calendar \
  --env GOOGLE_OAUTH_CREDENTIALS=/path/to/credentials.json \
  -- bunx --bun @cocal/google-calendar-mcp

# For HTTP servers
claude mcp add --transport http SERVER_NAME https://url

# For SSE servers
claude mcp add --transport sse SERVER_NAME https://url
```

## Verification Steps

After adding an MCP server:

1. **Check registration:**
   ```bash
   claude mcp list
   ```
   Should show: `✓ Connected`

2. **View details:**
   ```bash
   claude mcp get SERVER_NAME
   ```

3. **Restart Claude Code** - Required for tools to become available

4. **Test in session** - Try using `mcp__server_name__tool_name` tools

## Key Diagnostic Commands

```bash
# List all configured servers
claude mcp list

# Get specific server details
claude mcp get SERVER_NAME

# Remove a server if misconfigured
claude mcp remove SERVER_NAME

# Check what file was modified
# Look for: "File modified: /Users/donjacobsmeyer/.claude.json"
```

## Authentication for OAuth-Based MCP Servers

For servers like Google Calendar that need OAuth:

1. **Set credentials path** when adding server (via `--env`)
2. **Run auth flow** with credentials path set:
   ```bash
   GOOGLE_OAUTH_CREDENTIALS=/path/to/credentials.json \
     bunx --bun @cocal/google-calendar-mcp auth
   ```
3. **Tokens auto-save** to `~/.config/google-calendar-mcp/tokens.json` (default)
4. **Server auto-loads** tokens from default location on startup

## What Doesn't Work

❌ **Just editing `.mcp.json` files** - Won't be detected by Claude Code
❌ **Relying on `enableAllProjectMcpServers`** - Setting doesn't work as expected
❌ **Manual edits to `.claude.json`** - Use CLI instead to ensure correct format

## What Does Work

✅ **Using `claude mcp add` command** - Registers server properly
✅ **Restarting Claude Code after adding** - Makes tools available
✅ **Verifying with `claude mcp list`** - Confirms connection status

## Future MCP Server Setup Checklist

When adding ANY new MCP server:

- [ ] Install the MCP server package (if needed)
- [ ] Set up credentials/API keys (if needed)
- [ ] Run authentication flow (if OAuth-based)
- [ ] **Use `claude mcp add` to register the server**
- [ ] Verify with `claude mcp list` (should show ✓ Connected)
- [ ] Restart Claude Code
- [ ] Test tools in a session

## Related Files

- **Actual config:** `/Users/donjacobsmeyer/.claude.json` (this is what matters)
- **Settings:** `/Users/donjacobsmeyer/.claude/settings.json` (general settings)
- **Documentation MCP files:** `.mcp.json` files (ignored by Claude Code)

## Bottom Line

**The `.mcp.json` files are documentation/reference, not configuration.**

**The `claude mcp add` command is the ONLY way to properly register MCP servers.**

Always use the CLI. Always verify. Always restart.
