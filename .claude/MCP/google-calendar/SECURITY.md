# Google Calendar MCP - Security Guide

## Security Overview

The Google Calendar MCP server handles sensitive authentication credentials and access tokens that grant calendar access. This guide covers security best practices, threat modeling, and mitigation strategies.

## Threat Model

### Assets to Protect

1. **OAuth Client Credentials** (`credentials.json`)
   - Contains: client_id, client_secret, redirect URIs
   - Sensitivity: MEDIUM
   - Impact if compromised: Attacker can impersonate your application
   - Mitigation: Don't commit to git, restrict file permissions

2. **Refresh Tokens** (`tokens/token.json`)
   - Contains: refresh_token, access_token
   - Sensitivity: HIGH
   - Impact if compromised: Full calendar access until revoked
   - Mitigation: Encrypt at rest, restrict file permissions, monitor access

3. **Calendar Data**
   - Contains: Events, schedules, attendees, locations
   - Sensitivity: HIGH (PII/business confidential)
   - Impact if compromised: Privacy breach, data leak
   - Mitigation: OAuth scopes, least privilege, audit logging

### Attack Vectors

1. **File System Access**
   - Attacker reads credentials.json or token.json
   - Mitigation: File permissions (600), directory permissions (755)

2. **Process Memory**
   - Attacker dumps MCP server process memory
   - Mitigation: Short-lived access tokens, process isolation

3. **Network Interception**
   - Man-in-the-middle attack on OAuth flow
   - Mitigation: HTTPS enforced, certificate validation

4. **Container Escape** (Docker deployments)
   - Attacker escapes container to access host
   - Mitigation: Non-root user, read-only mounts, no-new-privileges

5. **Git Repository Exposure**
   - Credentials committed to version control
   - Mitigation: .gitignore, git-secrets, pre-commit hooks

## Security Best Practices

### 1. File System Security

#### Credential Files

```bash
# Set restrictive permissions
chmod 600 /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json
chmod 600 /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/tokens/token.json

# Directory permissions (executable for traversal)
chmod 755 /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials
chmod 755 /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/tokens

# Verify ownership
chown -R $(whoami):$(id -gn) /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar
```

#### .gitignore Protection

```bash
# Add to .gitignore
cat >> /Users/donjacobsmeyer/PAI/.gitignore << 'EOF'

# Google Calendar MCP Credentials
.claude/MCP/google-calendar/credentials/*.json
.claude/MCP/google-calendar/tokens/*.json
.claude/MCP/google-calendar/.env
EOF

# Verify not tracked
git status --ignored | grep credentials
```

#### Git-Secrets Protection

```bash
# Install git-secrets
brew install git-secrets  # macOS
# or: git clone https://github.com/awslabs/git-secrets

# Initialize in repository
cd /Users/donjacobsmeyer/PAI
git secrets --install
git secrets --register-aws  # Also catches generic secrets

# Add custom patterns
git secrets --add 'client_secret.*'
git secrets --add 'refresh_token.*'
git secrets --add '"access_token"'

# Scan existing repository
git secrets --scan
```

### 2. OAuth Security

#### Consent Screen Configuration

1. **User Type**: External (for personal) or Internal (for workspace)
2. **Verification Status**: Unverified (test mode) is acceptable for personal use
3. **Scopes**: Minimal necessary
   - `https://www.googleapis.com/auth/calendar.events` - Event management
   - `https://www.googleapis.com/auth/calendar` - Calendar access
4. **Test Users**: Add only trusted email addresses
5. **Publishing**: Keep in "Testing" mode for personal use

#### OAuth Best Practices

```json
// In Google Cloud Console credentials:
{
  "redirect_uris": [
    "http://localhost:3000/oauth2callback"  // Localhost only
  ],
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",  // HTTPS enforced
  "token_uri": "https://oauth2.googleapis.com/token"  // HTTPS enforced
}
```

**Do NOT**:
- Use public redirect URIs
- Share client_secret publicly
- Use production credentials for testing
- Skip consent screen setup

### 3. Token Management

#### Token Lifecycle

```
1. Initial Auth → Refresh Token (long-lived, 7 days in test mode)
2. Refresh Token → Access Token (short-lived, 1 hour)
3. Access Token → API Requests (until expiration)
4. Expiration → Auto-refresh using Refresh Token
```

#### Token Storage

**Current**: Plain JSON files
```bash
# tokens/token.json structure
{
  "type": "authorized_user",
  "client_id": "...",
  "client_secret": "...",
  "refresh_token": "1//...",  # SENSITIVE
  "access_token": "ya29...",   # SENSITIVE
  "expiry_date": 1234567890
}
```

