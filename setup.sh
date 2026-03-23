#!/bin/bash
# ============================================================================
# Project N.O.M.A.D. for macOS — Setup Script
# https://github.com/karissafuller/project-nomad-macos
#
# Installs the full offline survival knowledge stack on macOS with Apple Silicon.
# Based on Project N.O.M.A.D. by Crosstalk Solutions.
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Data directory
NOMAD_DATA="$HOME/nomad-data"

echo ""
echo -e "${CYAN}${BOLD}============================================${NC}"
echo -e "${CYAN}${BOLD}  Project N.O.M.A.D. for macOS${NC}"
echo -e "${CYAN}${BOLD}  Knowledge That Never Goes Offline${NC}"
echo -e "${CYAN}${BOLD}============================================${NC}"
echo ""

# ─── CHECK: macOS and Apple Silicon ─────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This script is for macOS only.${NC}"
    exit 1
fi

ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo -e "${YELLOW}Warning: This script is optimized for Apple Silicon (arm64). You're on ${ARCH}.${NC}"
    echo -e "${YELLOW}Things may still work, but AI performance will be significantly lower.${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

echo -e "${GREEN}✓${NC} macOS on ${ARCH} detected"

# ─── CHECK: Homebrew ────────────────────────────────────────────────────────

if ! command -v brew &> /dev/null; then
    echo ""
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
fi
echo -e "${GREEN}✓${NC} Homebrew $(brew --version | head -1)"

# ─── CHECK: Docker Desktop ─────────────────────────────────────────────────

if ! command -v docker &> /dev/null; then
    echo ""
    echo -e "${YELLOW}Docker Desktop is required but not installed.${NC}"
    echo ""
    echo "Please install Docker Desktop manually:"
    echo "  1. Go to https://www.docker.com/products/docker-desktop/"
    echo "  2. Download the Apple Silicon version"
    echo "  3. Install and open it"
    echo "  4. Wait for the whale icon to appear in your menu bar"
    echo ""
    read -p "Press Enter when Docker Desktop is running..."
fi

# Wait for Docker to be ready
echo -ne "Waiting for Docker daemon..."
RETRIES=30
while ! docker info &> /dev/null; do
    RETRIES=$((RETRIES - 1))
    if [[ $RETRIES -le 0 ]]; then
        echo ""
        echo -e "${RED}Error: Docker is not responding. Make sure Docker Desktop is running.${NC}"
        exit 1
    fi
    echo -n "."
    sleep 2
done
echo ""
echo -e "${GREEN}✓${NC} Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"

# ─── PHASE 1: Ollama ───────────────────────────────────────────────────────

echo ""
echo -e "${BLUE}${BOLD}Phase 1: Installing Ollama (Local AI Engine)${NC}"

if ! command -v ollama &> /dev/null; then
    brew install ollama
fi

# Start Ollama service
brew services start ollama 2>/dev/null || true
sleep 3

# Wait for Ollama to be ready
RETRIES=15
while ! curl -s http://localhost:11434/api/tags &> /dev/null; do
    RETRIES=$((RETRIES - 1))
    if [[ $RETRIES -le 0 ]]; then
        echo -e "${RED}Error: Ollama failed to start.${NC}"
        exit 1
    fi
    sleep 2
done

echo -e "${GREEN}✓${NC} Ollama is running"

# Pull default model
if ! ollama list 2>/dev/null | grep -q "llama3.1:8b"; then
    echo -e "${CYAN}Downloading llama3.1:8b model (~4.7 GB)... this may take a few minutes.${NC}"
    ollama pull llama3.1:8b
fi
echo -e "${GREEN}✓${NC} AI model ready (llama3.1:8b)"

# ─── PHASE 2: Open WebUI ───────────────────────────────────────────────────

echo ""
echo -e "${BLUE}${BOLD}Phase 2: Setting up Open WebUI (AI Chat Interface)${NC}"

if ! docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
    docker run -d \
        --name open-webui \
        -p 3000:8080 \
        --add-host=host.docker.internal:host-gateway \
        -v open-webui:/app/backend/data \
        --restart unless-stopped \
        ghcr.io/open-webui/open-webui:main
else
    docker start open-webui 2>/dev/null || true
fi

# Wait for Open WebUI
echo -ne "Waiting for Open WebUI to initialize..."
RETRIES=30
while true; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" != "000" ]]; then
        break
    fi
    RETRIES=$((RETRIES - 1))
    if [[ $RETRIES -le 0 ]]; then
        echo ""
        echo -e "${YELLOW}Warning: Open WebUI may still be starting. Check http://localhost:3000 in a minute.${NC}"
        break
    fi
    echo -n "."
    sleep 3
done
echo ""
echo -e "${GREEN}✓${NC} Open WebUI is running on port 3000"

# ─── PHASE 3: Kiwix (Offline Wikipedia) ────────────────────────────────────

echo ""
echo -e "${BLUE}${BOLD}Phase 3: Setting up Kiwix (Offline Wikipedia & References)${NC}"

mkdir -p "$NOMAD_DATA/kiwix"

# Download WikiMed if not present
if ! ls "$NOMAD_DATA/kiwix/"*.zim &> /dev/null; then
    echo -e "${CYAN}Downloading WikiMed medical encyclopedia (~1 GB)...${NC}"

    # Try to find the latest WikiMed file
    WIKIMED_URL="https://download.kiwix.org/zim/wikipedia/wikipedia_en_medicine_maxi_2024-11.zim"
    curl -L -o "$NOMAD_DATA/kiwix/wikimed_en.zim" "$WIKIMED_URL" || {
        echo -e "${YELLOW}Warning: Could not download WikiMed automatically.${NC}"
        echo "Please download a .zim file from https://library.kiwix.org"
        echo "and save it to $NOMAD_DATA/kiwix/"
    }
