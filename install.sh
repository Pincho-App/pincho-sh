#!/bin/sh
#
# WirePusher Shell Scripts Installer
#
# This script downloads and installs the WirePusher shell script library.
#
# Usage:
#   curl -sL https://gitlab.com/wirepusher/wirepusher-sh/-/raw/main/install.sh | sh
#
# Or with custom install location:
#   INSTALL_DIR=/opt/wirepusher sh install.sh
#

set -e

# Colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Configuration
REPO_URL="https://gitlab.com/wirepusher/wirepusher-sh/-/raw/main"
DEFAULT_INSTALL_DIR="/usr/local/lib/wirepusher"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"

# Check if running with sudo when needed
check_sudo() {
    if [ "$(id -u)" -ne 0 ] && [ "$INSTALL_DIR" = "$DEFAULT_INSTALL_DIR" ]; then
        printf "${YELLOW}⚠️  Installing to %s requires sudo privileges${NC}\n" "$INSTALL_DIR"
        printf "${YELLOW}   Run with: sudo sh install.sh${NC}\n"
        printf "${YELLOW}   Or install to home directory: INSTALL_DIR=~/.local/lib/wirepusher sh install.sh${NC}\n\n"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    printf "${BLUE}Checking dependencies...${NC}\n"

    if ! command -v curl >/dev/null 2>&1; then
        printf "${RED}✗ curl is not installed${NC}\n"
        printf "  Please install curl and try again\n"
        exit 1
    fi
    printf "${GREEN}✓ curl is installed${NC}\n"

    # Check for bash (optional)
    if command -v bash >/dev/null 2>&1; then
        bash_version=$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        printf "${GREEN}✓ bash ${bash_version} is installed${NC}\n"
    fi
}

# Create installation directory
create_install_dir() {
    printf "\n${BLUE}Creating installation directory...${NC}\n"

    if [ -d "$INSTALL_DIR" ]; then
        printf "${YELLOW}Directory already exists: %s${NC}\n" "$INSTALL_DIR"
    else
        if mkdir -p "$INSTALL_DIR"; then
            printf "${GREEN}✓ Created directory: %s${NC}\n" "$INSTALL_DIR"
        else
            printf "${RED}✗ Failed to create directory: %s${NC}\n" "$INSTALL_DIR"
            exit 1
        fi
    fi
}

# Download file
download_file() {
    url="$1"
    dest="$2"
    name="$3"

    printf "  Downloading %s..." "$name"

    if curl -fsSL -o "$dest" "$url"; then
        printf " ${GREEN}✓${NC}\n"
        return 0
    else
        printf " ${RED}✗${NC}\n"
        return 1
    fi
}

# Install library files
install_files() {
    printf "\n${BLUE}Installing library files...${NC}\n"

    # Download POSIX sh version
    if ! download_file "$REPO_URL/wirepusher.sh" "$INSTALL_DIR/wirepusher.sh" "wirepusher.sh"; then
        printf "${RED}Failed to download wirepusher.sh${NC}\n"
        exit 1
    fi

    # Download Bash version
    if ! download_file "$REPO_URL/wirepusher-bash.sh" "$INSTALL_DIR/wirepusher-bash.sh" "wirepusher-bash.sh"; then
        printf "${YELLOW}Warning: Failed to download wirepusher-bash.sh${NC}\n"
    fi

    # Make files executable
    chmod +x "$INSTALL_DIR/wirepusher.sh" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/wirepusher-bash.sh" 2>/dev/null || true

    printf "${GREEN}✓ Installation complete!${NC}\n"
}

# Print usage instructions
print_instructions() {
    printf "\n${GREEN}═══════════════════════════════════════════════════════${NC}\n"
    printf "${GREEN}  WirePusher Shell Scripts installed successfully!${NC}\n"
    printf "${GREEN}═══════════════════════════════════════════════════════${NC}\n\n"

    printf "${BLUE}Installation directory:${NC} %s\n\n" "$INSTALL_DIR"

    printf "${BLUE}Usage:${NC}\n"
    printf "  1. Source the library in your scripts:\n"
    printf "     ${YELLOW}. %s/wirepusher.sh${NC}\n\n" "$INSTALL_DIR"

    printf "  2. Set environment variables:\n"
    printf "     ${YELLOW}export WIREPUSHER_TOKEN='wpt_your_token'${NC}\n\n"

    printf "  3. Send notifications:\n"
    printf "     ${YELLOW}wirepusher_send 'Title' 'Message'${NC}\n\n"

    printf "${BLUE}Examples:${NC}\n"
    printf "  View examples at:\n"
    printf "  https://gitlab.com/wirepusher/wirepusher-sh/-/tree/main/examples\n\n"

    printf "${BLUE}Documentation:${NC}\n"
    printf "  https://gitlab.com/wirepusher/wirepusher-sh\n\n"

    # Suggest adding to shell profile
    if [ "$INSTALL_DIR" != "$DEFAULT_INSTALL_DIR" ]; then
        printf "${YELLOW}Tip:${NC} Add this to your ~/.bashrc or ~/.zshrc for easy access:\n"
        printf "     ${YELLOW}export PATH=\"\$PATH:%s\"${NC}\n\n" "$INSTALL_DIR"
    fi
}

# Main installation
main() {
    printf "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
    printf "${BLUE}  WirePusher Shell Scripts Installer${NC}\n"
    printf "${BLUE}═══════════════════════════════════════════════════════${NC}\n\n"

    check_sudo
    check_dependencies
    create_install_dir
    install_files
    print_instructions

    printf "${GREEN}Installation complete!${NC}\n"
}

main
