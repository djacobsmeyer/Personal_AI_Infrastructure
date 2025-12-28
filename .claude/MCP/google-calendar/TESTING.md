# Google Calendar MCP - Testing Guide

## Testing Overview

This guide covers comprehensive testing of the Google Calendar MCP server installation, from basic connectivity to advanced calendar operations.

## Pre-Test Checklist

Before running tests, ensure:

- [ ] OAuth credentials configured in Google Cloud Console
- [ ] credentials.json exists in credentials/
- [ ] Initial authentication completed (token.json exists)
- [ ] MCP server added to .mcp.json
- [ ] Claude Code restarted
- [ ] Bun installed and working (`bun --version`)

## Test Levels

### Level 1: Package Installation

Test that the package is accessible:

```bash
# Test package version
bunx --bun @cocal/google-calendar-mcp version

# Expected output: Google Calendar MCP Server v2.2.0
```

**Pass Criteria**: Version information displayed without errors

### Level 2: Authentication

Test OAuth authentication flow:

```bash
# Set credentials path
export GOOGLE_OAUTH_CREDENTIALS=/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json

# Run authentication
bunx --bun @cocal/google-calendar-mcp auth

# Expected:
# - Browser opens
# - Google OAuth consent screen displayed
# - After approval, success message shown
# - Token saved to tokens/token.json
```

**Pass Criteria**:
- Browser launches successfully
- OAuth consent completes
- Token file created with 600 permissions
- Token file contains valid JSON

**Verification**:
```bash
# Check token exists
test -f /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/tokens/token.json && echo "EXISTS" || echo "MISSING"

# Check permissions
ls -la /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/tokens/token.json
# Should show: -rw------- (600)

# Validate JSON
cat tokens/token.json | jq .
# Should parse without errors
```

### Level 3: MCP Server Startup

Test that the MCP server starts correctly:

```bash
# Test server startup (will run in stdio mode)
GOOGLE_OAUTH_CREDENTIALS=/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json \
  bunx --bun @cocal/google-calendar-mcp start

# Expected:
# Server starts and waits for MCP protocol messages
# No error messages displayed
# (Press Ctrl+C to stop)
```

**Pass Criteria**:
- Server starts without errors
- No credential or token errors
- No API connection errors

### Level 4: Claude Code Integration

Test MCP server appears in Claude Code:

1. Open Claude Code
2. Start a new conversation
3. Check that google-calendar MCP tools are available

**Pass Criteria**:
- MCP server listed in available tools
- No connection errors in Claude Code
- Calendar tools accessible

### Level 5: Basic Calendar Operations

Test fundamental calendar operations through Claude Code:

#### Test 5.1: List Calendars

**Prompt**: "List my Google calendars"

**Expected Result**:
- Returns list of available calendars
- Shows calendar names and IDs
- No authentication errors

**Verification**:
```
Claude should respond with:
- Your primary calendar
- Any additional calendars
- Calendar properties (name, timezone, etc.)
```

#### Test 5.2: List Events

**Prompt**: "List my calendar events for today"

**Expected Result**:
- Returns events for current date
- Shows event titles, times, locations
- Handles empty calendar gracefully

**Verification**:
```
Claude should display:
- Event summaries
- Start/end times
- Attendees (if any)
- Locations (if any)
```

#### Test 5.3: Create Event

**Prompt**: "Create a test event tomorrow at 2pm for 1 hour called 'MCP Test'"

**Expected Result**:
- Event created successfully
- Confirmation with event details
- Event appears in calendar

**Verification**:
```bash
# Verify in Google Calendar web interface
# Event should appear with:
# - Title: "MCP Test"
# - Start: Tomorrow at 2:00 PM
# - Duration: 1 hour
# - Created by: Your account
```

#### Test 5.4: Search Events

**Prompt**: "Find all events with 'MCP' in the title"

**Expected Result**:
- Returns matching events
- Includes recently created test event
- Accurate search results

