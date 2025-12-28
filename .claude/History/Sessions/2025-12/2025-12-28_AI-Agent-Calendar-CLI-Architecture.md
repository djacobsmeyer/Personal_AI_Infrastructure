# AI Agent-Driven Calendar Management CLI
## Architectural Design Document

**Date:** 2025-12-28
**Author:** Atlas (Principal Software Architect)
**Status:** Architecture Design Complete
**Project Type:** AI-Enhanced CLI Tool for Personal Calendar Management

---

## Executive Summary

### Project Overview

This document presents a comprehensive architectural design for an AI agent-driven command-line calendar management system that enables natural language interaction with calendar services (iCloud CalDAV and Google Calendar). The system leverages PAI's existing agent infrastructure, CLI-First Architecture principles, and TypeScript/Bun stack to create a deterministic, extensible, and intelligent calendar interface.

### Strategic Recommendation

**PRIMARY RECOMMENDATION: Start with Google Calendar, design for multi-provider extensibility**

**Rationale:**
1. **Developer Experience**: Google Calendar API provides superior DX with REST, webhooks, comprehensive documentation
2. **Reduced Complexity**: CalDAV's quirks, lack of webhooks, and RFC non-compliance create significant maintenance burden
3. **Faster Time-to-Value**: Get working prototype operational in days, not weeks
4. **Migration Path**: Start with Google Calendar foundation, add CalDAV adapter later if truly needed
5. **Industry Validation**: Cal.com nearly abandoned CalDAV due to complexity - strong signal

### Success Metrics

**Phase 1 (MVP - 2 weeks):**
- Natural language event creation working 95%+ accuracy
- Core CRUD operations functional (create, read, update, delete events)
- Context-aware scheduling (timezone, business hours, conflicts)
- Basic AI agent delegation operational

**Phase 2 (Enhanced - 4 weeks):**
- Multi-calendar support (work, personal, shared calendars)
- Intelligent conflict detection and resolution suggestions
- Meeting preparation automation (context gathering, agenda creation)
- CalDAV adapter for iCloud (if needed)

**Phase 3 (Advanced - 8 weeks):**
- Cross-provider synchronization
- Predictive scheduling based on patterns
- Integration with email, tasks, and other PAI skills
- Voice-driven calendar interaction

### Technical Stack

**Core Technologies:**
- **Runtime**: Bun (not Node.js - per PAI standards)
- **Language**: TypeScript (strict mode, full type safety)
- **CLI Framework**: Tier 1 (llcli-style manual parsing) for MVP, escalate to Commander.js if complexity warrants
- **Calendar APIs**: Google Calendar REST API (primary), CalDAV (secondary adapter)
- **AI Orchestration**: Claude Sonnet 4.5 via PAI agent infrastructure
- **NLP Enhancement**: Custom intent parsing with Claude's native understanding

**Supporting Infrastructure:**
- **Configuration**: `.env` for credentials, JSON for calendar preferences
- **Caching**: Local SQLite for calendar data caching (reduce API calls)
- **Testing**: Vitest for unit tests, integration tests with mock calendar API
- **Documentation**: README, QUICKSTART, comprehensive inline help

### Resource Requirements

**Development Team:**
- 1x Principal Engineer (TypeScript, API design) - 3 weeks full-time
- 1x AI/NLP Specialist (agent orchestration, intent parsing) - 2 weeks full-time
- User (Daniel) - Requirements validation, testing, feedback

**Infrastructure:**
- Google Calendar API access (free tier sufficient for personal use)
- iCloud account with app-specific password (if CalDAV required)
- PAI environment with Claude Code and agent infrastructure

---

## System Architecture

### High-Level Architecture

The system follows PAI's CLI-First Architecture with a three-layer design:

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER INTERACTION LAYER                        │
│  Natural Language: "Schedule lunch with Sarah next Tuesday"     │
│  Direct CLI: cal create "Meeting" --time "2pm" --duration "1h"  │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AI ORCHESTRATION LAYER                         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Intent Agent │  │ Context Agent│  │ Action Agent │         │
│  │ (Parse NL)   │  │ (Enrich data)│  │ (Execute ops)│         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  Uses: Claude Sonnet 4.5 + PAI agent delegation patterns       │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                DETERMINISTIC CLI LAYER (CORE)                    │
│                                                                  │
│  TypeScript CLI Tool: `cal` (300-500 lines, llcli-style)       │
│                                                                  │
│  Commands:                                                       │
│  • cal list [--today|--week|--month] [--calendar NAME]         │
│  • cal create TITLE --time TIME [--duration DUR] [--location]  │
│  • cal update EVENT_ID --time TIME [or other fields]           │
│  • cal delete EVENT_ID                                          │
│  • cal search QUERY [--from DATE] [--to DATE]                  │
│  • cal conflicts [--date DATE] [--week]                        │
│  • cal config [--set KEY=VALUE] [--list]                       │
│  • cal sync [--force]                                           │
│  • cal agenda [--today|--week]                                  │
│                                                                  │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│              PROVIDER ABSTRACTION LAYER                          │
│                                                                  │
│  Interface: CalendarProvider (TypeScript interface)             │
│                                                                  │
│  ┌──────────────────────┐    ┌──────────────────────┐          │
│  │ GoogleCalendarAdapter│    │  CalDAVAdapter       │          │
│  │                      │    │  (iCloud, others)    │          │
│  │ • REST API calls     │    │ • WebDAV protocol    │          │
│  │ • OAuth 2.0 auth     │    │ • App passwords      │          │
│  │ • Webhook support    │    │ • Polling sync       │          │
│  │ • Type-safe models   │    │ • RFC workarounds    │          │
│  └──────────────────────┘    └──────────────────────┘          │
│                                                                  │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DATA/CACHE LAYER                               │
│                                                                  │
│  • SQLite: Local event cache, sync state, user preferences      │
│  • JSON: Configuration files, calendar mappings                 │
│  • Filesystem: Credentials (encrypted), logs, history           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Component Relationships

**1. CLI Core (`cal` command)**
- **Responsibility**: Deterministic calendar operations, argument parsing, output formatting
- **Dependencies**: Provider abstraction layer, local cache
- **Outputs**: JSON (for composability with jq, grep) or formatted text
- **Testing**: Fully testable without AI layer

**2. AI Orchestration Layer**
- **Responsibility**: Natural language understanding, context enrichment, intelligent defaults
- **Architecture**: Three specialized agents (Intent → Context → Action)
- **Integration**: Calls deterministic CLI commands, never bypasses them
- **Model**: Claude Sonnet 4.5 (good balance of speed and capability)

**3. Provider Abstraction**
- **Responsibility**: Calendar service integration, API translation
- **Pattern**: Strategy pattern with pluggable adapters
- **Interface**:
```typescript
interface CalendarProvider {
  // Authentication
  authenticate(): Promise<void>;
  validateAuth(): Promise<boolean>;

  // Event operations
  listEvents(options: ListOptions): Promise<CalendarEvent[]>;
  createEvent(event: EventInput): Promise<CalendarEvent>;
  updateEvent(id: string, updates: Partial<EventInput>): Promise<CalendarEvent>;
  deleteEvent(id: string): Promise<void>;

  // Calendar management
  listCalendars(): Promise<Calendar[]>;
  getCalendar(id: string): Promise<Calendar>;

  // Advanced features
  checkConflicts(event: EventInput): Promise<ConflictInfo[]>;
  searchEvents(query: string, options?: SearchOptions): Promise<CalendarEvent[]>;

  // Sync support
  syncEvents(since?: Date): Promise<SyncResult>;
}
```

**4. Cache Layer**
- **Responsibility**: Reduce API calls, offline access, conflict detection
- **Technology**: SQLite (lightweight, embedded, SQL queryable)
- **Schema**: Events, calendars, sync state, user preferences
- **Sync Strategy**: Write-through cache with periodic background sync

---

## Natural Language Interaction Patterns

### Design Philosophy

**Natural language should feel like talking to a calendar-aware assistant, not a command parser.**

The system recognizes that users think in contexts, not parameters:
- "Tomorrow at 2pm" (not `--date 2025-12-29 --time 14:00`)
- "After my meeting with John" (relative scheduling)
- "My usual meeting time" (pattern recognition)

### Intent Categories

**1. Event Creation**
```
Natural Language Input          →  CLI Translation                    →  Executed
─────────────────────────────────────────────────────────────────────────────────
"Schedule lunch with Sarah       cal create "Lunch with Sarah"         ✓
 next Tuesday at noon"           --time "2025-12-31T12:00"
                                 --duration "1h"

"Set up a 30-minute call         cal create "Product sync"             ✓
 about product sync tomorrow"    --time "2025-12-29T14:00"
                                 --duration "30m"

"Block off Thursday afternoon    cal create "Focus time"               ✓
 for focused work"               --time "2026-01-02T13:00"
                                 --duration "4h"
                                 --calendar "Personal"

"Weekly standup every Monday     cal create "Weekly standup"           ✓
 at 9am"                         --time "next-monday 09:00"
                                 --recurrence "weekly"
```

