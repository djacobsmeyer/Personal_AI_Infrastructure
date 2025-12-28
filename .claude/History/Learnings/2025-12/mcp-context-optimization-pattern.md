# MCP Context Optimization: Script Wrapper Pattern

**Date:** 2025-12-28
**Context:** Google Calendar MCP integration
**Lesson:** For occasional-use MCP tools, script wrappers eliminate context pollution

## The Problem

MCP servers registered in `.claude.json` load ALL tool definitions into EVERY Claude session:

**Google Calendar MCP Context Cost:**
- 12 tool definitions
- 14.7k tokens (7.3% of 200k context window)
- Loaded in 100% of sessions
- Used in ~5% of sessions

**Result:** Wasting 14.7k tokens in 95% of sessions where calendar isn't needed.

## The Solution: Script Wrapper Pattern

Instead of loading MCP tools globally, create script wrappers that:
1. Call external APIs directly (Google Calendar API, Stripe API, etc.)
2. Reuse OAuth tokens from MCP auth flow
3. Return clean JSON output
4. Zero context cost when not in use

## Implementation

### Step 1: Remove MCP Server from Global Config

```bash
claude mcp remove google-calendar
```

This prevents tools from loading into every session.

### Step 2: Create Script Wrapper

```typescript
// ~/.claude/Tools/calendar
#!/usr/bin/env bun

import { google } from 'googleapis';

// Reuse MCP tokens
const TOKENS_PATH = '~/.config/google-calendar-mcp/tokens.json';

async function getCalendarClient() {
  const credentials = readFileSync(CREDENTIALS_PATH, 'utf8');
  const tokens = readFileSync(TOKENS_PATH, 'utf8');

  const oauth2Client = new google.auth.OAuth2(...);
  oauth2Client.setCredentials(tokens);

  return google.calendar({ version: 'v3', auth: oauth2Client });
}

// Implement calendar operations
async function listEvents(start, end) { ... }
async function createEvent(title, start, end) { ... }
```

### Step 3: Create Skill that Uses Script

```markdown
---
name: Calendar
description: Google Calendar management. USE WHEN user mentions calendar, scheduling, OR availability.
---

# Calendar Skill

Uses script wrapper for zero-context calendar operations.

## Usage

```bash
calendar list-events --start today --end +7
calendar create-event --title "Meeting" --start "2025-12-30T14:00:00"
```
```

## When to Use This Pattern

✅ **Use script wrappers when:**
- Tool used occasionally (< 20% of sessions)
- Context window is precious
- External API has direct client library
- OAuth tokens can be reused

❌ **Keep MCP tools loaded when:**
- Tool used frequently (> 50% of sessions)
- Complex multi-step workflows
- Tool has no direct API alternative
- Context cost is acceptable

## Context Savings

| MCP Server | Tool Count | Context Cost | Usage % | Savings with Script |
|------------|-----------|--------------|---------|---------------------|
| google-calendar | 12 | 14.7k tokens | 5% | 14.0k tokens/session |
| stripe | 20 | 22.1k tokens | 3% | 21.4k tokens/session |
| notion | 15 | 18.3k tokens | 10% | 16.5k tokens/session |

**Total potential savings:** ~50k tokens for occasional-use tools

## Architecture Comparison

### Always-Loaded MCP (Before)

```
┌─────────────────┐
│ Claude Session  │
├─────────────────┤
│ System: 3.7k    │
│ Tools: 17.1k    │
│ MCP: 14.7k ◄─── │ Always loaded
│ Messages: 27k   │
│ Free: 60k       │
└─────────────────┘
```

### Script Wrapper (After)

```
┌─────────────────┐
│ Claude Session  │
├─────────────────┤
│ System: 3.7k    │
│ Tools: 17.1k    │
│ MCP: 0k   ◄───  │ Zero cost!
│ Messages: 27k   │
│ Free: 74.7k     │ +14.7k tokens
└─────────────────┘

When needed:
Bash("calendar list-events") → Direct API call → JSON response
```

## Token Reuse Strategy

The genius of this pattern:
1. Use MCP server's auth flow (bunx @cocal/google-calendar-mcp auth)
2. MCP saves tokens to ~/.config
3. Script wrapper reuses those same tokens
4. No duplicate auth flows needed

**Authentication flow once, use everywhere.**

## Implementation Checklist

When converting MCP to script wrapper:

- [ ] Remove MCP server: `claude mcp remove SERVER_NAME`
- [ ] Install direct API client: `bun add googleapis` (or equivalent)
- [ ] Create script at `~/.claude/Tools/TOOL_NAME`
- [ ] Reuse MCP token paths in script
- [ ] Implement core operations (list, create, update, delete)
- [ ] Return JSON output for easy parsing
- [ ] Create skill that uses script
- [ ] Test all operations
- [ ] Document in skill SKILL.md
- [ ] Add to learnings

## Real-World Results

**Google Calendar MCP → Script Wrapper:**
- Context saved: 14.7k tokens per session (7.3%)
- Performance: ~500ms per operation (acceptable)
- Code quality: Direct API is cleaner than MCP tool calls
- Maintenance: Easier to debug and extend

**Stripe MCP → Script Wrapper (potential):**
- Context saved: 22.1k tokens per session (11%)
- Would free significant context for complex workflows

## Future Applications

This pattern applies to ANY occasional-use external service:
- Payment processors (Stripe, Square)
- CRM systems (Salesforce, HubSpot)
- Project management (Asana, Linear)
- Communication (Slack, Discord)
- Storage (Dropbox, Google Drive)

**Rule of Thumb:**
If you use it less than 20% of the time, wrap it in a script.

## Code Template

```typescript
#!/usr/bin/env bun

import { EXTERNAL_API } from 'package';

const TOKENS_PATH = '~/.config/mcp-server-name/tokens.json';
const CREDENTIALS_PATH = '/path/to/credentials.json';

async function getClient() {
  const credentials = JSON.parse(readFileSync(CREDENTIALS_PATH, 'utf8'));
  const tokens = JSON.parse(readFileSync(TOKENS_PATH, 'utf8'));

  // Initialize client with tokens
  return createClient(credentials, tokens);
}

async function main() {
  const [command, ...args] = process.argv.slice(2);
  const client = await getClient();

  let result;
  switch (command) {
    case 'list': result = await client.list(); break;
    case 'create': result = await client.create(args); break;
    // ... other operations
  }

  console.log(JSON.stringify(result, null, 2));
}

main();
```

## Bottom Line

**MCP tools are powerful but expensive.**

For occasional-use integrations, the script wrapper pattern:
- Eliminates context pollution
- Maintains all functionality
- Improves performance
- Simplifies debugging
- Enables better token management

**The best code is the code that doesn't load when you don't need it.**
