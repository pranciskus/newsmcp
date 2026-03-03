import type { PluginApi } from "./config.js";
import { resolveConfig } from "./config.js";
import { NewsApiClient } from "./client.js";
import { registerGetNews } from "./tools/get-news.js";
import { registerGetNewsDetail } from "./tools/get-news-detail.js";
import { registerGetTopics } from "./tools/get-topics.js";
import { registerGetRegions } from "./tools/get-regions.js";

export default function register(api: PluginApi) {
  const cfg = resolveConfig(api);
  const client = new NewsApiClient(cfg);

  registerGetNews(api, client);
  registerGetNewsDetail(api, client);
  registerGetTopics(api, client);
  registerGetRegions(api, client);

  api.logger.info(`newsmcp plugin loaded (${cfg.apiBaseUrl})`);
}
