<h1 align="center">NewsMCP — World news for AI agents</h1>

<p align="center">
  <a href="https://newsmcp.io">newsmcp.io</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;<a href="#integrations">integrations</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;<a href="#rest-api">REST API</a>
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/@newsmcp/server"><img src="https://img.shields.io/npm/v/@newsmcp/server?style=flat-square&color=cb3837" alt="npm @newsmcp/server"></a>
  <a href="https://www.npmjs.com/package/@newsmcp/openclaw"><img src="https://img.shields.io/npm/v/@newsmcp/openclaw?style=flat-square&color=cb3837" alt="npm @newsmcp/openclaw"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT"></a>
</p>

---

Real-time news events, clustered by AI from hundreds of sources, classified by topic and geography, ranked by importance.

Free. No API key. One command to install.

## Coverage

**12 topics** — `politics` `economy` `technology` `science` `health` `environment` `sports` `culture` `crime` `military` `education` `society`

**30 regions** — 6 continents and 24 countries. Filter by `europe`, `asia`, `united-states`, `germany`, `japan`, `ukraine`, and more.

**Hundreds of sources** — Articles clustered into events in real-time, ranked by source count and impact score.

## Integrations

| Platform | Package | Install |
|----------|---------|---------|
| [Claude Desktop](#claude-desktop) | `@newsmcp/server` | MCP config |
| [Claude Code plugin](#claude-code-plugin) | `newsmcp` | `/plugin install` |
| [Claude Code MCP](#claude-code-mcp) | `@newsmcp/server` | `claude mcp add` |
| [Cursor](#cursor) | `@newsmcp/server` | MCP config |
| [Windsurf](#windsurf) | `@newsmcp/server` | MCP config |
| [OpenAI Codex](#openai-codex) | `@newsmcp/server` | `codex mcp add` |
| [Gemini CLI](#gemini-cli) | `@newsmcp/server` | `settings.json` |
| [OpenCode](#opencode) | `@newsmcp/server` | `opencode mcp add` |
| [Smithery](#smithery) | `@newsmcp/server` | `npx @smithery/cli` |
| [OpenClaw plugin](#openclaw-plugin) | `@newsmcp/openclaw` | `openclaw plugins install` |
| [OpenClaw skill](#openclaw-skill) | `newsmcp-skill` | `clawhub install` |
| [REST API](#rest-api) | — | `curl https://newsmcp.io/v1/news/` |

### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "newsmcp": {
      "command": "npx",
      "args": ["-y", "@newsmcp/server"]
    }
  }
}
```

### Claude Code Plugin

```bash
/plugin marketplace add pranciskus/newsmcp
/plugin install newsmcp
```

### Claude Code MCP

```bash
claude mcp add newsmcp -- npx -y @newsmcp/server
```

### Cursor

Add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "newsmcp": {
      "command": "npx",
      "args": ["-y", "@newsmcp/server"]
    }
  }
}
```

### Windsurf

Add to MCP config:

```json
{
  "mcpServers": {
    "newsmcp": {
      "command": "npx",
      "args": ["-y", "@newsmcp/server"]
    }
  }
}
```

### OpenAI Codex

```bash
codex mcp add newsmcp -- npx -y @newsmcp/server
```

Or add to `~/.codex/config.toml`:

```toml
[mcp_servers.newsmcp]
command = "npx"
args = ["-y", "@newsmcp/server"]
```

### Gemini CLI

Add to `~/.gemini/settings.json` (or project-local `.gemini/settings.json`):

```json
{
  "mcpServers": {
    "newsmcp": {
      "command": "npx",
      "args": ["-y", "@newsmcp/server"]
    }
  }
}
```

### OpenCode

```bash
opencode mcp add
```

Or add to `~/.config/opencode/opencode.json` (or project-local `.opencode/opencode.json`):

```json
{
  "mcp": {
    "newsmcp": {
      "type": "local",
      "enabled": true,
      "command": ["npx", "-y", "@newsmcp/server"]
    }
  }
}
```

### Smithery

```bash
npx -y @smithery/cli install @newsmcp/server --client claude
```

### OpenClaw Plugin

```bash
openclaw plugins install @newsmcp/openclaw
```

No configuration needed — works out of the box. See [`@newsmcp/openclaw`](packages/openclaw-plugin/) for options.

### OpenClaw Skill

```bash
clawhub install newsmcp-skill
```

Lightweight alternative — a single SKILL.md that teaches the agent to call the REST API via `curl`. No dependencies. See [`newsmcp-skill`](packages/skill/) on [ClawHub](https://clawhub.ai/).

## MCP Tools

Four tools. That's the interface.

### `get_news`

Top events happening right now. Filter by topic, region, time window.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `topics` | string | — | Comma-separated topic slugs: `politics,technology` |
| `geo` | string | — | Comma-separated region slugs: `europe,lithuania` |
| `hours` | number | 24 | Time window in hours (1–168) |
| `page` | number | 1 | Page number |
| `per_page` | number | 20 | Results per page (max 50) |
| `order_by` | string | `-sources_count` | Sort field (see below) |

**Sort options**: `-sources_count`, `-impact_score`, `-last_seen_at`, `-entries_count` (prefix `-` for descending)

### `get_news_detail`

Full details on a single event — all source articles, AI-generated context, impact analysis, entity tags.

| Parameter | Type | Description |
|-----------|------|-------------|
| `event_id` | string | Event UUID from `get_news` results |

### `get_topics`

Lists every topic category available for filtering. No parameters.

`crime` `culture` `economy` `education` `environment` `health` `military` `politics` `science` `society` `sports` `technology`

### `get_regions`

Lists every geographic region — 6 continents and 24 countries — available for filtering. No parameters.

## How agents use it

| Prompt | What happens |
|--------|-------------|
| "What's happening in the world?" | `get_news` with defaults — top 20 events by source coverage |
| "Any tech news from Europe today?" | `get_news` with `topics=technology`, `geo=europe`, `hours=24` |
| "Tell me more about that earthquake" | `get_news_detail` with the event UUID |
| "What topics can I filter by?" | `get_topics` — returns the full list |
| "Show me news from Asia this week" | `get_news` with `geo=asia`, `hours=168` |

## REST API

Don't need MCP? Hit the endpoints directly. Same data, same filters.

**Base URL**: `https://newsmcp.io/v1`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/news/` | List news events with optional filtering |
| `GET` | `/news/{id}/` | Single event with full article list |
| `GET` | `/news/topics/` | All topic categories |
| `GET` | `/news/regions/` | All geographic regions |

### Query parameters

All parameters are optional. Combine freely.

```bash
# Latest events
curl -s https://newsmcp.io/v1/news/ | jq

# Filter by topic
curl -s "https://newsmcp.io/v1/news/?topics=technology" | jq

# Filter by region
curl -s "https://newsmcp.io/v1/news/?geo=europe" | jq

# Last 12 hours, sorted by impact
curl -s "https://newsmcp.io/v1/news/?hours=12&order_by=-impact_score" | jq

# Combine everything
curl -s "https://newsmcp.io/v1/news/?topics=politics&geo=united+states&hours=48&per_page=5" | jq
```

### Response format

```json
{
  "events": [
    {
      "id": "cc3428ab-2ada-41bb-86ab-833fd39ffd8d",
      "summary": "Event description with AI-generated context...",
      "topics": ["technology", "politics"],
      "geo": ["united states"],
      "entries_count": 86,
      "sources_count": 45,
      "first_seen_at": "2026-02-15T04:06:41.728Z",
      "last_seen_at": "2026-03-03T05:00:30Z",
      "impact_score": 8,
      "entries": [
        {
          "title": "Article headline",
          "url": "https://source.com/article",
          "domain": "source.com",
          "published_at": "2026-03-03T05:00:30Z"
        }
      ]
    }
  ],
  "total": 142,
  "page": 1,
  "per_page": 20
}
```

## How it works

1. **Collect** — Hundreds of news sources are scraped continuously
2. **Cluster** — Articles about the same event are grouped using vector embeddings
3. **Classify** — Each event is tagged with topics and geographic entities
4. **Rank** — Events are scored by source count, impact, and recency
5. **Serve** — Clean JSON via REST API and MCP server

Events update in real-time as new articles appear. The clustering AI merges duplicate coverage automatically.

## Configuration

Point to a different API backend:

```json
{
  "mcpServers": {
    "newsmcp": {
      "command": "npx",
      "args": ["-y", "@newsmcp/server"],
      "env": {
        "NEWS_API_BASE_URL": "https://your-api.example.com/v1"
      }
    }
  }
}
```

## Releases (GitHub Actions + OIDC)

Publishing is tag-driven via [`.github/workflows/release.yml`](.github/workflows/release.yml):

- Trigger: push tag `v*.*.*`
- Publishes `@newsmcp/server` and `@newsmcp/openclaw` to npm via Trusted Publishing (OIDC)
- Publishes MCP metadata with `mcp-publisher login github-oidc`
- Creates a GitHub release with generated notes

### One-time setup

1. npm package settings:
   For `@newsmcp/server` and `@newsmcp/openclaw`, add a Trusted Publisher pointing to:
   - Owner: `pranciskus`
   - Repository: `newsmcp`
   - Workflow file: `.github/workflows/release.yml`
   - Environment: leave empty (unless you intentionally use one)
2. MCP Registry:
   Ensure the repo/package is authorized for GitHub OIDC publishing in MCP Registry.

### Release flow

1. Bump versions in:
   - `packages/mcp-server/package.json`
   - `packages/openclaw-plugin/package.json`
   - `packages/mcp-server/server.json`
   - `package-lock.json`
2. Commit and push to `main`
3. Create and push tag:

```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

The workflow does the publish and GitHub release automatically.

## Repository structure

```
newsmcp/
├── .github/workflows/       # CI/CD workflows (release automation)
├── .claude-plugin/          # Marketplace manifest
├── packages/
│   ├── mcp-server/          # @newsmcp/server — MCP server (npm)
│   ├── claude-code-plugin/  # newsmcp — Claude Code plugin
│   ├── openclaw-plugin/     # @newsmcp/openclaw — OpenClaw plugin (npm)
│   └── skill/               # newsmcp-skill — OpenClaw skill (ClawHub)
├── publish.sh                # Build, test, publish workflow
├── README.md
└── LICENSE
```

## License

MIT