**2. Event Querying**
```
Natural Language Input          →  CLI Translation                    →  Executed
─────────────────────────────────────────────────────────────────────────────────
"What's on my calendar today?"   cal list --today                      ✓

"Show me next week's meetings"   cal list --week                       ✓
                                 --from "2025-12-30"

"Find all meetings with Sarah"   cal search "Sarah"                    ✓

"What do I have tomorrow?"       cal agenda --date "2025-12-29"        ✓

"Any conflicts Thursday?"        cal conflicts                         ✓
                                 --date "2026-01-02"
```

**3. Event Modification**
```
Natural Language Input          →  CLI Translation                    →  Executed
─────────────────────────────────────────────────────────────────────────────────
"Move tomorrow's 2pm meeting     [Search] cal list --tomorrow          ✓
 to 3pm"                         [Update] cal update EVENT_123
                                 --time "15:00"

"Cancel my meeting with John"    [Search] cal search "John"            ✓
                                 [Delete] cal delete EVENT_456

"Make the standup 15 minutes     [Search] cal search "standup"         ✓
 shorter"                        [Update] cal update EVENT_789
                                 --duration "-15m"
```

**4. Intelligent Scheduling**
```
Natural Language Input          →  AI Agent Processing               →  Result
─────────────────────────────────────────────────────────────────────────────────
"Find a time for coffee with     1. cal list --week                    Suggestion:
 Sarah next week"                2. Analyze Sarah's availability       "Tuesday 3pm
                                 3. Check conflicts                    or Thursday
                                 4. Suggest 2-3 options                10am work?"

"Schedule this meeting when      1. Parse attendees                    Auto-schedule
 everyone's available"           2. Query all calendars                when optimal
                                 3. Find common free time              time found
                                 4. Rank by preference

"What's the best time for a      1. Analyze user's calendar patterns   Recommendation
 deep work session tomorrow?"    2. Find 2+ hour blocks                based on
                                 3. Check energy patterns              patterns
                                 4. Recommend optimal time
```

### Context Awareness

The AI layer maintains and enriches context:

**Time Context:**
- "Tomorrow" resolves to actual date based on current date
- "Next week" means upcoming Monday-Sunday
- "After lunch" resolves to 1pm or 2pm based on user patterns
- "Before the weekend" means Thursday/Friday based on user's work week

**Calendar Context:**
- Default calendar inferred from event type (work vs personal)
- Shared calendar with wife auto-selected for family events
- Work calendar auto-selected for professional meetings

**User Pattern Learning:**
- "My usual meeting time" → 2pm based on historical data
- "Coffee" → 30-minute default duration learned from past coffee meetings
- "Standup" → 15 minutes, recurring weekly, work calendar

**Relationship Context:**
- "Meeting with Sarah" → Checks if Sarah is already in contacts
- Family events → Auto-share with wife's calendar
- Client meetings → Work calendar, longer default duration

---

## AI Agent Architecture

### Agent Delegation Strategy

Following PAI's delegation patterns, the calendar system uses three specialized agents:

**1. Intent Agent (Haiku - Fast & Cheap)**
```
Role: Parse natural language input into structured intent
Model: Claude Haiku (sufficient for classification)
Speed: <500ms response time
Cost: Minimal (~$0.0001 per request)

Input:  "Schedule lunch with Sarah next Tuesday at noon"
Output: {
  action: "create_event",
  entities: {
    title: "Lunch with Sarah",
    attendees: ["Sarah"],
    date: "2025-12-31",
    time: "12:00",
    duration: "1h" (inferred default)
  },
  confidence: 0.95
}
```

**2. Context Agent (Sonnet - Balanced)**
```
Role: Enrich intent with user context, patterns, and calendar state
Model: Claude Sonnet 4.5 (needs reasoning capability)
Speed: ~2-3s response time
Cost: Moderate (~$0.003 per request)

Input:  Intent from Intent Agent + User calendar history
Process:
  - Check for conflicts at proposed time
  - Analyze user's typical lunch duration (historical avg)
  - Verify Sarah is a known contact
  - Suggest optimal location based on past meetings with Sarah
  - Check weather if outdoor location

Output: {
  enriched_event: {
    title: "Lunch with Sarah",
    time: "2025-12-31T12:00:00",
    duration: "1h",
    location: "Cafe Aurora" (based on history),
    calendar: "Personal",
    attendees: ["sarah@example.com"]
  },
  warnings: [],
  suggestions: ["Weather looks great for outdoor seating"]
}
```

**3. Action Agent (Haiku - Fast Execution)**
```
Role: Execute deterministic CLI commands, handle errors, retry logic
Model: Claude Haiku (executing commands, not reasoning)
Speed: <1s + API call time
Cost: Minimal

Input:  Enriched event from Context Agent
Process:
  1. Translate to CLI command:
     cal create "Lunch with Sarah" \
       --time "2025-12-31T12:00:00" \
       --duration "1h" \
       --location "Cafe Aurora" \
       --calendar "Personal" \
       --attendee "sarah@example.com"

  2. Execute command via TypeScript CLI
  3. Handle errors (retry with exponential backoff)
  4. Verify creation via API

Output: {
  status: "success",
  event_id: "evt_abc123",
  calendar_url: "https://calendar.google.com/...",
  summary: "Created 'Lunch with Sarah' for Tue Dec 31 at noon"
}
```

### Delegation Flow

```
User Input (Natural Language)
         │
         ▼
   ┌──────────────┐
   │ Intent Agent │ (Haiku - 500ms)
   │ Parses input │
   └──────┬───────┘
          │ Structured intent
          ▼
   ┌──────────────┐
   │Context Agent │ (Sonnet - 2-3s)
   │Enriches data │
   └──────┬───────┘
          │ Complete event spec
          ▼
   ┌──────────────┐
   │Action Agent  │ (Haiku - <1s)
   │Executes CLI  │
   └──────┬───────┘
          │ Result
          ▼
   User Feedback (Voice + Text)
```

**Total Latency**: ~3-4 seconds for natural language → calendar event
**Total Cost**: ~$0.004 per request (sustainable for personal use)

### Error Handling & Recovery

**Agent-Level Retry Logic:**
- Intent parsing failure → Ask user for clarification
- Context enrichment timeout → Use defaults, mark low-confidence
- CLI execution failure → Retry with exponential backoff (3 attempts)
- API rate limit → Queue request, notify user of delay

**Validation Chain:**
```
Intent Agent validation:
  ✓ Required fields present (title, time OR relative time)
  ✓ Parseable date/time format
  ✗ Fail: Ask user to clarify

Context Agent validation:
  ✓ No hard conflicts (double-booking)
  ⚠ Soft conflicts (back-to-back meetings)
  ✓ Valid timezone handling
  ✗ Fail: Suggest alternatives

Action Agent validation:
  ✓ CLI command syntax valid
  ✓ API response successful (200/201)
  ✓ Event visible in calendar
  ✗ Fail: Rollback, notify user
```

### Integration with PAI Agent Infrastructure

**Using Existing PAI Agents:**

**Intern Agent** - Calendar research and analysis
- Usage: "Analyze my calendar patterns for the last month"
- Delegates to: Multiple parallel interns, each analyzing different aspects
- Example: Time utilization, meeting frequency, common attendees, optimal focus times

**Researcher Agent** - External context gathering
- Usage: "Find a good restaurant for my client meeting"
- Delegates to: Perplexity/Claude researcher for location suggestions
- Returns: Top 3 options with ratings, distance, availability

**Engineer Agent** - CLI tool implementation
- Usage: Building the actual TypeScript CLI tool
- Delegates to: Engineer agent for TDD implementation
- Returns: Production-ready code with tests

**Voice Integration:**
- Uses PAI's voice server for spoken confirmations
- Each calendar operation completion triggers voice notification
- Example: "Created lunch with Sarah for next Tuesday at noon" (spoken aloud)

---

## Calendar Provider Abstraction Strategy

### Abstraction Layer Design

**Core Principle**: Write once, support multiple providers with minimal provider-specific code.

**TypeScript Interface Pattern:**

