# @newsmcp/openclaw

[![npm version](https://img.shields.io/npm/v/@newsmcp/openclaw)](https://www.npmjs.com/package/@newsmcp/openclaw)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

OpenClaw plugin for real-time AI-clustered world news. Topic and geographic filtering from [newsmcp.io](https://newsmcp.io). Free, no API key.

## Install

```bash
openclaw plugins install @newsmcp/openclaw
```

## Configuration

Optional — works out of the box with no configuration.

To use a custom API endpoint:

```bash
openclaw config set plugins.entries.@newsmcp/openclaw.config.apiBaseUrl "https://your-api.example.com/v1"
```

Or edit `openclaw.json`:

```json
{
  "plugins": {
    "entries": {
      "@newsmcp/openclaw": {
        "config": {
          "apiBaseUrl": "https://newsmcp.io/v1"
        }
      }
    }
  }
}
```

## Tools

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `newsmcp_get_news` | Top events with topic/geo/time filtering | `topics`, `geo`, `hours`, `page`, `per_page`, `order_by` |
| `newsmcp_get_news_detail` | Full event detail with context and all sources | `event_id` |
| `newsmcp_get_topics` | List available topic categories | — |
| `newsmcp_get_regions` | List available geographic regions | — |

## License

MIT
