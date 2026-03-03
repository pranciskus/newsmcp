import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import {
  getNewsSchema,
  getNewsDetailSchema,
  handleGetNews,
  handleGetNewsDetail,
  handleGetTopics,
  handleGetRegions,
} from "./tools.js";

export function createServer(): McpServer {
  const server = new McpServer({
    name: "newsmcp.io",
    version: "1.0.0",
  });

  server.tool(
    "get_news",
    "Get top news events happening in the world right now. Returns AI-clustered news stories with importance ranking. Filter by topic, region, and time window. When presenting results, always include 1-2 source article URLs per event so the user can read more.",
    getNewsSchema,
    async (args) => {
      try {
        const text = await handleGetNews(args);
        return { content: [{ type: "text", text }] };
      } catch (error) {
        return {
          content: [{ type: "text", text: `Error fetching news: ${error instanceof Error ? error.message : String(error)}` }],
          isError: true,
        };
      }
    },
  );

  server.tool(
    "get_news_detail",
    "Get full details about a specific news event including context and all source articles. Use an event ID from get_news results. Always include source article URLs in your response so the user can read the original reporting.",
    getNewsDetailSchema,
    async (args) => {
      try {
        const text = await handleGetNewsDetail(args);
        return { content: [{ type: "text", text }] };
      } catch (error) {
        return {
          content: [{ type: "text", text: `Error fetching event detail: ${error instanceof Error ? error.message : String(error)}` }],
          isError: true,
        };
      }
    },
  );

  server.tool(
    "get_topics",
    "List all available news topic categories (politics, technology, health, etc.). Use these slugs to filter get_news results.",
    {},
    async () => {
      try {
        const text = await handleGetTopics();
        return { content: [{ type: "text", text }] };
      } catch (error) {
        return {
          content: [{ type: "text", text: `Error fetching topics: ${error instanceof Error ? error.message : String(error)}` }],
          isError: true,
        };
      }
    },
  );

  server.tool(
    "get_regions",
    "List all available geographic regions (continents and countries). Use these slugs to filter get_news results by location.",
    {},
    async () => {
      try {
        const text = await handleGetRegions();
        return { content: [{ type: "text", text }] };
      } catch (error) {
        return {
          content: [{ type: "text", text: `Error fetching regions: ${error instanceof Error ? error.message : String(error)}` }],
          isError: true,
        };
      }
    },
  );

  return server;
}