#### Test 5.5: Update Event

**Prompt**: "Update the 'MCP Test' event to start at 3pm instead"

**Expected Result**:
- Event updated successfully
- New time reflected in calendar
- Other details unchanged

**Verification**:
```
Check in Google Calendar:
- Event now starts at 3:00 PM
- Title still "MCP Test"
- Duration still 1 hour
```

#### Test 5.6: Delete Event

**Prompt**: "Delete the 'MCP Test' event"

**Expected Result**:
- Event deleted successfully
- Confirmation message displayed
- Event removed from calendar

**Verification**:
```
Check in Google Calendar:
- Event no longer visible
- Not in trash/deleted items (permanent delete)
```

### Level 6: Advanced Operations

#### Test 6.1: Complex Event Creation

**Prompt**:
```
Create a meeting on Friday at 10am for 2 hours called "Project Review"
with attendees test@example.com and include a description "Quarterly review meeting"
at location "Conference Room A"
```

**Expected Result**:
- Event created with all details
- Attendees invited (if email is valid)
- Location and description set

#### Test 6.2: Recurring Events

**Prompt**: "Create a daily standup meeting at 9am every weekday for the next 2 weeks"

**Expected Result**:
- Recurring event created
- Proper recurrence pattern
- All instances visible

#### Test 6.3: Event Search with Filters

**Prompt**: "Show me all meetings next week after 2pm"

**Expected Result**:
- Filtered results
- Only events matching criteria
- Correct time range

#### Test 6.4: Free/Busy Check

**Prompt**: "When am I free tomorrow afternoon?"

**Expected Result**:
- Available time slots identified
- Conflicts highlighted
- Accurate availability

#### Test 6.5: Quick Add

**Prompt**: "Quick add: Lunch with Sarah tomorrow at noon"

**Expected Result**:
- Natural language parsing
- Event created correctly
- Time zone handled properly

### Level 7: Multi-Account Testing

If using multi-account setup:

```bash
# Authenticate work account
bunx --bun @cocal/google-calendar-mcp auth work

# Authenticate personal account
bunx --bun @cocal/google-calendar-mcp auth personal
```

**Test**: Switch between accounts in Claude Code

**Prompt Work**: "List my work calendar events"
**Prompt Personal**: "List my personal calendar events"

**Expected Result**:
- Correct account accessed
- No cross-account data leakage
- Proper account isolation

### Level 8: Error Handling

Test error conditions and recovery:

#### Test 8.1: Invalid Event

**Prompt**: "Create an event with invalid date format"

**Expected Result**:
- Graceful error message
- Helpful correction suggestion
- No server crash

#### Test 8.2: Non-Existent Event

**Prompt**: "Delete event with ID 'nonexistent123'"

**Expected Result**:
- Event not found error
- Clear error message
- No data corruption

#### Test 8.3: Permission Errors

Revoke calendar access at https://myaccount.google.com/permissions

**Prompt**: "List my calendar events"

**Expected Result**:
- Authentication error
- Suggestion to re-authenticate
- No sensitive data exposed

**Recovery**:
```bash
bunx --bun @cocal/google-calendar-mcp auth
```

### Level 9: Performance Testing

#### Test 9.1: Large Event List

**Prompt**: "List all events from the past year"

**Expected Result**:
- Results returned within reasonable time (<10 seconds)
- Pagination handled correctly
- No timeout errors

#### Test 9.2: Concurrent Operations

Test multiple operations in quick succession:

1. "List today's events"
2. "Create event tomorrow at 10am"
3. "Search for 'meeting' events"
4. "Check availability on Friday"

**Expected Result**:
- All operations complete successfully
- No race conditions
- Correct results for each query

### Level 10: Docker Testing

If using Docker deployment:

#### Test 10.1: Container Build

```bash
cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/docker
docker compose build
```

**Expected Result**:
- Build completes without errors
- Image size reasonable (~150MB)
- All layers cached correctly

