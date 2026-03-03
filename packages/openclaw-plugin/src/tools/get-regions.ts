import type { PluginApi } from "../config.js";
import type { NewsApiClient } from "../client.js";
import type { NewsRegionsResponse } from "../types.js";
import { toolResult, toolError, errorMessage } from "../types.js";

export function registerGetRegions(api: PluginApi, client: NewsApiClient) {
  api.registerTool({
    name: "newsmcp_get_regions",
    description:
      "List all available geographic regions (continents and countries) for filtering news events. Use these slugs with the geo parameter in newsmcp_get_news.",
    parameters: {
      type: "object" as const,
      properties: {},
    },
    async execute() {
      try {
        const data = await client.get<NewsRegionsResponse>("/news/regions/");
        return toolResult(data);
      } catch (err) {
        return toolError(errorMessage(err));
      }
    },
  });
}