```typescript
// Core domain models (provider-agnostic)
interface CalendarEvent {
  id: string;
  title: string;
  description?: string;
  startTime: Date;
  endTime: Date;
  timezone: string;
  location?: string;
  attendees: Attendee[];
  recurrence?: RecurrenceRule;
  calendarId: string;
  metadata: Record<string, unknown>;
}

interface Calendar {
  id: string;
  name: string;
  description?: string;
  color: string;
  isDefault: boolean;
  isPrimary: boolean;
  accessRole: 'owner' | 'writer' | 'reader';
  provider: 'google' | 'caldav' | 'outlook';
}

// Provider adapter interface
abstract class CalendarProvider {
  abstract name: string;
  abstract authenticate(): Promise<void>;
  abstract listEvents(options: ListOptions): Promise<CalendarEvent[]>;
  abstract createEvent(event: EventInput): Promise<CalendarEvent>;
  abstract updateEvent(id: string, updates: Partial<EventInput>): Promise<CalendarEvent>;
  abstract deleteEvent(id: string): Promise<void>;
  abstract listCalendars(): Promise<Calendar[]>;
  abstract syncEvents(since?: Date): Promise<SyncResult>;

  // Utility methods (shared across providers)
  protected normalizeEvent(raw: unknown): CalendarEvent {
    // Provider-specific to common format
  }

  protected denormalizeEvent(event: EventInput): unknown {
    // Common format to provider-specific
  }
}
```

### Google Calendar Adapter Implementation

```typescript
// Implementation for Google Calendar
class GoogleCalendarAdapter extends CalendarProvider {
  name = 'Google Calendar';

  private client: GoogleCalendarClient;
  private credentials: OAuth2Credentials;

  async authenticate(): Promise<void> {
    // OAuth 2.0 flow
    // Store tokens in ~/.config/cal/google-tokens.json
    // Auto-refresh on expiry
  }

  async listEvents(options: ListOptions): Promise<CalendarEvent[]> {
    const response = await this.client.events.list({
      calendarId: options.calendarId || 'primary',
      timeMin: options.from?.toISOString(),
      timeMax: options.to?.toISOString(),
      maxResults: options.limit || 50,
      singleEvents: true,
      orderBy: 'startTime'
    });

    return response.data.items.map(item =>
      this.normalizeEvent(item)
    );
  }

  async createEvent(event: EventInput): Promise<CalendarEvent> {
    const googleEvent = this.denormalizeEvent(event);
    const response = await this.client.events.insert({
      calendarId: event.calendarId || 'primary',
      requestBody: googleEvent
    });

    return this.normalizeEvent(response.data);
  }

  // Webhook support for real-time updates
  async setupWebhook(callbackUrl: string): Promise<void> {
    await this.client.events.watch({
      calendarId: 'primary',
      requestBody: {
        id: uuidv4(),
        type: 'web_hook',
        address: callbackUrl
      }
    });
  }
}
```

### CalDAV Adapter Implementation

```typescript
// Implementation for CalDAV (iCloud, etc.)
class CalDAVAdapter extends CalendarProvider {
  name = 'CalDAV (iCloud)';

  private client: DAVClient;
  private serverUrl: string;
  private username: string;
  private password: string; // App-specific password

  async authenticate(): Promise<void> {
    // Basic auth with app-specific password
    this.client = new DAVClient({
      serverUrl: this.serverUrl,
      credentials: {
        username: this.username,
        password: this.password
      },
      authMethod: 'Basic',
      defaultAccountType: 'caldav'
    });

    await this.client.login();
  }

  async listEvents(options: ListOptions): Promise<CalendarEvent[]> {
    // CalDAV REPORT query
    const events = await this.client.calendarQuery({
      url: this.calendarUrl,
      props: [
        { name: 'getetag', namespace: DAV.DAV },
        { name: 'calendar-data', namespace: DAV.CALDAV }
      ],
      filters: this.buildTimeRangeFilter(options.from, options.to)
    });

    // Parse iCalendar format to CalendarEvent
    return events.map(e => this.parseICalToEvent(e.data));
  }

  async createEvent(event: EventInput): Promise<CalendarEvent> {
    // Convert to iCalendar format
    const ical = this.eventToICal(event);

    // PUT request to CalDAV server
    const eventUrl = `${this.calendarUrl}/${uuidv4()}.ics`;
    await this.client.createCalendarObject({
      url: eventUrl,
      data: ical,
      filename: `${event.title}.ics`
    });

    // Fetch back to get server-assigned ID
    const created = await this.client.getObject({ url: eventUrl });
    return this.parseICalToEvent(created.data);
  }

  // CalDAV has no webhooks - polling required
  async syncEvents(since?: Date): Promise<SyncResult> {
    // Use sync-token for efficient polling
    const syncToken = await this.getSyncToken();
    const changes = await this.client.syncCollection({
      url: this.calendarUrl,
      syncToken: syncToken
    });

    return {
      added: changes.created.map(e => this.parseICalToEvent(e)),
      updated: changes.updated.map(e => this.parseICalToEvent(e)),
      deleted: changes.deleted.map(e => e.url),
      nextSyncToken: changes.syncToken
    };
  }

  // Helper: iCalendar parsing (handles RFC quirks)
  private parseICalToEvent(icalData: string): CalendarEvent {
    // Use ical.js library for parsing
    // Handle Google's RFC violations gracefully
  }
}
```

### Provider Selection Strategy

```typescript
// Provider factory pattern
class ProviderFactory {
  static create(providerType: 'google' | 'caldav', config: ProviderConfig): CalendarProvider {
    switch (providerType) {
      case 'google':
        return new GoogleCalendarAdapter(config);
      case 'caldav':
        return new CalDAVAdapter(config);
      default:
        throw new Error(`Unknown provider: ${providerType}`);
    }
  }

  static fromConfig(configPath: string): CalendarProvider {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
    return this.create(config.provider, config);
  }
}

// Usage in CLI
const provider = ProviderFactory.fromConfig('~/.config/cal/config.json');
await provider.authenticate();
const events = await provider.listEvents({ from: new Date(), to: addDays(new Date(), 7) });
```

### Multi-Provider Aggregation

**For users with multiple calendars across providers:**

```typescript
class AggregateCalendarProvider extends CalendarProvider {
  private providers: CalendarProvider[];

  constructor(providers: CalendarProvider[]) {
    super();
    this.providers = providers;
  }

  async listEvents(options: ListOptions): Promise<CalendarEvent[]> {
    // Parallel fetch from all providers
    const results = await Promise.all(
      this.providers.map(p => p.listEvents(options))
    );

    // Merge and sort by start time
    return results
      .flat()
      .sort((a, b) => a.startTime.getTime() - b.startTime.getTime());
  }

  async createEvent(event: EventInput): Promise<CalendarEvent> {
    // Route to correct provider based on calendarId
    const provider = this.findProviderForCalendar(event.calendarId);
    return provider.createEvent(event);
  }

  private findProviderForCalendar(calendarId: string): CalendarProvider {
    // Calendar ID encodes provider (e.g., "google:primary", "caldav:work")
    const [providerName] = calendarId.split(':');
    return this.providers.find(p => p.name.includes(providerName));
  }
}
```

---

## Authentication & Security Approach

### Authentication Strategy

**Google Calendar OAuth 2.0 Flow:**

```typescript
// OAuth 2.0 with PKCE (Proof Key for Code Exchange)
class GoogleAuthManager {
  private clientId: string;
  private clientSecret: string;
  private redirectUri = 'http://localhost:8888/oauth/callback';

  async initiateAuth(): Promise<void> {
    // 1. Generate PKCE code verifier and challenge
    const codeVerifier = this.generateCodeVerifier();
    const codeChallenge = await this.generateCodeChallenge(codeVerifier);

    // 2. Build authorization URL
    const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
    authUrl.searchParams.set('client_id', this.clientId);
    authUrl.searchParams.set('redirect_uri', this.redirectUri);
    authUrl.searchParams.set('response_type', 'code');
    authUrl.searchParams.set('scope', 'https://www.googleapis.com/auth/calendar');
    authUrl.searchParams.set('code_challenge', codeChallenge);
    authUrl.searchParams.set('code_challenge_method', 'S256');

    // 3. Open browser for user consent
    console.log(`Opening browser for authentication...`);
    await open(authUrl.toString());

    // 4. Start local server to receive callback
    const code = await this.startCallbackServer();

    // 5. Exchange code for tokens
    const tokens = await this.exchangeCodeForTokens(code, codeVerifier);

    // 6. Store tokens securely
    await this.storeTokens(tokens);
  }

  async refreshTokens(): Promise<void> {
    const tokens = await this.loadTokens();

    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: this.clientId,
        client_secret: this.clientSecret,
        refresh_token: tokens.refresh_token,
        grant_type: 'refresh_token'
      })
    });

    const newTokens = await response.json();
    await this.storeTokens({
      ...tokens,
      access_token: newTokens.access_token,
      expires_at: Date.now() + newTokens.expires_in * 1000
    });
  }

  async getValidAccessToken(): Promise<string> {
    const tokens = await this.loadTokens();

    // Refresh if expired or expiring within 5 minutes
    if (Date.now() + 300000 > tokens.expires_at) {
      await this.refreshTokens();
      return (await this.loadTokens()).access_token;
    }

    return tokens.access_token;
  }
}
```

**CalDAV App-Specific Password:**

