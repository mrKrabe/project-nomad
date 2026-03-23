# Project N.O.M.A.D. for macOS

**The complete offline survival knowledge stack — ported to macOS and Apple Silicon.**

> "Knowledge That Never Goes Offline"

---

[Project N.O.M.A.D.](https://github.com/Crosstalk-Solutions/project-nomad) is an incredible open-source project that bundles local AI, offline Wikipedia, maps, education tools, and more into a single self-hosted server. The only catch? It's Linux-only.

**This repo brings the full N.O.M.A.D. experience to macOS**, optimized for Apple Silicon. If you have a MacBook or Mac Mini, you can run the entire offline survival stack natively — and thanks to Apple Silicon's unified memory architecture, the AI components actually run *faster* than most dedicated NOMAD Linux boxes.

## What You Get

| Service | Tool | What It Does |
|---------|------|-------------|
| **Local AI Chat** | Ollama + Open WebUI | ChatGPT-style AI that runs 100% on your Mac. Upload your own documents for personalized answers. |
| **Offline Wikipedia** | Kiwix | Full Wikipedia, medical references, dictionaries — no internet needed. |
| **Offline Education** | Kolibri | Khan Academy, TED Talks, textbooks — all offline. |
| **Data Tools** | CyberChef | Encoding, decoding, encryption, hashing, format conversion. |
| **Local Notes** | FlatNotes | Markdown note-taking app, self-hosted. |
| **Offline Maps** | Organic Maps | OpenStreetMap with turn-by-turn navigation, fully offline. |

**All services are accessible from any device on your WiFi** — phones, tablets, laptops — via browser.

## Requirements

- **Mac with Apple Silicon** (M1/M2/M3/M4 — any variant)
- **macOS Ventura 13.0 or later** (tested on Sequoia 15.7.4)
- **16 GB RAM minimum** (24 GB+ recommended for larger AI models)
- **25–200 GB free disk space** (depends on content choices)
- **Docker Desktop for Mac** ([download here](https://www.docker.com/products/docker-desktop/))

## Quick Start

### 1. Install Homebrew (if you don't have it)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Run the setup script

```bash
curl -fsSL https://raw.githubusercontent.com/karissafuller/project-nomad-macos/main/setup.sh -o setup.sh && bash setup.sh
```

The script will:
- Install Ollama and pull an AI model
- Set up Open WebUI, Kiwix, Kolibri, CyberChef, and FlatNotes via Docker
- Download the WikiMed medical encyclopedia
- Print a dashboard with all your service URLs

### 3. Open your browser

Once setup completes, visit **http://localhost:3000** for AI Chat. See the full URL list printed at the end of setup.

## Service URLs

| Service | URL |
|---------|-----|
| AI Chat (Open WebUI) | http://localhost:3000 |
| Wikipedia/References (Kiwix) | http://localhost:8888 |
| Education (Kolibri) | http://localhost:8009 |
| Data Tools (CyberChef) | http://localhost:8087 |
| Notes (FlatNotes) | http://localhost:8086 |

Replace `localhost` with your Mac's IP to access from other devices:

```bash
ipconfig getifaddr en0
```

## Storage Estimates

| Setup | Space Needed |
|-------|-------------|
| **Minimal** (AI + WikiMed + CyberChef) | ~8 GB |
| **Recommended** (above + maps + selected Khan Academy) | ~25 GB |
| **Full** (everything + full Wikipedia + multiple AI models) | ~180 GB |

## Manage Your Stack

```bash
# Check running services
docker ps

# Stop all Docker services
docker stop open-webui kiwix-serve cyberchef flatnotes

# Start all Docker services
docker start open-webui kiwix-serve cyberchef flatnotes

# Restart Ollama
brew services restart ollama

# Start Kolibri
export KOLIBRI_HTTP_PORT=8009 && kolibri start

# Download more AI models
ollama pull mistral:7b
ollama pull gemma2:9b
ollama pull codellama:7b

# Check disk usage
docker system df
```

## Add More Content

### More AI Models
Browse available models at [ollama.com/library](https://ollama.com/library):
```bash
ollama pull llama3.1:13b      # Smarter, still fast on 24GB+
ollama pull mistral:7b         # Great for general tasks
ollama pull codellama:7b       # Coding-focused
```

### More Wikipedia / Reference Content
Download `.zim` files from [library.kiwix.org](https://library.kiwix.org) and save them to `~/nomad-data/kiwix/`, then restart Kiwix:
```bash
docker restart kiwix-serve
```

### Offline Maps
Install [Organic Maps](https://organicmaps.app/) (free) on your Mac, iPhone, or iPad. Download your region's maps while you have internet.

## Going Off-Grid

Your Mac is already a portable offline server:

- **Battery:** MacBook Pros get 14–17 hours — plenty for extended use
- **Power bank:** Any 100W+ USB-C power bank extends runtime significantly
- **Solar:** A 60–100W portable solar panel with USB-C PD charges directly
- **Hotspot:** System Settings → General → Sharing → Internet Sharing — lets phones/tablets connect to your Mac and access all services with zero internet

## Uninstall

Everything is self-contained and fully reversible:

```bash
# Remove Docker containers and data
docker rm -f open-webui kiwix-serve cyberchef flatnotes
docker volume rm open-webui flatnotes-data
docker system prune -a

# Remove Ollama and models
brew uninstall ollama
rm -rf ~/.ollama

# Remove Kolibri
pip3 uninstall kolibri
rm -rf ~/.kolibri

# Remove downloaded content
rm -rf ~/nomad-data
```

Your Mac will be exactly as it was before — zero traces.

## Credits

- **[Project N.O.M.A.D.](https://github.com/Crosstalk-Solutions/project-nomad)** by Crosstalk Solutions — the original project that inspired this macOS port
- **[Ollama](https://ollama.com/)** — local LLM inference engine
- **[Open WebUI](https://github.com/open-webui/open-webui)** — chat interface with RAG support
- **[Kiwix](https://kiwix.org/)** — offline content platform
- **[Kolibri](https://learningequality.org/kolibri/)** — offline education by Learning Equality
- **[CyberChef](https://github.com/gchq/CyberChef)** — data manipulation toolkit by GCHQ
- **[FlatNotes](https://github.com/dullage/flatnotes)** — markdown note-taking app

## The Story Behind This

I'm a program manager, not a developer. I saw Project N.O.M.A.D. trending and wanted to run it on my Mac — but it's Linux-only. So I used Claude (Anthropic's AI) in two stages: first to architect the macOS equivalent and write a detailed setup spec, then handed that spec to Claude Code (an AI agent with terminal access) to execute the full deployment on my machine autonomously.

The whole process — from "this looks cool" to "fully running offline AI stack" — took about two hours. No prior sysadmin experience required.

If I can do it, you can do it.

## License

MIT — use it however you want.