**Recommended**: Encrypted storage (future enhancement)
```bash
# Option 1: Encrypted file
gpg --encrypt tokens/token.json
gpg --decrypt tokens/token.json.gpg > tokens/token.json

# Option 2: System keychain (macOS)
security add-generic-password -a google-calendar-mcp -s refresh_token -w "TOKEN_VALUE"

# Option 3: Secrets manager (production)
# AWS Secrets Manager, HashiCorp Vault, etc.
```

#### Token Revocation

Manual revocation (if compromised):

1. Go to: https://myaccount.google.com/permissions
2. Find "Claude Code Calendar Access" (or your app name)
3. Click "Remove Access"
4. Delete local token: `rm tokens/token.json`
5. Re-authenticate: `bunx --bun @cocal/google-calendar-mcp auth`

Automatic revocation:
- Test mode: Tokens auto-expire after 7 days
- Production mode: Tokens valid indefinitely (until revoked)

### 4. Container Security (Docker)

#### Dockerfile Security

```dockerfile
# 1. Minimal base image
FROM oven/bun:1.3.5-alpine  # Alpine = smaller attack surface

# 2. Non-root user
RUN addgroup -g 1001 -S mcp && \
    adduser -u 1001 -S mcp -G mcp
USER mcp  # All operations as non-root

# 3. No new privileges
# Set in docker-compose.yml:
security_opt:
  - no-new-privileges:true

# 4. Read-only root filesystem (where possible)
read_only: false  # Need /tmp for token ops, but minimize writable areas
```

#### Volume Security

```yaml
# docker-compose.yml
volumes:
  # Read-only credentials (cannot be modified by container)
  - ../credentials:/app/credentials:ro

  # Read-write tokens (needed for refresh)
  - ../tokens:/app/tokens:rw
```

#### Network Isolation

```yaml
# For post-auth operation (maximum security)
network_mode: none  # No network access

# For auth flow (required for OAuth)
network_mode: bridge  # Temporary network access

# Best practice: Switch modes
# 1. Use bridge for initial auth
# 2. Switch to none for production
# 3. Switch back to bridge if token refresh needed
```

#### Resource Limits

```yaml
# Prevent resource exhaustion attacks
deploy:
  resources:
    limits:
      cpus: '0.5'      # Max 50% of one core
      memory: 256M     # Max 256MB RAM
    reservations:
      cpus: '0.1'      # Min 10% of one core
      memory: 64M      # Min 64MB RAM
```

### 5. Process Isolation

#### Bun Process Security

```bash
# Run with minimal privileges
bunx --bun @cocal/google-calendar-mcp

# Process runs as current user (not root)
ps aux | grep google-calendar-mcp
# Should show your username, not root
```

#### Environment Variable Security

```json
// In .mcp.json
{
  "env": {
    // GOOD: Absolute path, no secrets in value
    "GOOGLE_OAUTH_CREDENTIALS": "/Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/credentials/credentials.json",

    // BAD: Embedded secret in environment
    "GOOGLE_CLIENT_SECRET": "GOCSPX-actual-secret-here"  // Don't do this
  }
}
```

**Rule**: Environment variables should point to files, not contain secrets directly.

### 6. Audit and Monitoring

#### Access Logging

Monitor who/what accesses your calendar:

1. **Google Account Activity**:
   - https://myaccount.google.com/activity
   - Review "Security" events
   - Check for unexpected access

2. **OAuth Audit Log**:
   - Google Cloud Console → "APIs & Services" → "Credentials"
   - Click on OAuth client
   - Review "Usage" metrics

3. **File Access Monitoring** (macOS):
   ```bash
   # Enable file access logging
   sudo log stream --predicate 'eventMessage contains "credentials.json"'
   ```

#### Anomaly Detection

Watch for:
- Token files accessed by unexpected processes
- Network connections from MCP server (should be minimal)
- Unusual calendar API calls (bulk deletes, mass updates)
- Failed authentication attempts

### 7. Multi-Account Security

#### Account Isolation

```bash
# Separate credentials per account
credentials/
  ├── credentials-work.json      # Work account
  └── credentials-personal.json  # Personal account

tokens/
  ├── token-work.json
  └── token-personal.json
```

#### Configuration

```json
// Separate MCP servers = separate processes = isolation
{
  "google-calendar-work": {
    "env": {
      "GOOGLE_OAUTH_CREDENTIALS": ".../credentials-work.json"
    }
  },
  "google-calendar-personal": {
    "env": {
      "GOOGLE_OAUTH_CREDENTIALS": ".../credentials-personal.json"
    }
  }
}
```

**Benefit**: Compromise of one account doesn't affect the other.

### 8. Compliance Considerations

#### GDPR Compliance