```typescript
// CalDAV uses Basic Auth with app-specific passwords
class CalDAVAuthManager {
  private username: string;
  private password: string; // App-specific password from iCloud

  async authenticate(): Promise<boolean> {
    // Test authentication with PROPFIND request
    const response = await fetch(this.serverUrl, {
      method: 'PROPFIND',
      headers: {
        'Authorization': `Basic ${btoa(`${this.username}:${this.password}`)}`,
        'Depth': '0'
      }
    });

    return response.ok;
  }

  getAuthHeader(): string {
    return `Basic ${btoa(`${this.username}:${this.password}`)}`;
  }
}
```

### Credential Storage

**Secure Storage Strategy:**

```typescript
// Credentials stored in ~/.config/cal/credentials.json
// Encrypted at rest using user's system keychain

interface CredentialStore {
  google?: {
    access_token: string;
    refresh_token: string;
    expires_at: number;
    scope: string;
  };
  caldav?: {
    username: string;
    password: string; // Encrypted
    server_url: string;
  };
}

class SecureCredentialManager {
  private storePath = path.join(os.homedir(), '.config', 'cal', 'credentials.json');

  async store(provider: string, credentials: unknown): Promise<void> {
    // Encrypt sensitive fields using system keychain
    const encrypted = await this.encrypt(credentials);

    const store = await this.load();
    store[provider] = encrypted;

    // Write with restricted permissions (0600)
    await fs.writeFile(
      this.storePath,
      JSON.stringify(store, null, 2),
      { mode: 0o600 }
    );
  }

  async load(): Promise<CredentialStore> {
    if (!await fs.pathExists(this.storePath)) {
      return {};
    }

    const data = await fs.readFile(this.storePath, 'utf-8');
    const store = JSON.parse(data);

    // Decrypt sensitive fields
    for (const [provider, creds] of Object.entries(store)) {
      store[provider] = await this.decrypt(creds);
    }

    return store;
  }

  private async encrypt(data: unknown): Promise<unknown> {
    // Use system keychain (macOS Keychain, Linux Secret Service, Windows Credential Manager)
    // via keytar or similar library
  }
}
```

### Security Best Practices

**1. Least Privilege Access:**
- Request only calendar.events scope (not full calendar access)
- Separate credentials for work vs personal calendars
- Read-only mode option for auditing/analysis

**2. Token Security:**
- Never log tokens
- Rotate refresh tokens periodically
- Clear tokens on logout
- Encrypt at rest

**3. API Security:**
- Rate limiting (respect provider limits)
- Exponential backoff on errors
- Request signing for CalDAV
- HTTPS only (no HTTP fallback)

**4. User Privacy:**
- Local-first architecture (cache everything)
- No telemetry without explicit consent
- Event data never sent to third parties
- Audit log of all calendar modifications

**5. Git Safety:**
- `.gitignore`: Credentials, tokens, cached events
- Environment variables for API keys
- Separate private/public PAI repositories
- Pre-commit hooks to prevent credential leaks

---

## Common Use Cases & Workflows

### Use Case 1: Morning Calendar Review

**User Intent**: "What's on my calendar today?"

**System Flow:**
```
1. User input (natural language or `cal agenda --today`)

2. Intent Agent (Haiku):
   → Parses intent: list_events with filter today

3. CLI Execution:
   $ cal list --today --format agenda

4. Provider Layer:
   → Google Calendar API: events.list(timeMin=today 00:00, timeMax=today 23:59)
   → Cache layer: Check for cached events (if online unavailable)

5. Output (formatted):
   ┌─────────────────────────────────────────────┐
   │ Today's Agenda - Saturday, Dec 28, 2025    │
   ├─────────────────────────────────────────────┤
   │ 9:00 AM  - 9:30 AM   Team Standup          │
   │ 11:00 AM - 12:00 PM  Product Review        │
   │ 2:00 PM  - 3:00 PM   1:1 with Sarah        │
   │ 4:00 PM  - 5:00 PM   Focus Time (Blocked)  │
   └─────────────────────────────────────────────┘

   Next: Team Standup in 2 hours 15 minutes

6. Voice output:
   "You have 4 events today, starting with team standup at 9 AM"
```

**Enhancements:**
- Travel time calculation between locations
- Weather alerts for outdoor events
- Meeting preparation suggestions (past notes, attendee context)

---

### Use Case 2: Smart Event Creation

**User Intent**: "Schedule coffee with John next week when we're both free"

**System Flow:**
```
1. User input (natural language)

2. Intent Agent (Haiku):
   → Action: create_event
   → Entities: {title: "Coffee with John", attendee: "John", timeframe: "next week"}
   → Missing: Specific time
   → Confidence: 0.6 (low due to missing time)

3. Context Agent (Sonnet) - Multi-step reasoning:
   Step 1: Identify John
     - Search contacts for "John"
     - Found: John Smith (john.smith@example.com)

   Step 2: Analyze availability
     - Query user's calendar for next week (Dec 30 - Jan 5)
     - Query John's calendar (if shared/accessible)
     - Find overlapping free time slots

   Step 3: Apply heuristics
     - Historical pattern: Coffee meetings typically 30 mins
     - Preferred times: Mid-morning (10am-11am) or mid-afternoon (2pm-3pm)
     - Location suggestion: "Cafe Aurora" (frequent meeting spot with John)

   Step 4: Generate suggestions
     - Option 1: Tuesday Jan 2, 10:30 AM (both free, optimal time)
     - Option 2: Thursday Jan 4, 2:00 PM (backup option)
     - Option 3: Friday Jan 5, 11:00 AM (if neither works)

4. User confirmation:
   "I found 3 times when you and John Smith are both free next week:
    1. Tuesday Jan 2 at 10:30 AM (recommended)
    2. Thursday Jan 4 at 2:00 PM
    3. Friday Jan 5 at 11:00 AM

    Which works best?"

   User: "Option 1"

5. Action Agent (Haiku) - Execute:
   $ cal create "Coffee with John" \
     --time "2026-01-02T10:30:00" \
     --duration "30m" \
     --location "Cafe Aurora" \
     --attendee "john.smith@example.com" \
     --send-invite

6. Result:
   ✓ Created event "Coffee with John"
   ✓ Sent calendar invite to john.smith@example.com
   ✓ Added to your calendar (Personal)

   Google Calendar link: https://calendar.google.com/event?eid=...

7. Voice output:
   "Coffee with John scheduled for Tuesday January 2nd at 10:30 AM at Cafe Aurora"
```

**Enhancements:**
- Email integration (parse meeting requests from email)
- Automatic agenda creation based on past meeting notes
- Reminder setup (e.g., "Remind me 1 day before to prepare talking points")

---

### Use Case 3: Conflict Detection & Resolution

**User Intent**: "Can I add a 2pm meeting tomorrow?"

**System Flow:**
```
1. User input (natural language)

2. Intent Agent (Haiku):
   → Action: check_conflicts
   → Time: Tomorrow 2pm
   → Duration: 1h (default assumption)

3. Context Agent (Sonnet) - Conflict analysis:
   Step 1: Query calendar for tomorrow
     - Existing events:
       * 1:30 PM - 2:30 PM: Client call (Work calendar)
       * 3:00 PM - 4:00 PM: Focus time (Personal calendar)

   Step 2: Detect conflicts
     - Hard conflict: 2pm meeting overlaps with 1:30-2:30 client call
     - Soft conflict: Only 30 min buffer before 3pm focus time

   Step 3: Analyze impact
     - Client call is non-movable (external attendees)
     - Focus time can potentially be rescheduled

   Step 4: Generate alternatives
     - Option 1: Schedule at 11:00 AM (2-hour free slot)
     - Option 2: Schedule at 4:00 PM (after focus time)
     - Option 3: Move focus time, schedule at 2pm (not recommended)

4. User notification:
   ⚠ Conflict detected: Tomorrow at 2pm overlaps with "Client call" (1:30-2:30 PM)

   Suggested alternatives:
   1. Tomorrow at 11:00 AM (✓ 2-hour window available)
   2. Tomorrow at 4:00 PM (after focus time)
   3. Monday Jan 1 at 2:00 PM (if date is flexible)

   Would you like to schedule at one of these times instead?

5. User: "11am works"

6. Action Agent executes:
   $ cal create "New meeting" --time "2025-12-29T11:00:00" --duration "1h"

7. Voice output:
   "Meeting scheduled for tomorrow at 11 AM. I avoided the conflict with your 2 PM client call."
```

**Enhancements:**
- Automatic attendee availability checking
- Meeting priority scoring (can this be moved?)
- Cascading reschedule suggestions (if everything is booked)

---

### Use Case 4: Recurring Event Management

**User Intent**: "Change my weekly standup from Monday 9am to Tuesday 10am"

