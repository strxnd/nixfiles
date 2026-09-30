/**
 * Minimal Firecrawl REST client — a dependency-free replacement for the
 * `firecrawl` npm package.
 *
 * The upstream SDK's dependency graph (axios → follow-redirects, etc.) cannot
 * be loaded by pi's extension runtime, so this module talks to the same
 * Firecrawl HTTP API directly using only Node built-ins and global fetch.
 * It exposes exactly the surface the search/scrape/crawl tools use.
 */

/**
 * The public read model of a crawl job.
 */
export interface CrawlJob {
  readonly id: string;
  readonly status?:
    "queued" | "scraping" | "processing" | "completed" | "failed" | "cancelled";
  readonly data?: unknown;
  readonly [key: string]: unknown;
}

export interface CrawlOptions {
  readonly limit?: number;
  readonly maxDiscoveryDepth?: number;
  readonly includePaths?: string[];
  readonly excludePaths?: string[];
  readonly crawlEntireDomain?: boolean;
  readonly allowSubdomains?: boolean;
  readonly sitemap?: "include" | "skip" | "only";
  readonly scrapeOptions?: {
    readonly formats?: string[];
    readonly onlyMainContent?: boolean;
  };
}

export interface FirecrawlDocument {
  readonly markdown?: string;
  readonly metadata?: Record<string, unknown>;
  readonly [key: string]: unknown;
}

const DEFAULT_API_URL = "https://api.firecrawl.dev";

function rebaseUrl(base: string, path: string) {
  return `${base.replace(/\/$/, "")}${path}`;
}

export class Firecrawl {
  readonly apiKey: string;
  readonly apiUrl: string;

  constructor(options: { apiKey: string; apiUrl?: string }) {
    this.apiKey = options.apiKey;
    this.apiUrl =
      options.apiUrl ?? process.env.FIRECRAWL_API_URL ?? DEFAULT_API_URL;
  }

  private async request(
    path: string,
    init: { method: string; body?: unknown } = { method: "GET" },
  ) {
    const response = await fetch(rebaseUrl(this.apiUrl, path), {
      method: init.method,
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: init.body === undefined ? undefined : JSON.stringify(init.body),
    });

    if (!response.ok) {
      let detail = "";
      try {
        const parsed = (await response.json()) as {
          error?: string;
          message?: string;
        };
        detail = parsed.error ?? parsed.message ?? "";
      } catch {
        // non-JSON error body
      }
      throw new Error(
        `Firecrawl request failed (${response.status}${detail ? `: ${detail}` : ""})`,
      );
    }

    return (await response.json()) as Record<string, unknown>;
  }

  async search(
    query: string,
    options?: {
      limit?: number;
      sources?: string[];
      scrapeOptions?: unknown;
      timeout?: number;
    },
  ): Promise<{ success: boolean; data: unknown[] }> {
    const body = await this.request("/v1/search", {
      method: "POST",
      body: { query, ...options },
    });
    return {
      success: true,
      data: Array.isArray(body.data) ? body.data : [],
    };
  }

  async scrape(
    url: string,
    options?: Record<string, unknown>,
  ): Promise<FirecrawlDocument> {
    const body = await this.request("/v1/scrape", {
      method: "POST",
      body: { url, ...options },
    });
    // The upstream API nests the document under `data`; normalize so the
    // caller can read `.markdown` / `.metadata` directly.
    return (body.data ?? body) as FirecrawlDocument;
  }

  async startCrawl(url: string, options?: CrawlOptions): Promise<CrawlJob> {
    const body = await this.request("/v1/crawl", {
      method: "POST",
      body: { url, ...options },
    });
    const id =
      typeof body.id === "string"
        ? body.id
        : typeof body.jobId === "string"
          ? body.jobId
          : "";
    return {
      id,
      status: "queued",
      ...body,
    } as CrawlJob;
  }

  async getCrawlStatus(jobId: string): Promise<CrawlJob> {
    const body = await this.request(`/v1/crawl/${encodeURIComponent(jobId)}`);
    // The extension polls while `status === "scraping"`; fold non-terminal
    // statuses into "scraping" so the wait does not end early.
    const raw = typeof body.status === "string" ? body.status : "scraping";
    const status = raw === "queued" || raw === "processing" ? "scraping" : raw;
    return { id: jobId, status, ...body } as CrawlJob;
  }

  async cancelCrawl(jobId: string): Promise<unknown> {
    const body = await this.request(`/v1/crawl/${encodeURIComponent(jobId)}`, {
      method: "DELETE",
    });
    return { success: true, ...body };
  }
}
