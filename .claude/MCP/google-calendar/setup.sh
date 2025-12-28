#!/usr/bin/env bash
#
# Google Calendar MCP Server - Automated Setup Script
# Author: PAI System
# Description: Interactive setup wizard for Google Calendar MCP integration
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAI_DIR="/Users/donjacobsmeyer/PAI"
MCP_CONFIG="${PAI_DIR}/.claude/.mcp.json"
CREDENTIALS_DIR="${SCRIPT_DIR}/credentials"
TOKENS_DIR="${SCRIPT_DIR}/tokens"
CREDENTIALS_FILE="${CREDENTIALS_DIR}/credentials.json"

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Banner
print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║   Google Calendar MCP Server - Setup Wizard              ║
║   PAI System - Automated Configuration                   ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=0

    # Check Bun
    if ! command -v bun &> /dev/null; then
        log_error "Bun is not installed"
        echo "  Install: curl -fsSL https://bun.sh/install | bash"
        ((missing++))
    else
        log_success "Bun installed: $(bun --version)"
    fi

    # Check Docker (optional)
    if ! command -v docker &> /dev/null; then
        log_warning "Docker not installed (optional for containerized deployment)"
    else
        log_success "Docker installed: $(docker --version | cut -d' ' -f3)"
    fi

    # Check jq
    if ! command -v jq &> /dev/null; then
        log_warning "jq not installed (optional for JSON validation)"
        echo "  Install: brew install jq"
    else
        log_success "jq installed: $(jq --version)"
    fi

    if [ $missing -gt 0 ]; then
        log_error "Missing required dependencies. Please install and re-run."
        exit 1
    fi
}

# Create directory structure
setup_directories() {
    log_info "Creating directory structure..."

    mkdir -p "${CREDENTIALS_DIR}"
    mkdir -p "${TOKENS_DIR}"

    # Set permissions
    chmod 755 "${CREDENTIALS_DIR}"
    chmod 755 "${TOKENS_DIR}"

    log_success "Directories created"
}

# Check for existing credentials
check_credentials() {
    if [ -f "${CREDENTIALS_FILE}" ]; then
        log_success "Existing credentials.json found"

        # Validate JSON
        if command -v jq &> /dev/null; then
            if jq empty "${CREDENTIALS_FILE}" 2>/dev/null; then
                log_success "credentials.json is valid JSON"
            else
                log_error "credentials.json is invalid JSON"
                return 1
            fi
        fi

        return 0
    else
        log_warning "No credentials.json found"
        return 1
    fi
}

# Interactive credential setup
setup_credentials() {
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  OAuth Credentials Setup${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "To use Google Calendar MCP, you need OAuth 2.0 credentials."
    echo ""
    echo "Steps:"
    echo "  1. Go to: https://console.cloud.google.com/"
    echo "  2. Create/select a project"
    echo "  3. Enable Google Calendar API"
    echo "  4. Create OAuth 2.0 credentials (type: Desktop app)"
    echo "  5. Download the JSON file"
    echo ""

    read -p "Have you completed these steps? (y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Please complete OAuth setup first, then re-run this script"
        exit 0
    fi

    echo ""
    read -p "Enter the path to your downloaded credentials JSON file: " cred_path

    if [ ! -f "$cred_path" ]; then
        log_error "File not found: $cred_path"
        exit 1
    fi

    # Validate JSON
    if command -v jq &> /dev/null; then
        if ! jq empty "$cred_path" 2>/dev/null; then
            log_error "Invalid JSON file"
            exit 1
        fi

        # Check for required fields
        if ! jq -e '.installed // .web' "$cred_path" &>/dev/null; then
            log_error "Invalid credentials format (missing 'installed' or 'web' key)"
            exit 1
        fi
    fi

    # Copy to credentials directory
    cp "$cred_path" "${CREDENTIALS_FILE}"
    chmod 600 "${CREDENTIALS_FILE}"

    log_success "Credentials file installed and secured"
}

# Setup OAuth consent screen
setup_oauth_consent() {
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  OAuth Consent Screen${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Configure the OAuth consent screen:"
    echo ""
    echo "  1. Go to: https://console.cloud.google.com/apis/credentials/consent"
    echo "  2. User type: External (for personal) or Internal (for workspace)"
    echo "  3. Add your email as a test user"
    echo "  4. Required scopes (auto-configured by package):"
    echo "     - https://www.googleapis.com/auth/calendar.events"
    echo "     - https://www.googleapis.com/auth/calendar"
    echo ""

    read -p "Have you configured the OAuth consent screen? (y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "OAuth consent screen must be configured"
        exit 1
    fi
}

# Run authentication
run_authentication() {
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Authentication${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    log_info "Starting OAuth authentication flow..."
    echo ""
    echo "A browser window will open for Google OAuth consent."
    echo "Please grant the requested permissions."
    echo ""

    read -p "Press Enter to continue..."

    # Set environment variable and run auth
    export GOOGLE_OAUTH_CREDENTIALS="${CREDENTIALS_FILE}"

    if bunx --bun @cocal/google-calendar-mcp auth; then
        log_success "Authentication successful"

        # Check token was created
        if [ -f "${TOKENS_DIR}/token.json" ]; then
            chmod 600 "${TOKENS_DIR}/token.json"
            log_success "Token saved and secured"
        else
            log_warning "Token file not found (may be in different location)"
        fi
    else
        log_error "Authentication failed"
        exit 1
    fi
}

# Choose deployment method
choose_deployment() {
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Deployment Method${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Choose your deployment method:"
    echo ""
    echo "  1) Direct Bun execution (Recommended for PAI)"
    echo "     - No orphaned processes"
    echo "     - Fast startup"
    echo "     - Claude Code manages lifecycle"
    echo ""
    echo "  2) Docker ephemeral"
    echo "     - Process isolation"
    echo "     - Resource limits"
    echo "     - Slower startup"
    echo ""
    echo "  3) Docker persistent service"
    echo "     - Fast connection"
    echo "     - Single container"
    echo "     - Manual management"
    echo ""

    read -p "Select option (1-3): " -n 1 -r deployment_choice
    echo ""

    case $deployment_choice in
        1)
            DEPLOYMENT_TYPE="bun"
            ;;
        2)
            DEPLOYMENT_TYPE="docker-ephemeral"
            ;;
        3)
            DEPLOYMENT_TYPE="docker-persistent"
            ;;
        *)
            log_error "Invalid selection"
            exit 1
            ;;
    esac
}