**System Flow:**
```
1. User input (natural language)

2. Intent Agent (Haiku):
   → Action: update_recurring_event
   → Search: "weekly standup"
   → Updates: {day: "Tuesday", time: "10:00"}

3. CLI search:
   $ cal search "weekly standup" --recurring-only

4. Context Agent (Sonnet) - Recurrence handling:
   Found: "Weekly Standup" (recurring event)
     - Current: Every Monday at 9:00 AM
     - Next occurrence: Monday Dec 30, 2025
     - Series has 3 future instances

   Question: Update this instance only, or all future instances?
   Default: All future instances (user said "change my weekly standup")

5. User confirmation:
   Found recurring event "Weekly Standup" (Mondays at 9 AM).

   This will update all future instances to Tuesdays at 10 AM.
   Next occurrence will be Tuesday Dec 31 at 10 AM.

   Confirm? [Y/n]

6. User: "Y"

7. Action Agent executes:
   $ cal update evt_abc123 \
     --recurrence "RRULE:FREQ=WEEKLY;BYDAY=TU" \
     --time "10:00" \
     --apply-to-series

8. Result:
   ✓ Updated recurring event "Weekly Standup"
   ✓ All future instances now: Tuesdays at 10:00 AM
   ✓ Next occurrence: Tuesday Dec 31, 2025 at 10:00 AM

9. Voice output:
   "Updated weekly standup to Tuesdays at 10 AM for all future instances"
```

---

### Use Case 5: Calendar Sync & Multi-Device

**User Intent**: Ensure changes made on phone appear in CLI immediately

**System Flow:**
```
1. Background sync daemon (runs every 5 minutes):
   $ cal sync --background

2. Provider webhook (Google Calendar only):
   - Google sends webhook notification when event changes
   - Local webhook server receives notification
   - Triggers immediate sync

3. Sync process:
   Step 1: Fetch sync token from cache
   Step 2: Request incremental changes from provider
     - Google: sync token-based incremental sync
     - CalDAV: sync-collection report with sync token
   Step 3: Update local cache
     - New events: INSERT INTO events
     - Updated events: UPDATE events WHERE id=...
     - Deleted events: DELETE FROM events WHERE id=...
   Step 4: Store new sync token

4. Cache invalidation:
   - Invalidate affected date ranges
   - Notify any active CLI sessions (via IPC)

5. User query (immediately after phone edit):
   $ cal list --today
   → Reads from just-synced cache
   → Returns up-to-date events including phone edit
```

**CalDAV Polling Strategy (no webhooks):**
```
Polling interval: 5 minutes (configurable)
Smart polling:
  - Poll every 1 min during active work hours (9am-6pm)
  - Poll every 5 min during off-hours
  - Poll every 30 min overnight

Optimization:
  - Use sync-token to fetch only changes
  - Batch multiple calendar syncs into one request
  - Exponential backoff on network errors
```

---

## Trade-offs: CalDAV vs Google Calendar

### Comprehensive Comparison Matrix

| Aspect | Google Calendar | CalDAV (iCloud) | Recommendation |
|--------|----------------|-----------------|----------------|
| **Developer Experience** | ⭐⭐⭐⭐⭐ REST API, excellent docs | ⭐⭐ WebDAV, sparse docs, RFC issues | **Google** for initial development |
| **Protocol Complexity** | Simple HTTP REST | Complex WebDAV with XML | **Google** significantly easier |
| **Authentication** | OAuth 2.0 (standard) | App-specific passwords (manual) | **Google** better UX |
| **Real-time Updates** | Webhooks (push notifications) | Polling only (5-min delay) | **Google** for responsiveness |
| **API Stability** | Excellent (Google scale) | Variable (RFC non-compliance) | **Google** more reliable |
| **Rate Limits** | Generous (1M req/day free tier) | Unknown/undocumented | **Google** clearer limits |
| **Data Ownership** | Google owns data | User owns data (iCloud) | **CalDAV** for privacy |
| **Vendor Lock-in** | High (Google-specific features) | Low (open standard) | **CalDAV** for portability |
| **Multi-Provider** | Google only | Works with iCloud, Fastmail, etc. | **CalDAV** for flexibility |
| **Offline Access** | Requires cache implementation | Requires cache implementation | Tie (both need local cache) |
| **Cost** | Free (personal use) | Free (with iCloud account) | Tie |
| **Feature Richness** | Rich (Meet integration, etc.) | Basic (standard calendar only) | **Google** for integrations |
| **Implementation Time** | 1-2 weeks | 3-4 weeks (due to complexity) | **Google** faster to market |
| **Maintenance Burden** | Low (stable API) | Medium-High (workarounds needed) | **Google** less maintenance |
| **Community Support** | Excellent (large ecosystem) | Good (but smaller community) | **Google** better resources |

### Detailed Analysis

**Google Calendar Advantages:**

1. **Superior DX**: REST API with clear request/response patterns, no XML parsing
2. **Webhooks**: Real-time sync without polling overhead
3. **Documentation**: Comprehensive, up-to-date, with code examples
4. **Tooling**: Official client libraries, Postman collections, API Explorer
5. **Error Messages**: Clear, actionable error messages with documentation links
6. **Incremental Sync**: Efficient sync token mechanism

**Google Calendar Disadvantages:**

1. **Vendor Lock-in**: Tight coupling to Google ecosystem
2. **Privacy Concerns**: Data stored on Google servers
3. **Feature Creep**: API adds features that may break assumptions
4. **Account Dependency**: Requires Google account

**CalDAV Advantages:**

1. **Open Standard**: Works with multiple providers (iCloud, Fastmail, Nextcloud, etc.)
2. **Data Ownership**: User controls where data lives
3. **Privacy**: Self-hosted options available
4. **No Vendor Lock-in**: Easy to switch providers
5. **Standards Compliance**: RFC-based (in theory)

**CalDAV Disadvantages:**

1. **Implementation Complexity**: WebDAV + iCalendar format parsing
2. **RFC Non-Compliance**: Google's CalDAV doesn't fully follow RFC (as noted in research)
3. **No Webhooks**: Polling required for sync (latency + inefficiency)
4. **Server Quirks**: Different CalDAV servers have different behaviors
5. **Limited Features**: No modern features (Meet links, smart suggestions, etc.)
6. **Documentation**: Sparse, outdated, provider-specific gotchas
7. **Debugging Difficulty**: XML parsing errors are cryptic

### Industry Evidence

**Cal.com's Experience** (from research):
- Nearly abandoned CalDAV support due to complexity
- Google's CalDAV "hit and miss - mostly miss - and loads of frustration, workarounds, and special cases"
- "Google doesn't even come close to following the RFC"

**Developer Consensus** (from search results):
- "Google Calendar API's versatility and functionality far surpass older protocols like CalDAV"
- "For Google Calendar-specific integrations in 2025, the Google Calendar REST API is the clear choice"
- "CalDAV should primarily be considered for multi-platform calendar applications requiring standard protocol support"

### Strategic Recommendation

**Phase 1 (MVP): Google Calendar Only**

**Rationale:**
1. Faster time-to-value (1-2 weeks vs 3-4 weeks)
2. Better UX with webhooks (immediate sync)
3. Lower maintenance burden
4. User already considering switching to Google Calendar

**Implementation:**
- Build core CLI with Google Calendar adapter
- Design provider abstraction layer (interface defined)
- Leave CalDAV adapter as stub (interface implemented, but minimal functionality)
- Focus on perfecting AI agent orchestration and NLP

**Phase 2 (Optional): Add CalDAV Support**

**Trigger Conditions:**
- User has compelling need for iCloud calendar (shared with wife)
- Google Calendar proves insufficient
- User values data ownership over convenience

**Implementation:**
- Implement CalDAVAdapter following established interface
- Add polling sync mechanism
- Handle iCalendar parsing edge cases
- Test against iCloud specifically (not general CalDAV)

**Phase 3 (Future): Multi-Provider Aggregation**

**If needed:**
- Build AggregateCalendarProvider to merge multiple sources
- Handle conflict resolution across providers
- Unified view with provider attribution

### Migration Strategy (If Starting with Google)

**If user later wants CalDAV:**

```typescript
// Migration is easy because of abstraction layer

// Before (Google only)
const provider = new GoogleCalendarAdapter(config);

// After (CalDAV)
const provider = new CalDAVAdapter(config);

// Or both (aggregate)
const provider = new AggregateCalendarProvider([
  new GoogleCalendarAdapter(googleConfig),
  new CalDAVAdapter(caldavConfig)
]);

// CLI commands unchanged - abstraction layer handles differences
```

**Data migration:**
- Export events from Google Calendar (iCalendar format)
- Import to iCloud via CalDAV
- No CLI code changes needed

### Final Verdict

**Start with Google Calendar. Add CalDAV only if truly needed.**

