/**
 * Thrown when a request fails at the network level or the server returns a
 * non-accepted status. `message` is already user-presentable.
 */
export class ApiException extends Error {
  constructor(
    message: string,
    readonly statusCode?: number,
  ) {
    super(message);
    this.name = 'ApiException';
  }
}

type StatusPredicate = (code: number) => boolean;

interface RequestOptions {
  /** Statuses treated as success. Defaults to any 2xx. */
  acceptedStatuses?: StatusPredicate;
}

const JSON_HEADERS = { 'Content-Type': 'application/json' };

/**
 * A thin JSON-over-HTTP client. Repositories use this instead of calling
 * `fetch` directly, so encoding/decoding, headers and error normalisation
 * live in one place. Returns decoded JSON and throws {@link ApiException}.
 */
export async function getJson<T = unknown>(url: string, options: RequestOptions = {}): Promise<T> {
  return request<T>(url, { method: 'GET', headers: JSON_HEADERS }, options);
}

export async function postJson<T = unknown>(
  url: string,
  body: Record<string, unknown>,
  options: RequestOptions = {},
): Promise<T> {
  return request<T>(
    url,
    { method: 'POST', headers: JSON_HEADERS, body: JSON.stringify(body) },
    options,
  );
}

/** Append query parameters to a URL, skipping null/undefined values. */
export function withQuery(url: string, params: Record<string, string | null | undefined>): string {
  const query = Object.entries(params)
    .filter(([, v]) => v != null)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v as string)}`)
    .join('&');
  return query ? `${url}?${query}` : url;
}

async function request<T>(url: string, init: RequestInit, options: RequestOptions): Promise<T> {
  let res: Response;
  try {
    res = await fetch(url, init);
  } catch (e) {
    throw new ApiException(`Network error: ${e instanceof Error ? e.message : String(e)}`);
  }

  const text = await res.text();
  let decoded: unknown = null;
  if (text.length > 0) {
    try {
      decoded = JSON.parse(text);
    } catch {
      throw new ApiException(`Unexpected response (${res.status})`, res.status);
    }
  }

  const ok = options.acceptedStatuses?.(res.status) ?? (res.status >= 200 && res.status < 300);
  if (ok) return decoded as T;

  let message = `Request failed (${res.status})`;
  if (decoded && typeof decoded === 'object') {
    const body = decoded as Record<string, unknown>;
    message = String(body.error ?? body.message ?? message);
  }
  throw new ApiException(message, res.status);
}
