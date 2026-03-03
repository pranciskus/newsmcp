import type {
  NewsListResponse,
  NewsEventDetail,
  NewsTopicsResponse,
  NewsRegionsResponse,
} from "./types.js";

const DEFAULT_BASE_URL = "https://newsmcp.io/v1";

function getBaseUrl(): string {
  return (process.env.NEWS_API_BASE_URL || DEFAULT_BASE_URL).replace(/\/+$/, "");
}

async function fetchJson<T>(path: string, params?: Record<string, string>): Promise<T> {
  const url = new URL(path, getBaseUrl() + "/");
  if (params) {
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== "") {
        url.searchParams.set(key, value);
      }
    }
  }

  const response = await fetch(url.toString(), {
    headers: { Accept: "application/json" },
  });

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error(`API error ${response.status}: ${text || response.statusText}`);
  }

  return response.json() as Promise<T>;
}

export async function getNews(params: {
  topics?: string;
  geo?: string;
  hours?: number;
  page?: number;
  per_page?: number;
  order_by?: string;
}): Promise<NewsListResponse> {
  const query: Record<string, string> = {};
  if (params.topics) query.topics = params.topics;
  if (params.geo) query.geo = params.geo;
  if (params.hours !== undefined) query.hours = String(params.hours);
  if (params.page !== undefined) query.page = String(params.page);
  if (params.per_page !== undefined) query.per_page = String(params.per_page);
  if (params.order_by) query.order_by = params.order_by;

  return fetchJson<NewsListResponse>("news/", query);
}

export async function getNewsDetail(eventId: string): Promise<NewsEventDetail> {
  return fetchJson<NewsEventDetail>(`news/${eventId}/`);
}

export async function getTopics(): Promise<NewsTopicsResponse> {
  return fetchJson<NewsTopicsResponse>("news/topics/");
}

export async function getRegions(): Promise<NewsRegionsResponse> {
  return fetchJson<NewsRegionsResponse>("news/regions/");
}