The 3-4 week development time difference, ongoing maintenance burden, and lack of webhooks make CalDAV a poor choice for MVP. The abstraction layer design means adding CalDAV later is straightforward if requirements change.

---

## Technical Stack & Dependencies

### Core Technology Stack

**Runtime & Language:**
```json
{
  "runtime": "Bun 1.0+",
  "language": "TypeScript 5.3+",
  "strictMode": true,
  "target": "ES2022"
}
```

**Package Manager:**
```bash
# Bun for all JavaScript/TypeScript dependencies (not npm/yarn/pnpm)
bun install
bun run dev
bun test
```

**CLI Framework:**
```typescript
// Tier 1: Manual argument parsing (llcli-style) - RECOMMENDED FOR MVP
// - Zero dependencies for argument parsing
// - ~300-500 lines of code
// - Sufficient for 5-10 commands

// Tier 2: Commander.js - IF COMPLEXITY GROWS
// - Framework-based parsing
// - Subcommand support
// - Use only if Tier 1 becomes unwieldy (>10 commands)
```

### Required Dependencies

**Production Dependencies:**

```json
{
  "dependencies": {
    // Google Calendar API client
    "@googleapis/calendar": "^9.0.0",

    // CalDAV client (if implementing CalDAV)
    "tsdav": "^2.0.3",

    // Date/time handling (superior to moment.js)
    "date-fns": "^3.0.0",
    "date-fns-tz": "^2.0.0",

    // Local database for caching
    "better-sqlite3": "^9.2.2",

    // OAuth 2.0 helper
    "google-auth-library": "^9.4.0",

    // HTTP client (Bun has built-in fetch, but this adds retry logic)
    "ky": "^1.1.3",

    // Configuration management
    "dotenv": "^16.3.1",

    // CLI utilities
    "chalk": "^5.3.0",        // Colored output
    "ora": "^8.0.1",          // Spinners
    "prompts": "^2.4.2",      // Interactive prompts

    // iCalendar parsing (if CalDAV needed)
    "ical.js": "^1.5.0",

    // Encryption for credential storage
    "keytar": "^7.9.0"        // System keychain access
  }
}
```

**Development Dependencies:**

```json
{
  "devDependencies": {
    // TypeScript
    "typescript": "^5.3.3",
    "@types/node": "^20.10.6",
    "@types/better-sqlite3": "^7.6.8",

    // Testing
    "vitest": "^1.1.0",
    "@vitest/ui": "^1.1.0",

    // Linting & Formatting
    "eslint": "^8.56.0",
    "@typescript-eslint/eslint-plugin": "^6.17.0",
    "@typescript-eslint/parser": "^6.17.0",
    "prettier": "^3.1.1",

    // Build tools
    "bun-types": "^1.0.20"
  }
}
```

### Project Structure

```
${PAI_DIR}/bin/cal/
├── cal.ts                          # Main CLI entry point
├── package.json                    # Bun configuration
├── tsconfig.json                   # TypeScript strict mode config
├── .env.example                    # Environment template
├── README.md                       # Comprehensive documentation
├── QUICKSTART.md                   # Common usage patterns
│
├── lib/                            # Core library code
│   ├── providers/                  # Calendar provider adapters
│   │   ├── provider.interface.ts   # CalendarProvider interface
│   │   ├── google.adapter.ts       # Google Calendar implementation
│   │   └── caldav.adapter.ts       # CalDAV implementation (optional)
│   │
│   ├── models/                     # Domain models (provider-agnostic)
│   │   ├── event.model.ts
│   │   ├── calendar.model.ts
│   │   └── recurrence.model.ts
│   │
│   ├── cache/                      # Local caching layer
│   │   ├── database.ts             # SQLite setup and queries
│   │   └── sync-manager.ts         # Sync logic
│   │
│   ├── auth/                       # Authentication managers
│   │   ├── google-auth.ts          # OAuth 2.0 flow
│   │   ├── caldav-auth.ts          # Basic auth
│   │   └── credential-store.ts     # Secure credential storage
│   │
│   ├── ai/                         # AI agent integration
│   │   ├── intent-parser.ts        # Natural language intent extraction
│   │   ├── context-enricher.ts     # Event context enrichment
│   │   └── action-executor.ts      # CLI command execution
│   │
│   └── utils/                      # Utility functions
│       ├── date-parser.ts          # Natural language date parsing
│       ├── formatter.ts            # Output formatting
│       └── validators.ts           # Input validation
│
├── commands/                       # CLI command implementations
│   ├── list.command.ts
│   ├── create.command.ts
│   ├── update.command.ts
│   ├── delete.command.ts
│   ├── search.command.ts
│   ├── conflicts.command.ts
│   ├── agenda.command.ts
│   ├── sync.command.ts
│   └── config.command.ts
│
├── tests/                          # Test suite
│   ├── unit/                       # Unit tests (providers, models)
│   ├── integration/                # Integration tests (full workflows)
│   └── fixtures/                   # Test data
│
└── scripts/                        # Development scripts
    ├── setup-auth.ts               # Initial OAuth setup
    └── migrate-db.ts               # Database migrations
```

### Configuration Files

**tsconfig.json** (Strict mode):
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "outDir": "./dist",
    "rootDir": "./",
    "types": ["bun-types"]
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

**package.json**:
```json
{
  "name": "cal",
  "version": "0.1.0",
  "description": "AI-powered calendar CLI with natural language interface",
  "type": "module",
  "main": "cal.ts",
  "bin": {
    "cal": "./cal.ts"
  },
  "scripts": {
    "dev": "bun run cal.ts",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "lint": "eslint .",
    "format": "prettier --write .",
    "setup": "bun run scripts/setup-auth.ts"
  },
  "keywords": ["calendar", "cli", "ai", "natural-language"],
  "author": "PAI",
  "license": "MIT"
}
```

**.env.example**:
```bash
# Google Calendar API
GOOGLE_CLIENT_ID=your_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here

# CalDAV (if using iCloud)
CALDAV_SERVER_URL=https://caldav.icloud.com
CALDAV_USERNAME=your_apple_id@icloud.com
CALDAV_PASSWORD=your_app_specific_password

# AI Configuration
ANTHROPIC_API_KEY=your_anthropic_api_key

# Local Configuration
CACHE_DB_PATH=~/.config/cal/cache.db
CREDENTIALS_PATH=~/.config/cal/credentials.json
DEFAULT_CALENDAR=primary
DEFAULT_TIMEZONE=America/Los_Angeles

# Sync Configuration
SYNC_INTERVAL_MINUTES=5
ENABLE_WEBHOOKS=true
WEBHOOK_PORT=8888
```

### Database Schema (SQLite)

```sql
-- Events cache
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  calendar_id TEXT NOT NULL,
  provider TEXT NOT NULL, -- 'google' or 'caldav'
  title TEXT NOT NULL,
  description TEXT,
  start_time INTEGER NOT NULL, -- Unix timestamp
  end_time INTEGER NOT NULL,
  timezone TEXT NOT NULL,
  location TEXT,
  attendees TEXT, -- JSON array
  recurrence TEXT, -- iCalendar RRULE
  metadata TEXT, -- JSON object for provider-specific data
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  synced_at INTEGER NOT NULL
);

CREATE INDEX idx_events_start_time ON events(start_time);
CREATE INDEX idx_events_calendar_id ON events(calendar_id);
CREATE INDEX idx_events_provider ON events(provider);

-- Calendars
CREATE TABLE calendars (
  id TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT,
  is_default BOOLEAN DEFAULT 0,
  is_primary BOOLEAN DEFAULT 0,
  access_role TEXT,
  synced_at INTEGER NOT NULL
);

-- Sync state
CREATE TABLE sync_state (
  provider TEXT PRIMARY KEY,
  calendar_id TEXT NOT NULL,
  sync_token TEXT,
  last_sync INTEGER NOT NULL
);

-- User preferences
CREATE TABLE preferences (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

---

## Future Extensibility Considerations

### Extensibility Architecture

The system is designed for extensibility in five key dimensions:

**1. Provider Extensibility**
- **Current**: Google Calendar, CalDAV
- **Future**: Microsoft Outlook, Fastmail, Nextcloud, Any CalDAV server
- **Mechanism**: Implement `CalendarProvider` interface, register in provider factory
- **Effort**: 1-2 weeks per new provider

**2. AI Agent Extensibility**
- **Current**: Intent, Context, Action agents
- **Future Agents**:
  - **Meeting Prep Agent**: Gathers context before meetings (past notes, attendee info, relevant docs)
  - **Time Optimization Agent**: Analyzes calendar patterns, suggests improvements
  - **Travel Agent**: Adds travel time between locations, suggests departure times
  - **Email Integration Agent**: Parses meeting requests from email, auto-schedules
- **Mechanism**: PAI agent delegation patterns, Task tool
- **Effort**: 3-5 days per new agent

**3. Integration Extensibility**
- **Current**: Standalone CLI
- **Future Integrations**:
  - **Email**: Parse meeting invites, auto-create events
  - **Tasks**: Convert tasks to calendar blocks (timeboxing)
  - **Contacts**: Smart attendee suggestions based on past meetings
  - **Notes**: Link meeting notes to calendar events
  - **Slack**: `/cal` slash command for team calendars
  - **Voice Assistants**: Siri, Google Assistant integration
- **Mechanism**: Plugin architecture, webhook receivers
- **Effort**: 1-2 weeks per integration

**4. Output Format Extensibility**
- **Current**: JSON, formatted text
- **Future Formats**:
  - **iCalendar**: Export for import to other apps
  - **CSV**: Spreadsheet export for analysis
  - **Markdown**: Agenda format for notes
  - **HTML**: Web view for dashboard
  - **PDF**: Printable weekly/monthly views
- **Mechanism**: Output formatter plugins
- **Effort**: 1-3 days per format

**5. Command Extensibility**
- **Current**: 9 core commands (list, create, update, delete, search, conflicts, agenda, sync, config)
- **Future Commands**:
  - `cal analyze` - Calendar analytics (time spent in meetings, busiest days, etc.)
  - `cal optimize` - Suggest calendar optimizations
  - `cal template` - Save/load event templates
  - `cal batch` - Batch create/update from CSV/JSON
  - `cal export` - Export date range to various formats
  - `cal import` - Import from other calendar systems
  - `cal remind` - Custom reminder management
- **Mechanism**: New command files in `commands/` directory
- **Effort**: 1-5 days per command

### Plugin System Design (Future)

**Phase 3+ Feature: Plugin Architecture**

```typescript
// Plugin interface
interface CalendarPlugin {
  name: string;
  version: string;

