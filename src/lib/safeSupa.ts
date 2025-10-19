import { PostgrestError } from "@supabase/supabase-js";

type SupaFn<T> = () => Promise<{ data: T | null; error: PostgrestError | null }>;

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

/**
 * Wrap Supabase calls for a clean error string, quick retry, and a timeout.
 * Usage:
 *   const { data, error } = await safeSupa(() =>
 *     supabase.from("countries").select("name")
 *   );
 */
export async function safeSupa<T>(
  fn: SupaFn<T>,
  opts: { retries?: number; timeoutMs?: number } = {}
): Promise<{ data: T | null; error: string | null }> {
  const retries = Math.max(0, opts.retries ?? 1);       // default: 1 retry
  const timeoutMs = Math.max(1000, opts.timeoutMs ?? 5000);

  for (let attempt = 0; attempt <= retries; attempt++) {
    const controller = new AbortController();
    const t = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const { data, error } = await fn();               // run the query
      clearTimeout(t);

      if (!error) return { data, error: null };

      // Postgrest error (auth/RLS/4xx/5xx)
      const msg = error.message || "Request failed";
      if (attempt === retries) return { data: null, error: msg };
    } catch (e: any) {
      clearTimeout(t);
      const msg = e?.message || "Network error";
      if (attempt === retries) return { data: null, error: msg };
    }

    // tiny backoff before retry
    await sleep(250);
  }

  return { data: null, error: "Unknown error" };
}
