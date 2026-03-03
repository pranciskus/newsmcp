import type { NewsmcpConfig } from "./config.js";

export class NewsApiError extends Error {
  constructor(
    public status: number,
    public url: string,
    message: string,
  ) {
    super(message);
    this.name = "NewsApiError";
  }
}

export class NewsApiClient {
  private baseUrl: string;
  private timeoutMs: number;

  constructor(cfg: NewsmcpConfig, timeoutMs = 15_000) {
    this.baseUrl = cfg.apiBaseUrl;
    this.timeoutMs = timeoutMs;
  }

  async get<T = unknown>(
    path: string,
    params?: Record<string, string | number | undefined>,
  ): Promise<T> {
    const url = new URL(`${this.baseUrl}${path}`);
    if (params) {
      for (const [key, val] of Object.entries(params)) {
        if (val != null) url.searchParams.set(key, String(val));
      }
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const res = await fetch(url.toString(), {
        headers: {
          Accept: "application/json",
          "User-Agent": "newsmcp-openclaw/0.1",
        },
        signal: controller.signal,
      });

      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new NewsApiError(
          res.status,
          url.toString(),
          `News API ${res.status}: ${text.slice(0, 200)}`,
        );
      }

      return (await res.json()) as T;
    } catch (err) {
      if (err instanceof NewsApiError) throw err;
      if ((err as Error).name === "AbortError") {
        throw new NewsApiError(
          0,
          url.toString(),
          `News API timeout after ${this.timeoutMs}ms`,
        );
      }
      throw new NewsApiError(
        0,
        url.toString(),
        `News API request failed: ${(err as Error).message}`,
      );
    } finally {
      clearTimeout(timeout);
    }
  }
}