  // Lifecycle hooks
  onInstall?(): Promise<void>;
  onEnable?(): Promise<void>;
  onDisable?(): Promise<void>;

  // Command hooks
  commands?: Record<string, CommandHandler>;

  // Event hooks (intercept calendar operations)
  beforeEventCreate?(event: EventInput): Promise<EventInput>;
  afterEventCreate?(event: CalendarEvent): Promise<void>;

  // Provider hooks (add custom providers)
  providers?: Record<string, CalendarProvider>;

  // Output format hooks
  formatters?: Record<string, OutputFormatter>;
}

// Plugin manager
class PluginManager {
  private plugins: Map<string, CalendarPlugin> = new Map();

  async loadPlugin(path: string): Promise<void> {
    const plugin = await import(path);
    await plugin.onInstall?.();
    this.plugins.set(plugin.name, plugin);
  }

  async executeHook(hookName: string, ...args: unknown[]): Promise<void> {
    for (const plugin of this.plugins.values()) {
      await plugin[hookName]?.(...args);
    }
  }
}

// Example plugin: Meeting Prep
class MeetingPrepPlugin implements CalendarPlugin {
  name = 'meeting-prep';
  version = '1.0.0';

  async afterEventCreate(event: CalendarEvent): Promise<void> {
    // If event is a meeting with attendees
    if (event.attendees.length > 0) {
      // Create preparation tasks
      const prepTime = subHours(event.startTime, 1);
      await createTask({
        title: `Prepare for: ${event.title}`,
        dueDate: prepTime,
        notes: `Review notes, gather materials for ${event.title}`
      });
    }
  }
}
```

### API Extensibility

**Future: REST API Wrapper**

```typescript
// Turn CLI into REST API for web/mobile clients
import { serve } from 'bun';

serve({
  port: 3000,
  fetch(req) {
    const url = new URL(req.url);

    // REST API endpoints
    if (url.pathname === '/api/events') {
      return handleListEvents(req);
    }
    if (url.pathname === '/api/events/create') {
      return handleCreateEvent(req);
    }

    // Natural language endpoint
    if (url.pathname === '/api/nl') {
      const { query } = await req.json();
      return handleNaturalLanguage(query);
    }
  }
});

// Now accessible via HTTP
// POST /api/nl
// {"query": "Schedule lunch with Sarah tomorrow at noon"}
```

**Benefits:**
- Web dashboard on top of CLI
- Mobile app using same backend
- Zapier/IFTTT integration
- Team calendar server

### AI Model Extensibility

**Model Swapping:**

```typescript
// Support multiple AI providers
interface AIProvider {
  parseIntent(input: string): Promise<Intent>;
  enrichContext(intent: Intent, context: Context): Promise<EnrichedEvent>;
}

class ClaudeAIProvider implements AIProvider {
  async parseIntent(input: string): Promise<Intent> {
    // Use Anthropic API
  }
}

class OpenAIProvider implements AIProvider {
  async parseIntent(input: string): Promise<Intent> {
    // Use OpenAI API
  }
}

class LocalLLMProvider implements AIProvider {
  async parseIntent(input: string): Promise<Intent> {
    // Use local Ollama/LLaMA
  }
}

// Configurable
const aiProvider = new ClaudeAIProvider(); // or OpenAIProvider, LocalLLMProvider
```

**Benefits:**
- Cost optimization (use cheaper models for simple tasks)
- Privacy (local LLM for sensitive calendars)
- Vendor independence (not locked to Anthropic)

### Data Extensibility

**Custom Fields & Metadata:**

```typescript
// Extensible event metadata
interface CalendarEvent {
  // ... standard fields

  // Provider-specific metadata (preserved through sync)
  metadata: {
    google?: GoogleMetadata;
    caldav?: CalDAVMetadata;
    custom?: Record<string, unknown>; // User-defined fields
  };
}

// Example: Custom project tracking
await cal.createEvent({
  title: "Client meeting",
  // ... other fields
  metadata: {
    custom: {
      projectId: "proj_123",
      billable: true,
      clientName: "Acme Corp",
      tags: ["sales", "q1-2026"]
    }
  }
});

// Search by custom fields
await cal.searchEvents({
  filter: event => event.metadata.custom?.projectId === "proj_123"
});
```

### Observability & Monitoring Extensibility

**Future: Integration with PAI Observability Skill**

```typescript
// Send calendar operations to observability dashboard
import { notifyObservability } from '${PAI_DIR}/Skills/Observability';

await notifyObservability({
  agent: 'calendar-cli',
  operation: 'create_event',
  duration: 234, // ms
  success: true,
  metadata: {
    provider: 'google',
    eventType: 'meeting',
    attendeeCount: 3
  }
});

// Real-time dashboard shows:
// - Calendar API call latency
// - Event creation success rate
// - Most active calendars
// - AI agent performance metrics
```

### Scalability Considerations

**Multi-User Support (Future):**

```typescript
// Currently: Single user (Daniel)
// Future: Multi-user (family/team calendars)

interface UserContext {
  userId: string;
  defaultCalendar: string;
  preferences: UserPreferences;
  credentials: CredentialStore;
}

// Switch context
$ cal --user daniel list --today
$ cal --user sarah list --today

// Shared calendars
$ cal --calendar "Family" create "Vacation" --time "2026-06-01"
// Auto-shares with all family members
```

**Performance at Scale:**

- **Current**: Optimized for 1 user, ~100 events/month
- **Future**: Support 10+ users, 1000+ events/month
- **Techniques**:
  - Lazy loading (only fetch needed date ranges)
  - Aggressive caching with TTL
  - Background sync workers
  - Database indexing on all query patterns
  - Connection pooling for API clients

---

## Implementation Roadmap

### Phase 1: MVP (2 weeks)

**Week 1: Core CLI + Google Calendar**
- Day 1-2: Project setup, TypeScript configuration, Google Calendar OAuth
- Day 3-4: Implement GoogleCalendarAdapter, core CRUD operations
- Day 5-7: CLI commands (list, create, update, delete, search)

**Week 2: AI Integration + Polish**
- Day 8-9: Intent Agent (natural language parsing)
- Day 10-11: Context Agent (enrichment), Action Agent (execution)
- Day 12-13: Testing, documentation, demo preparation
- Day 14: User testing, bug fixes, README/QUICKSTART

**Deliverables:**
- Working CLI: `cal` command with 5-7 core commands
- Natural language support for event creation
- Google Calendar integration fully functional
- Basic caching for offline access
- Comprehensive documentation

**Success Criteria:**
- "Schedule lunch with Sarah tomorrow at noon" → Creates event correctly
- `cal list --today` → Shows today's events from Google Calendar
- Voice integration works (completion announcements)

### Phase 2: Enhanced Features (2 weeks)

**Week 3: Intelligence & Optimization**
- Conflict detection and resolution suggestions
- Smart scheduling (find optimal times)
- Meeting preparation automation
- Calendar analytics (`cal analyze`)

**Week 4: Multi-Calendar & Advanced Features**
- Multi-calendar support (work, personal, shared)
- Recurring event management
- Event templates
- Batch operations
- Export/import functionality

**Deliverables:**
- Intelligent conflict resolution
- Multi-calendar aggregation
- Advanced CLI commands (analyze, optimize, template, batch)
- Calendar pattern recognition

**Success Criteria:**
- System detects conflicts and suggests alternatives
- User can manage multiple calendars seamlessly
- Analytics provide actionable insights

### Phase 3: CalDAV & Extensibility (2 weeks, optional)

**Week 5: CalDAV Integration**
- Implement CalDAVAdapter
- iCalendar parsing and generation
- Polling sync mechanism
- iCloud-specific testing

**Week 6: Polish & Extensibility**
- Plugin system foundation
- REST API wrapper
- Web dashboard (basic)
- Mobile-friendly API endpoints

**Deliverables:**
- CalDAV support (iCloud tested)
- Multi-provider aggregation working
- Basic plugin system
- REST API for external integrations

**Success Criteria:**
- User can sync with both Google Calendar and iCloud
- Events appear correctly across providers
- Third-party apps can integrate via REST API

---

## Appendix: Technical Specifications

### CLI Command Reference

**Complete command specification:**

```bash
# List events
cal list [options]
  --today              # Today's events
  --tomorrow           # Tomorrow's events
  --week              # This week's events
  --month             # This month's events
  --from DATE         # Start date (YYYY-MM-DD)
  --to DATE           # End date (YYYY-MM-DD)
  --calendar NAME     # Filter by calendar
  --format FORMAT     # Output format (json|table|agenda)

