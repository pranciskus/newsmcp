import type { PluginApi } from "../config.js";
import type { NewsApiClient } from "../client.js";
import type { NewsEventDetail } from "../types.js";
import { toolResult, toolError, errorMessage } from "../types.js";
import { nonEmptyString } from "../validate.js";

export function registerGetNewsDetail(api: PluginApi, client: NewsApiClient) {
  api.registerTool({
    name: "newsmcp_get_news_detail",
    description:
      "Get full details for a single news event — all source articles, AI-generated context, impact analysis. Use event IDs from newsmcp_get_news results. Always include source article URLs in your response so the user can read the original reporting. For platforms that support formatting, prefer short-domain Markdown links like [lrt.lt](https://...).",
    parameters: {
      type: "object" as const,
      properties: {
        event_id: {
          type: "string",
          description: "Event UUID from newsmcp_get_news results",
        },
      },
      required: ["event_id"],
    },
    async execute(_id: string, params: Record<string, unknown>) {
      try {
        const eventId = nonEmptyString(params.event_id, "event_id");
        const data = await client.get<NewsEventDetail>(
          `/news/${encodeURIComponent(eventId)}/`,
        );
        return toolResult(data);
      } catch (err) {
        return toolError(errorMessage(err));
      }
    },
  });
}
