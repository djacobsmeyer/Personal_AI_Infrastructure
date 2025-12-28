---
name: Calendar
description: Google Calendar management for scheduling, availability checks, and event coordination. USE WHEN user mentions calendar operations, schedule checks, meeting planning, availability queries, event creation, OR asks about their schedule.
---

# Calendar - Google Calendar Management

Manages calendar operations using on-demand script wrapper (zero context cost when not in use).

## Core Capabilities

- **List Events:** View scheduled events for any date range
- **Create Events:** Schedule new meetings and appointments
- **Search Events:** Find events by keyword or description
- **Check Conflicts:** Verify time slot availability
- **Get Availability:** Find free time windows
- **Delete Events:** Remove calendar entries

## Architecture

**Context Protection Strategy:**
- Calendar script wrapper (`~/.claude/Tools/calendar`) spawns ephemeral Claude session
- MCP tools load ONLY in that session (not primary)
- Returns clean JSON output
- Session terminates - zero context pollution
- **Saves ~14.7k tokens (7.3% of context) per session**

## Usage

### List Events

```bash
calendar list-events --start "2025-12-28" --end "2026-01-04"
calendar list-events --start "today" --end "next week" --calendar "work@company.com"
```

### Create Event

```bash
calendar create-event \
  --title "Team Meeting" \
  --start "2025-12-30T14:00:00" \
  --end "2025-12-30T15:00:00" \
  --location "Conference Room A" \
  --description "Q1 planning discussion"
```

### Search Events

```bash
calendar search-events \
  --query "standup" \
  --start "2025-12-01" \
  --end "2025-12-31"
```

### Check Conflicts

```bash
calendar check-conflicts \
  --start "2025-12-30T14:00:00" \
  --end "2025-12-30T15:00:00"
```

### Get Availability

```bash
calendar get-availability --date "2025-12-30"
```

### List Calendars

```bash
calendar list-calendars
```

### Delete Event

```bash
calendar delete-event --event-id "abc123xyz" --calendar "primary"
```

## Response Format

All commands return JSON:

```json
{
  "success": true,
  "data": { /* event or calendar data */ },
  "message": "Operation completed successfully"
}
```

## Common Workflows

### Check Schedule for Week

```typescript
// User: "What's on my calendar this week?"
const result = await Bash({
  command: 'calendar list-events --start "today" --end "+7 days"'
});

// Parse JSON and summarize:
// "You have 3 meetings this week: Team standup Mon 9am, 1-on-1 Wed 2pm, Sprint review Fri 3pm"
```

### Schedule Meeting with Conflict Check

```typescript
// User: "Schedule a meeting Tuesday at 2pm"
// 1. Check conflicts first
const conflicts = await Bash({
  command: 'calendar check-conflicts --start "2025-12-31T14:00:00" --end "2025-12-31T15:00:00"'
});

// 2. If clear, create event
if (!conflicts.hasConflicts) {
  const event = await Bash({
    command: 'calendar create-event --title "Meeting" --start "2025-12-31T14:00:00" --end "2025-12-31T15:00:00"'
  });
}
```

### Find Next Available Slot

```typescript
// User: "When am I free tomorrow?"
const availability = await Bash({
  command: 'calendar get-availability --date "tomorrow"'
});

// Return: "Available slots: 10am-12pm, 2pm-4pm"
```

## Integration with Other Skills

- **Research Skill:** Schedule time to review research findings
- **Observability:** Track when events are created/modified
- **Fabric Workflows:** Extract wisdom from meeting notes and schedule follow-ups

## Configuration

Calendar script uses credentials at:
```
/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json
```

Tokens stored at:
```
~/.config/google-calendar-mcp/tokens.json
```

## Troubleshooting

### "Authentication failed"
Re-authenticate:
```bash
cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar
GOOGLE_OAUTH_CREDENTIALS="/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json" \
  bunx --bun @cocal/google-calendar-mcp auth
```

### "Calendar not found"
List available calendars:
```bash
calendar list-calendars
```

### Script permission denied
```bash
chmod +x ~/.claude/Tools/calendar
```

## Best Practices

1. **Always check conflicts** before creating events
2. **Use relative dates** when possible ("today", "tomorrow", "next week")
3. **Include timezone** for cross-timezone scheduling
4. **Parse JSON responses** for structured data processing
5. **Provide context** when creating events (location, description, attendees)

## Future Enhancements

- [ ] Recurring event support
- [ ] Attendee management
- [ ] Calendar sharing operations
- [ ] Event reminders configuration
- [ ] Google Meet link generation
- [ ] Multi-calendar coordination

## Example Session

```
User: "What's on my calendar this week?"
PAI: *Runs: calendar list-events --start today --end +7*
PAI: "Your calendar is clear this week - no events scheduled."

User: "Schedule a meeting with the team on Monday at 2pm"
PAI: *Runs: calendar check-conflicts --start "2025-12-30T14:00:00" --end "2025-12-30T15:00:00"*
PAI: *No conflicts found*
PAI: *Runs: calendar create-event --title "Team Meeting" --start "2025-12-30T14:00:00" --end "2025-12-30T15:00:00"*
PAI: "Meeting scheduled for Monday, December 30th at 2pm."

User: "When am I free tomorrow?"
PAI: *Runs: calendar get-availability --date tomorrow*
PAI: "You have the following free slots tomorrow: 8am-12pm, 2pm-6pm"
```

## Implementation Notes

**Direct API Access:**
- Uses Google Calendar API v3 directly (googleapis package)
- Reuses OAuth tokens from google-calendar-mcp authentication
- No MCP context overhead
- Pure TypeScript/Bun implementation

**Token Management:**
- Tokens: `~/.config/google-calendar-mcp/tokens.json`
- Credentials: `/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json`
- Automatic token refresh handled by googleapis library

**Date Parsing:**
- Relative dates: `today`, `tomorrow`, `+7` (7 days from now)
- Absolute dates: `2025-12-30`
- ISO timestamps: `2025-12-30T14:00:00`

## Context Impact

**Before (MCP tools always loaded):**
- MCP tools: 14.7k tokens (7.3%)
- Loaded in EVERY session
- 12 tool definitions always present

**After (Script-based approach):**
- MCP tools: 0 tokens (0%)
- Only loads when calendar operations needed
- **Saves 14.7k tokens per session**

## Performance

- Script startup: ~200ms (Bun cold start)
- API call latency: ~300-500ms (Google Calendar API)
- Total operation time: ~500-700ms
- Acceptable for occasional calendar operations

## Security

- OAuth tokens stored securely in `~/.config`
- Credentials file in PAI private directory
- Never commit tokens or credentials to git
- Script uses read-only access to token files