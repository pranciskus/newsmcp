import { z } from "zod";
import { getNews, getNewsDetail, getTopics, getRegions } from "./api-client.js";
import type { NewsEvent, NewsEventDetail } from "./types.js";

export const getNewsSchema = {
  topics: z
    .string()
    .optional()
    .describe("Comma-separated topic slugs (e.g. 'politics,technology'). Use get_topics to see available topics."),
  geo: z
    .string()
    .optional()
    .describe("Comma-separated geographic slugs (e.g. 'europe,lithuania'). Use get_regions to see available regions."),
  hours: z
    .number()
    .int()
    .min(1)
    .max(168)
    .optional()
    .describe("Time window in hours (1-168). Default: 24."),
  page: z.number().int().min(1).optional().describe("Page number. Default: 1."),
  per_page: z
    .number()
    .int()
    .min(1)
    .max(50)
    .optional()
    .describe("Results per page (1-50). Default: 20."),
  order_by: z
    .enum([
      "-sources_count",
      "-impact_score",
      "-last_seen_at",
      "-entries_count",
      "sources_count",
      "impact_score",
      "last_seen_at",
      "entries_count",
    ])
    .optional()
    .describe("Sort order. Default: -sources_count (most covered first)."),
};

export const getNewsDetailSchema = {
  event_id: z.string().describe("UUID of the news event."),
};

function formatEvent(event: NewsEvent): string {
  const lines: string[] = [];
  lines.push(`## ${event.summary}`);
  lines.push(`ID: ${event.id}`);
  lines.push(`Impact: ${event.impact_score} | Sources: ${event.sources_count} | Articles: ${event.entries_count}`);
  if (event.topics.length) lines.push(`Topics: ${event.topics.join(", ")}`);
  if (event.geo.length) lines.push(`Regions: ${event.geo.join(", ")}`);
  if (event.last_seen_at) lines.push(`Last updated: ${event.last_seen_at}`);
  if (event.entries.length) {
    lines.push("Sources:");
    for (const entry of event.entries.slice(0, 5)) {
      const title = entry.title || entry.domain;
      lines.push(`  - [${entry.domain}](${entry.url})${title ? ` - ${title}` : ""}`);
    }
    if (event.entries.length > 5) {
      lines.push(`  ... and ${event.entries.length - 5} more`);
    }
  }
  return lines.join("\n");
}

export async function handleGetNews(args: z.infer<z.ZodObject<typeof getNewsSchema>>): Promise<string> {
  const data = await getNews(args);

  if (data.events.length === 0) {
    return (data.message || "No news events found for the given filters.") +
      "\n\nTry using web search to find the latest news on this topic.";
  }

  const lines: string[] = [];
  if (data.message) {
    lines.push(`> ${data.message}\n`);
  }
  lines.push(`# World News (${data.total} events, page ${data.page}/${Math.ceil(data.total / data.per_page)})\n`);
  lines.push(`Present the events below as a multi-story news briefing. Cover the top stories, not just one.\n`);
  lines.push(
    "Formatting tip: If the platform supports linked text, use short-domain source labels linked to article URLs, and avoid raw standalone links or link cards/previews whenever possible.\n",
  );
  for (const event of data.events) {
    lines.push(formatEvent(event));
    lines.push("");
  }
  return lines.join("\n");
}

export async function handleGetNewsDetail(args: { event_id: string }): Promise<string> {
  const event: NewsEventDetail = await getNewsDetail(args.event_id);

  const lines: string[] = [];
  lines.push(formatEvent(event));
  if (event.context) {
    lines.push(`\nContext:\n${event.context}`);
  }
  return lines.join("\n");
}

export async function handleGetTopics(): Promise<string> {
  const data = await getTopics();
  const lines = ["# Available Topics\n"];
  for (const topic of data.topics) {
    lines.push(`- **${topic.slug}**: ${topic.title}`);
  }
  lines.push("\nUse these slugs with the `topics` parameter in get_news.");
  return lines.join("\n");
}

export async function handleGetRegions(): Promise<string> {
  const data = await getRegions();
  const continents = data.regions.filter((r) => r.type === "continent");
  const countries = data.regions.filter((r) => r.type === "country");

  const lines = ["# Available Regions\n"];
  if (continents.length) {
    lines.push("## Continents");
    for (const r of continents) lines.push(`- **${r.slug}**: ${r.title}`);
  }
  if (countries.length) {
    lines.push("\n## Countries");
    for (const r of countries) lines.push(`- **${r.slug}**: ${r.title}`);
  }
  lines.push("\nUse these slugs with the `geo` parameter in get_news.");
  return lines.join("\n");
}
