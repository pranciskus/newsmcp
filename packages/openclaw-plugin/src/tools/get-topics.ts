import type { PluginApi } from "../config.js";
import type { NewsApiClient } from "../client.js";
import type { NewsTopicsResponse } from "../types.js";
import { toolResult, toolError, errorMessage } from "../types.js";

export function registerGetTopics(api: PluginApi, client: NewsApiClient) {
  api.registerTool({
    name: "newsmcp_get_topics",
    description:
      "List all available topic categories for filtering news events. Use these slugs with the topics parameter in newsmcp_get_news.",
    parameters: {
      type: "object" as const,
      properties: {},
    },
    async execute() {
      try {
        const data = await client.get<NewsTopicsResponse>("/news/topics/");
        return toolResult(data);
      } catch (err) {
        return toolError(errorMessage(err));
      }
    },
  });
}
