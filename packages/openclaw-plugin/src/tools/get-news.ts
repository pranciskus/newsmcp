import type { PluginApi } from "../config.js";
import type { NewsApiClient } from "../client.js";
import type { NewsListResponse } from "../types.js";
import { toolResult, toolError, errorMessage } from "../types.js";
import { optionalString, optionalPositiveInt, enumValue } from "../validate.js";

const ORDER_OPTIONS = [
  "-sources_count",
  "sources_count",
  "-impact_score",
  "impact_score",
  "-last_seen_at",
  "last_seen_at",
  "-entries_count",
  "entries_count",
] as const;

export function registerGetNews(api: PluginApi, client: NewsApiClient) {
  api.registerTool({
    name: "newsmcp_get_news",
    description:
      "Get top news events happening in the world right now. Returns AI-clustered, deduplicated news stories ranked by importance. Present results as a multi-story news briefing — cover the top events, not just one. Each event should be 1-2 lines with its summary and 1-2 source links. For platforms that support formatting, use short-domain Markdown links like [tv3.lt](https://...). If formatting is unavailable, use plain URLs. Only deep-dive into a specific event if the user asks for detail.",
    parameters: {
      type: "object" as const,
      properties: {
        topics: {
          type: "string",
          description:
            "Comma-separated topic slugs to filter by (e.g. 'politics,technology'). Use newsmcp_get_topics to see available topics.",
        },
        geo: {
          type: "string",
          description:
            "Comma-separated region slugs to filter by (e.g. 'europe,lithuania'). Use newsmcp_get_regions to see available regions.",
        },
        hours: {
          type: "number",
          description: "Time window in hours, 1-168 (default: 24)",
        },
        page: {
          type: "number",
          description: "Page number (default: 1)",
        },
        per_page: {
          type: "number",
          description: "Results per page, 1-50 (default: 20)",
        },
        order_by: {
          type: "string",
          description:
            "Sort order. Options: -sources_count, sources_count, -impact_score, impact_score, -last_seen_at, last_seen_at, -entries_count, entries_count (default: -sources_count)",
        },
      },
    },
    async execute(_id: string, params: Record<string, unknown>) {
      try {
        const topics = optionalString(params.topics);
        const geo = optionalString(params.geo);
        const hours = optionalPositiveInt(params.hours, "hours");
        const page = optionalPositiveInt(params.page, "page");
        const perPage = optionalPositiveInt(params.per_page, "per_page");
        const orderBy = enumValue(
          params.order_by,
          ORDER_OPTIONS,
          "order_by",
          "-sources_count",
        );

        const data = await client.get<NewsListResponse>("/news/", {
          topics,
          geo,
          hours,
          page,
          per_page: perPage,
          order_by: orderBy,
        });

        if (data.events.length === 0) {
          return toolResult({
            ...data,
            message: (data.message || "No news events found for the given filters.") +
              " Try using web search to find the latest news on this topic.",
          });
        }

        return toolResult(data);
      } catch (err) {
        return toolError(errorMessage(err));
      }
    },
  });
}