# Create event
cal create TITLE [options]
  --time TIME         # Event time (ISO 8601 or natural: "tomorrow 2pm")
  --duration DURATION # Duration (e.g., "1h", "30m", "1h30m")
  --location LOCATION # Location/address
  --calendar NAME     # Target calendar
  --attendee EMAIL    # Add attendee (repeatable)
  --description TEXT  # Event description
  --recurrence RULE   # Recurrence rule (daily|weekly|monthly|RRULE)
  --send-invite       # Send calendar invites to attendees

# Update event
cal update EVENT_ID [options]
  --title TITLE       # New title
  --time TIME         # New time
  --duration DURATION # New duration
  --location LOCATION # New location
  --add-attendee EMAIL    # Add attendee
  --remove-attendee EMAIL # Remove attendee
  --description TEXT  # Update description
  --apply-to-series   # Apply to all recurrences

# Delete event
cal delete EVENT_ID [options]
  --confirm           # Skip confirmation prompt
  --this-only         # Delete only this occurrence (recurring events)

# Search events
cal search QUERY [options]
  --from DATE         # Search from date
  --to DATE           # Search to date
  --calendar NAME     # Search specific calendar
  --limit N           # Max results (default: 50)

# Check conflicts
cal conflicts [options]
  --date DATE         # Check specific date
  --week              # Check this week
  --calendar NAME     # Check specific calendar

# Show agenda
cal agenda [options]
  --today             # Today's agenda
  --tomorrow          # Tomorrow's agenda
  --week              # Weekly agenda
  --date DATE         # Specific date agenda

# Sync calendars
cal sync [options]
  --force             # Force full sync (ignore sync token)
  --background        # Run as background daemon
  --calendar NAME     # Sync specific calendar only

# Configure
cal config [options]
  --set KEY=VALUE     # Set configuration value
  --get KEY           # Get configuration value
  --list              # List all configuration
  --reset             # Reset to defaults

# Natural language mode
cal nl "natural language query"
  # Examples:
  cal nl "what's on my calendar tomorrow?"
  cal nl "schedule lunch with Sarah next Tuesday at noon"
  cal nl "cancel my 2pm meeting"
  cal nl "find time for coffee with John next week"
```

### API Response Schemas

**Event Response (JSON):**

```json
{
  "id": "evt_abc123",
  "title": "Lunch with Sarah",
  "description": "Discuss Q1 plans",
  "startTime": "2025-12-31T12:00:00-08:00",
  "endTime": "2025-12-31T13:00:00-08:00",
  "timezone": "America/Los_Angeles",
  "location": "Cafe Aurora, 123 Main St",
  "attendees": [
    {
      "email": "sarah@example.com",
      "displayName": "Sarah Smith",
      "responseStatus": "accepted"
    }
  ],
  "recurrence": null,
  "calendarId": "primary",
  "provider": "google",
  "metadata": {
    "google": {
      "htmlLink": "https://calendar.google.com/event?eid=...",
      "hangoutLink": null,
      "conferenceData": null
    }
  },
  "createdAt": "2025-12-28T10:30:00Z",
  "updatedAt": "2025-12-28T10:30:00Z"
}
```

**List Response (JSON):**

```json
{
  "events": [
    {
      "id": "evt_abc123",
      "title": "Team Standup",
      "startTime": "2025-12-28T09:00:00-08:00",
      "endTime": "2025-12-28T09:30:00-08:00",
      "calendar": "Work"
    },
    {
      "id": "evt_def456",
      "title": "Product Review",
      "startTime": "2025-12-28T11:00:00-08:00",
      "endTime": "2025-12-28T12:00:00-08:00",
      "calendar": "Work"
    }
  ],
  "total": 2,
  "from": "2025-12-28T00:00:00-08:00",
  "to": "2025-12-28T23:59:59-08:00"
}
```

**Conflict Response (JSON):**

```json
{
  "conflicts": [
    {
      "time": "2025-12-29T14:00:00-08:00",
      "events": [
        {
          "id": "evt_123",
          "title": "Client call",
          "calendar": "Work"
        },
        {
          "id": "evt_456",
          "title": "Team meeting",
          "calendar": "Work"
        }
      ],
      "severity": "hard",
      "suggestion": "Reschedule 'Team meeting' to 3:00 PM (next available slot)"
    }
  ],
  "softConflicts": [
    {
      "reason": "Back-to-back meetings with no buffer",
      "events": ["evt_789", "evt_012"],
      "suggestion": "Add 15-minute buffer between meetings"
    }
  ]
}
```

### Error Codes

**Standard error response:**

```json
{
  "error": {
    "code": "CONFLICT_DETECTED",
    "message": "Event overlaps with existing event 'Client call'",
    "details": {
      "conflictingEventId": "evt_123",
      "conflictingEventTitle": "Client call",
      "suggestedTimes": [
        "2025-12-29T15:00:00-08:00",
        "2025-12-29T16:00:00-08:00"
      ]
    }
  }
}
```

**Error code reference:**

| Code | Description | HTTP Status | Resolution |
|------|-------------|-------------|------------|
| `INVALID_INPUT` | Invalid command arguments | 400 | Check syntax with --help |
| `AUTHENTICATION_REQUIRED` | Not authenticated | 401 | Run `cal config --setup` |
| `FORBIDDEN` | Insufficient permissions | 403 | Check calendar access rights |
| `NOT_FOUND` | Event/calendar not found | 404 | Verify ID is correct |
| `CONFLICT_DETECTED` | Event conflict exists | 409 | Resolve conflict or force |
| `RATE_LIMIT_EXCEEDED` | API rate limit hit | 429 | Wait and retry |
| `PROVIDER_ERROR` | Calendar provider error | 502 | Check provider status |
| `SYNC_FAILED` | Sync operation failed | 503 | Retry sync |

---

## Research Sources & References

**Google Calendar API vs CalDAV:**
- [Google Calendar API Developer's Guide](https://developers.google.com/workspace/calendar)
- [Building a Unified Calendar API - DEV Community](https://dev.to/anthony_cole_d8330ab71208/building-a-unified-calendar-api-lessons-from-aggregating-google-calendar-caldav-and-jira-3ei8)
- [Best Calendar APIs in 2025 - Cronofy](https://www.cronofy.com/blog/best-calendar-apis)

**Natural Language Calendar Tools:**
- [The 9 best AI scheduling assistants - Zapier](https://zapier.com/blog/best-ai-scheduling/)
- [Neocal: AI-powered calendar app](https://www.toolify.ai/tool/neocal)
- [AI Calendar Tools 2025 - Saner.AI](https://www.saner.ai/blogs/best-ai-calendar)

**AI Agent Delegation:**
- [AI Agent Orchestration Patterns - Microsoft Learn](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
- [Google's Agent Development Kit](https://google.github.io/adk-docs/)
- [CrewAI Framework](https://github.com/crewAIInc/crewAI)

**TypeScript Calendar Libraries:**
- [FullCalendar TypeScript Support](https://fullcalendar.io/docs/typescript)
- [Temporal API - MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal)

---

**END OF ARCHITECTURAL DESIGN DOCUMENT**

This document provides a complete architectural blueprint for building an AI agent-driven calendar CLI that follows PAI's CLI-First Architecture, leverages existing agent infrastructure, and delivers an exceptional natural language user experience. The recommendation to start with Google Calendar and design for extensibility provides the fastest path to value while maintaining flexibility for future requirements.