- **Data Minimization**: Only request necessary scopes
- **Purpose Limitation**: Use calendar data only for intended purpose
- **Storage Limitation**: Don't cache calendar data unnecessarily
- **Right to Erasure**: Provide token revocation instructions

#### Data Residency

- **Google Calendar API**: Data stored in Google's infrastructure
- **Token Storage**: Local filesystem (your jurisdiction)
- **MCP Server**: Ephemeral in-memory processing (no persistent storage)

#### Access Control

- **Principle of Least Privilege**: Minimal OAuth scopes
- **Need-to-Know**: Only authorized users have access to credentials
- **Separation of Duties**: Work vs personal account separation

## Security Checklist

### Pre-Deployment

- [ ] OAuth credentials created as "Desktop app" type
- [ ] Consent screen configured with minimal scopes
- [ ] Test users list contains only authorized emails
- [ ] credentials.json has 600 permissions
- [ ] credentials.json added to .gitignore
- [ ] Git-secrets installed and configured
- [ ] Strong file permissions on parent directories

### Post-Deployment

- [ ] Token successfully generated and stored
- [ ] token.json has 600 permissions
- [ ] MCP server running as non-root user (Bun/Docker)
- [ ] No credentials committed to version control
- [ ] OAuth consent screen reviewed and approved
- [ ] Access logging enabled
- [ ] Regular token rotation schedule established (if production)

### Ongoing Maintenance

- [ ] Monthly review of OAuth access at https://myaccount.google.com/permissions
- [ ] Quarterly credential rotation (regenerate credentials.json)
- [ ] Monitor Google Cloud Console for unusual API usage
- [ ] Keep @cocal/google-calendar-mcp package updated
- [ ] Review file permissions after system updates
- [ ] Audit logs for unexpected access patterns

## Incident Response

### If Credentials Compromised

1. **Immediate Actions**:
   ```bash
   # Revoke OAuth access
   # Visit: https://myaccount.google.com/permissions
   # Remove "Claude Code Calendar Access"

   # Delete local tokens
   rm /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/tokens/*.json

   # Regenerate credentials in Google Cloud Console
   # Delete old OAuth client
   # Create new OAuth client
   # Download new credentials.json
   ```

2. **Investigation**:
   - Check git history for credential commits
   - Review file access logs
   - Identify compromise vector
   - Assess calendar data exposure

3. **Recovery**:
   - Generate new OAuth credentials
   - Re-authenticate with new credentials
   - Monitor for unauthorized calendar access
   - Document incident and lessons learned

### If Token Compromised

1. **Immediate Actions**:
   ```bash
   # Revoke token
   # Visit: https://myaccount.google.com/permissions

   # Delete local token
   rm /Users/donjacobsmeyer/PAI/.claude/MCP/google-calendar/tokens/token.json

   # Re-authenticate
   bunx --bun @cocal/google-calendar-mcp auth
   ```

2. **Assessment**:
   - Review calendar activity for unauthorized changes
   - Check for data exfiltration
   - Identify how token was compromised

3. **Prevention**:
   - Improve file permissions
   - Enable stricter access controls
   - Consider encrypted token storage

## Advanced Security (Optional)

### Encrypted Token Storage

```bash
# Encrypt tokens at rest
gpg --symmetric --cipher-algo AES256 tokens/token.json

# Decrypt on use (requires integration with MCP server)
gpg --decrypt tokens/token.json.gpg > /tmp/token.json
GOOGLE_CALENDAR_MCP_TOKEN_PATH=/tmp bunx @cocal/google-calendar-mcp
rm /tmp/token.json  # Clean up
```

### Secrets Manager Integration

For production deployments, consider:

1. **AWS Secrets Manager**
2. **HashiCorp Vault**
3. **Azure Key Vault**
4. **Google Secret Manager**

These provide:
- Encryption at rest and in transit
- Access audit logging
- Automatic rotation
- Fine-grained access control

### Certificate Pinning

Prevent MITM attacks:

```javascript
// Custom HTTP client with certificate pinning
// (Requires modification of @cocal/google-calendar-mcp or wrapper)
const https = require('https');
const options = {
  hostname: 'oauth2.googleapis.com',
  ca: fs.readFileSync('google-ca-cert.pem')  // Pin Google's CA
};
```

## Security Resources

- **OAuth 2.0 Security Best Practices**: https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics
- **Google OAuth 2.0 Documentation**: https://developers.google.com/identity/protocols/oauth2
- **MCP Security Guidelines**: https://modelcontextprotocol.io/security
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/

## Questions?

For security concerns or to report vulnerabilities:
- Package: https://github.com/nspady/google-calendar-mcp/security/advisories
- PAI: Contact system administrator