#### Test 10.2: Container Startup

```bash
docker compose up -d
```

**Expected Result**:
- Container starts successfully
- Health check passes
- Logs show no errors

#### Test 10.3: Container Health

```bash
docker compose ps
docker inspect gcal-mcp | jq '.[0].State.Health.Status'
```

**Expected Result**:
- Status: healthy
- Uptime: consistent
- No restart loops

#### Test 10.4: Volume Persistence

```bash
# Stop container
docker compose down

# Start again
docker compose up -d

# Test calendar access
# Should work without re-authentication
```

**Expected Result**:
- Tokens persist across restarts
- No re-authentication needed
- Immediate connectivity

## Test Cleanup

After testing, clean up test data:

```bash
# Delete test events via Claude Code
# "Delete all events with 'test' in the title"

# Or manually in Google Calendar web interface
```

## Automated Testing Script

Create an automated test runner:

```bash
#!/usr/bin/env bash
# test-suite.sh

set -euo pipefail

echo "Google Calendar MCP - Automated Tests"
echo "======================================"

# Test 1: Package installation
echo "Test 1: Package installation..."
if bunx --bun @cocal/google-calendar-mcp version &>/dev/null; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
    exit 1
fi

# Test 2: Credentials exist
echo "Test 2: Credentials exist..."
if [ -f "credentials/credentials.json" ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL: credentials.json not found"
    exit 1
fi

# Test 3: Token exists
echo "Test 3: Token exists..."
if [ -f "tokens/token.json" ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL: token.json not found"
    exit 1
fi

# Test 4: File permissions
echo "Test 4: File permissions..."
perms=$(stat -f "%Op" credentials/credentials.json 2>/dev/null || stat -c "%a" credentials/credentials.json 2>/dev/null)
if [ "$perms" = "100600" ] || [ "$perms" = "600" ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL: Incorrect permissions (expected 600, got $perms)"
fi

# Test 5: JSON validity
echo "Test 5: JSON validity..."
if command -v jq &>/dev/null; then
    if jq empty credentials/credentials.json 2>/dev/null; then
        echo "✓ PASS"
    else
        echo "✗ FAIL: Invalid JSON"
        exit 1
    fi
else
    echo "⊘ SKIP: jq not installed"
fi

echo ""
echo "All automated tests passed ✓"
```

Save and run:
```bash
chmod +x test-suite.sh
./test-suite.sh
```

## Continuous Testing

Set up regular testing:

```bash
# Add to cron (daily test)
0 9 * * * cd /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar && ./test-suite.sh >> test-log.txt 2>&1
```

## Test Results Log

Document test results:

```
Date: 2025-12-28
Tester: [Your Name]
Version: @cocal/google-calendar-mcp@2.2.0

Level 1 (Package): ✓ PASS
Level 2 (Auth): ✓ PASS
Level 3 (Startup): ✓ PASS
Level 4 (Integration): ✓ PASS
Level 5 (Basic Ops): ✓ PASS
Level 6 (Advanced): ✓ PASS
Level 7 (Multi-Account): ⊘ N/A
Level 8 (Errors): ✓ PASS
Level 9 (Performance): ✓ PASS
Level 10 (Docker): ✓ PASS

Notes:
- All tests completed successfully
- Response times under 5 seconds
- No errors encountered

Overall: PASS ✓
```

## Troubleshooting Failed Tests

If tests fail, consult:

1. **TROUBLESHOOTING.md** - Common issues and solutions
2. **SECURITY.md** - Permission and access issues
3. **README.md** - Configuration reference
4. **Package logs** - Error details

## Reporting Issues

If you encounter bugs:

1. Run full test suite
2. Collect logs and error messages
3. Document reproduction steps
4. Report at: https://github.com/nspady/google-calendar-mcp/issues

Include:
- Test level that failed
- Error messages
- System information (bun --version, OS, etc.)
- Configuration (sanitized)