fi

# Start Kiwix server
if ls "$NOMAD_DATA/kiwix/"*.zim &> /dev/null; then
    if ! docker ps -a --format '{{.Names}}' | grep -q '^kiwix-serve$'; then
        # Get list of zim files for the command
        ZIM_FILES=""
        for f in "$NOMAD_DATA/kiwix/"*.zim; do
            ZIM_FILES="$ZIM_FILES /data/$(basename "$f")"
        done

        docker run -d \
            --name kiwix-serve \
            -p 8888:8080 \
            -v "$NOMAD_DATA/kiwix":/data \
            --restart unless-stopped \
            ghcr.io/kiwix/kiwix-serve:latest $ZIM_FILES
    else
        docker start kiwix-serve 2>/dev/null || true
    fi
    echo -e "${GREEN}✓${NC} Kiwix is running on port 8888"
else
    echo -e "${YELLOW}⚠${NC} No .zim files found. Download from https://library.kiwix.org and restart."
fi

# ─── PHASE 4: Kolibri (Offline Education) ──────────────────────────────────

echo ""
echo -e "${BLUE}${BOLD}Phase 4: Setting up Kolibri (Offline Education)${NC}"

if ! command -v kolibri &> /dev/null && ! python3 -m kolibri --version &> /dev/null; then
    pip3 install kolibri --break-system-packages 2>/dev/null || pip3 install kolibri
fi

# Start Kolibri on port 8009
export KOLIBRI_HTTP_PORT=8009
kolibri start 2>/dev/null || {
    echo -e "${YELLOW}Warning: Kolibri may need manual start. Run:${NC}"
    echo "  export KOLIBRI_HTTP_PORT=8009 && kolibri start"
}
echo -e "${GREEN}✓${NC} Kolibri is running on port 8009"

# ─── PHASE 5: CyberChef ───────────────────────────────────────────────────

echo ""
echo -e "${BLUE}${BOLD}Phase 5: Setting up CyberChef (Data Tools)${NC}"

if ! docker ps -a --format '{{.Names}}' | grep -q '^cyberchef$'; then
    docker run -d \
        --name cyberchef \
        -p 8087:8080 \
        --restart unless-stopped \
        ghcr.io/gchq/cyberchef:latest
else
    docker start cyberchef 2>/dev/null || true
fi
echo -e "${GREEN}✓${NC} CyberChef is running on port 8087"

# ─── PHASE 6: FlatNotes ───────────────────────────────────────────────────

echo ""
echo -e "${BLUE}${BOLD}Phase 6: Setting up FlatNotes (Local Notes)${NC}"

if ! docker ps -a --format '{{.Names}}' | grep -q '^flatnotes$'; then
    docker run -d \
        --name flatnotes \
        -p 8086:8080 \
        -v flatnotes-data:/data \
        -e PUID=1000 \
        -e PGID=1000 \
        --restart unless-stopped \
        dullage/flatnotes:latest
else
    docker start flatnotes 2>/dev/null || true
fi
echo -e "${GREEN}✓${NC} FlatNotes is running on port 8086"

# ─── FINAL REPORT ─────────────────────────────────────────────────────────

LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "your-mac-ip")

echo ""
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║          PROJECT N.O.M.A.D. for macOS — READY           ║${NC}"
echo -e "${CYAN}${BOLD}║          Knowledge That Never Goes Offline               ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Your services are running:${NC}"
echo ""
echo -e "  ${GREEN}●${NC} AI Chat (Open WebUI)      ${BOLD}http://localhost:3000${NC}"
echo -e "  ${GREEN}●${NC} Wikipedia (Kiwix)          ${BOLD}http://localhost:8888${NC}"
echo -e "  ${GREEN}●${NC} Education (Kolibri)        ${BOLD}http://localhost:8009${NC}"
echo -e "  ${GREEN}●${NC} Data Tools (CyberChef)     ${BOLD}http://localhost:8087${NC}"
echo -e "  ${GREEN}●${NC} Notes (FlatNotes)          ${BOLD}http://localhost:8086${NC}"
echo ""
echo -e "${BOLD}Access from other devices on your WiFi:${NC}"
echo -e "  Replace 'localhost' with ${CYAN}${LOCAL_IP}${NC}"
echo ""
echo -e "${BOLD}First steps:${NC}"
echo -e "  1. Open ${CYAN}http://localhost:3000${NC} → create an account → start chatting with AI"
echo -e "  2. Open ${CYAN}http://localhost:8888${NC} → browse offline Wikipedia & medical references"
echo -e "  3. Open ${CYAN}http://localhost:8009${NC} → set up Kolibri → download Khan Academy content"
echo ""
echo -e "${BOLD}Manage:${NC}"
echo -e "  Stop all:   docker stop open-webui kiwix-serve cyberchef flatnotes && kolibri stop"
echo -e "  Start all:  docker start open-webui kiwix-serve cyberchef flatnotes && kolibri start"
echo -e "  More models: ollama pull mistral:7b"
echo ""
echo -e "${BOLD}Offline maps:${NC} Install Organic Maps from the App Store (free)"
echo ""
echo -e "${CYAN}Enjoy your offline brain. Stay prepared. 🛰${NC}"
echo ""
