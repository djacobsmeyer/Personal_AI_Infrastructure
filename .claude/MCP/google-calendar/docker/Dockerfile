# Multi-stage build for Google Calendar MCP Server
# Optimized for Bun runtime with minimal attack surface

FROM oven/bun:1.3.5-alpine AS base
LABEL maintainer="PAI System"
LABEL description="Google Calendar MCP Server with Bun runtime"

# Security: Run as non-root user
RUN addgroup -g 1001 -S mcp && \
    adduser -u 1001 -S mcp -G mcp

WORKDIR /app

# Install package
FROM base AS dependencies
RUN bun install --global @cocal/google-calendar-mcp@2.2.0

# Production stage
FROM base AS production

# Copy installed package from dependencies stage
COPY --from=dependencies /root/.bun/install/global /root/.bun/install/global

# Create directories for credentials and tokens
RUN mkdir -p /app/credentials /app/tokens && \
    chown -R mcp:mcp /app

# Switch to non-root user
USER mcp

# Volume mounts for persistent data
VOLUME ["/app/credentials", "/app/tokens"]

# Environment variables
ENV GOOGLE_OAUTH_CREDENTIALS=/app/credentials/credentials.json
ENV GOOGLE_CALENDAR_MCP_TOKEN_PATH=/app/tokens

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD bunx --bun @cocal/google-calendar-mcp version || exit 1

# Expose MCP stdio interface (no ports needed for stdio protocol)
ENTRYPOINT ["bunx", "--bun", "@cocal/google-calendar-mcp"]

# Default command: start server
CMD ["start"]
