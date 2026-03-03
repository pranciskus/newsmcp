# World News MCP Server

A free, no-auth MCP server that gives AI assistants access to real-time world news. Events are AI-clustered from multiple sources, classified by topic and geography, and ranked by importance.

**No API key required.**

## Quick Start

### Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "world-news": {
      "command": "npx",
      "args": ["-y", "@newsmcp/server"]
    }
  }
}
```

### Claude Code

```bash
claude mcp add world-news -- npx -y @newsmcp/server
```

### Cursor

Add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "world-news": {
      "command": "npx",
      "args": ["-y", "@newsmcp/server"]
    }
  }
}
```

### Smithery

```bash
npx -y @smithery/cli install @newsmcp/server --client claude
```

## Tools

### `get_news`

Get top news events happening right now.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `topics` | string | — | Comma-separated topic slugs (e.g. `politics,technology`) |
| `geo` | string | — | Comma-separated region slugs (e.g. `europe,lithuania`) |
| `hours` | number | 24 | Time window: 1-168 hours |
| `page` | number | 1 | Page number |
| `per_page` | number | 20 | Results per page (max 50) |
| `order_by` | string | `-sources_count` | Sort: `-sources_count`, `-impact_score`, `-last_seen_at`, `-entries_count` |

### `get_news_detail`

Get full details about a specific event.

| Parameter | Type | Description |
|-----------|------|-------------|
| `event_id` | string | UUID from `get_news` results |

### `get_topics`

List available topic categories for filtering. No parameters.

Topics include: politics, economy, technology, science, health, environment, sports, culture, crime, military, education, society.

### `get_regions`

List available geographic regions (continents and countries) for filtering. No parameters.

## Example Conversations

**"What's happening in the world?"**
&rarr; Calls `get_news` with defaults, returns top 20 events by source coverage.

**"Any tech news from Europe today?"**
&rarr; Calls `get_news` with `topics=technology`, `geo=europe`, `hours=24`.

**"Tell me more about that earthquake event"**
&rarr; Calls `get_news_detail` with the event UUID.

**"What topics can I filter by?"**
&rarr; Calls `get_topics`, returns the full list.

## Configuration

Set the `NEWS_API_BASE_URL` environment variable to point to a different API backend:

```json
{
  "mcpServers": {
    "world-news": {
      "command": "npx",
      "args": ["-y", "@newsmcp/server"],
      "env": {
        "NEWS_API_BASE_URL": "https://your-api.example.com/api/v1"
      }
    }
  }
}
```

## License

MIT
