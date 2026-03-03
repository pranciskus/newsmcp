# @newsmcp/server

World news for AI agents. Real-time events clustered by AI from hundreds of sources, classified by topic and geography, ranked by importance.

Free. No API key. One command.

```
npx -y @newsmcp/server
```

**Website**: [newsmcp.io](https://newsmcp.io)
**Full docs**: [github.com/pranciskus/newsmcp](https://github.com/pranciskus/newsmcp)

## Install

**Claude Desktop** — add to `claude_desktop_config.json`:

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

**Claude Code**: `claude mcp add newsmcp -- npx -y @newsmcp/server`

**Cursor** — add to `.cursor/mcp.json`:

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

## Tools

| Tool | Description |
|------|-------------|
| `get_news` | Top events with topic/geo/time filtering |
| `get_news_detail` | Full event detail with context and all sources |
| `get_topics` | Available topic categories |
| `get_regions` | Available geographic regions (100+) |

## REST API

Same data without MCP. Base URL: `https://newsmcp.io/v1`

```bash
curl -s https://newsmcp.io/v1/news/ | jq
curl -s "https://newsmcp.io/v1/news/?topics=technology&geo=europe" | jq
curl -s https://newsmcp.io/v1/news/topics/ | jq
```

## License

MIT