# Configure MCP server
configure_mcp() {
    echo ""
    log_info "Configuring MCP server in .mcp.json..."

    # Backup existing config
    if [ -f "${MCP_CONFIG}" ]; then
        cp "${MCP_CONFIG}" "${MCP_CONFIG}.backup.$(date +%Y%m%d-%H%M%S)"
        log_info "Backed up existing .mcp.json"
    fi

    local config_snippet

    case $DEPLOYMENT_TYPE in
        bun)
            config_snippet=$(cat <<EOF
{
  "google-calendar": {
    "command": "bunx",
    "args": [
      "--bun",
      "@cocal/google-calendar-mcp"
    ],
    "env": {
      "GOOGLE_OAUTH_CREDENTIALS": "${CREDENTIALS_FILE}",
      "GOOGLE_CALENDAR_MCP_TOKEN_PATH": "${TOKENS_DIR}"
    },
    "description": "Google Calendar management with event creation, search, and scheduling"
  }
}
EOF
)
            ;;
        docker-ephemeral)
            config_snippet=$(cat <<EOF
{
  "google-calendar": {
    "command": "docker",
    "args": [
      "compose",
      "-f",
      "${SCRIPT_DIR}/docker/docker-compose.yml",
      "run",
      "--rm",
      "google-calendar-mcp"
    ],
    "description": "Google Calendar management (containerized)"
  }
}
EOF
)
            ;;
        docker-persistent)
            config_snippet=$(cat <<EOF
{
  "google-calendar": {
    "command": "docker",
    "args": [
      "exec",
      "-i",
      "gcal-mcp",
      "bunx",
      "--bun",
      "@cocal/google-calendar-mcp",
      "start"
    ],
    "description": "Google Calendar management (containerized service)"
  }
}
EOF
)
            ;;
    esac

    echo ""
    echo -e "${BLUE}Configuration to add:${NC}"
    echo "$config_snippet"
    echo ""

    log_warning "Manual step required:"
    echo "  1. Open: ${MCP_CONFIG}"
    echo "  2. Add the configuration above under 'mcpServers' key"
    echo "  3. Ensure valid JSON syntax (no trailing commas)"
    echo ""

    read -p "Press Enter when done..."
}

# Build Docker image (if needed)
build_docker() {
    if [[ $DEPLOYMENT_TYPE == docker-* ]]; then
        echo ""
        log_info "Building Docker image..."

        cd "${SCRIPT_DIR}/docker"

        if docker compose build; then
            log_success "Docker image built successfully"
        else
            log_error "Docker build failed"
            exit 1
        fi

        if [[ $DEPLOYMENT_TYPE == "docker-persistent" ]]; then
            log_info "Starting Docker container..."

            if docker compose up -d; then
                log_success "Container started"
            else
                log_error "Failed to start container"
                exit 1
            fi
        fi
    fi
}

# Test installation
test_installation() {
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Testing Installation${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    log_info "Testing package version..."

    if bunx --bun @cocal/google-calendar-mcp version; then
        log_success "Package executable"
    else
        log_error "Package test failed"
        return 1
    fi

    echo ""
    log_info "File permissions:"
    ls -la "${CREDENTIALS_DIR}" "${TOKENS_DIR}"

    echo ""
    log_success "Installation test complete"
}

# Print next steps
print_next_steps() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Setup Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Restart Claude Code completely (Quit + Reopen)"
    echo "  2. Verify MCP server appears in Claude Code"
    echo "  3. Test with: 'List my calendar events for today'"
    echo ""
    echo "Documentation:"
    echo "  - Quick start: ${SCRIPT_DIR}/QUICKSTART.md"
    echo "  - Full guide:  ${SCRIPT_DIR}/README.md"
    echo "  - Docker:      ${SCRIPT_DIR}/docker/DOCKER.md"
    echo "  - Security:    ${SCRIPT_DIR}/SECURITY.md"
    echo "  - Troubleshoot: ${SCRIPT_DIR}/TROUBLESHOOTING.md"
    echo ""

    if [[ $DEPLOYMENT_TYPE == "docker-persistent" ]]; then
        echo "Docker commands:"
        echo "  - Stop:    cd ${SCRIPT_DIR}/docker && docker compose down"
        echo "  - Logs:    docker compose logs -f google-calendar-mcp"
        echo "  - Restart: docker compose restart"
        echo ""
    fi

    echo -e "${BLUE}Happy scheduling! 📅${NC}"
    echo ""
}

# Main execution
main() {
    print_banner
    check_prerequisites
    setup_directories

    if ! check_credentials; then
        setup_credentials
    fi

    setup_oauth_consent
    run_authentication
    choose_deployment
    configure_mcp
    build_docker
    test_installation
    print_next_steps
}

# Run main function
main "$@"
