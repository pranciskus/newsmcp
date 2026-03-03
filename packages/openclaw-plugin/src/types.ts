export interface NewsEntry {
  title: string | null;
  url: string;
  domain: string;
  published_at: string | null;
}

export interface NewsEvent {
  id: string;
  summary: string;
  topics: string[];
  geo: string[];
  entries_count: number;
  sources_count: number;
  first_seen_at: string | null;
  last_seen_at: string | null;
  impact_score: number;
  entries: NewsEntry[];
}

export interface NewsEventDetail extends NewsEvent {
  context: string | null;
}

export interface NewsListResponse {
  events: NewsEvent[];
  total: number;
  page: number;
  per_page: number;
  message?: string;
}

export interface NewsTerm {
  slug: string;
  title: string;
}

export interface NewsRegion extends NewsTerm {
  type: "continent" | "country";
}

export interface NewsTopicsResponse {
  topics: NewsTerm[];
}

export interface NewsRegionsResponse {
  regions: NewsRegion[];
}

export function toolResult(data: unknown) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data) }],
  };
}

export function toolError(message: string) {
  return {
    isError: true as const,
    content: [{ type: "text" as const, text: `Error: ${message}` }],
  };
}

export function errorMessage(err: unknown): string {
  if (err instanceof Error) {
    const status = (err as { status?: number }).status;
    if (status) return `[${status}] ${err.message}`;
    return err.message;
  }
  return String(err);
}
