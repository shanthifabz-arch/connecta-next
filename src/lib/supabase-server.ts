// src/lib/supabase-server.ts
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Server-side Supabase client (lazy singleton).
 *
 * Preferred envs (server-only):
 *   - SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY  (⚠️ powerful key; never expose to client)
 *
 * Fallbacks (to avoid build/runtime crashes in non-prod):
 *   - NEXT_PUBLIC_SUPABASE_URL
 *   - SUPABASE_ANON_KEY or NEXT_PUBLIC_SUPABASE_ANON_KEY
 *
 * NOTE: We only read envs when this function is called (not at module load),
 * so importing this file never throws during Next.js build.
 */
let cached: SupabaseClient | null = null;

export function getSupabaseServer(): SupabaseClient {
  if (cached) return cached;

  // Prefer true server-side envs
  const url =
    (process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || "").trim();
  const serviceKey =
    (process.env.SUPABASE_SERVICE_ROLE_KEY || "").trim();

  // Allow fallback to anon keys when service key isn't provided.
  // This helps avoid crashes in CI/build or simple read-only routes.
  const anonKey =
    (process.env.SUPABASE_ANON_KEY ||
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
      "").trim();

  if (!url) {
    throw new Error(
      "Supabase server misconfigured: missing SUPABASE_URL (or NEXT_PUBLIC_SUPABASE_URL fallback)."
    );
  }

  const key = serviceKey || anonKey;
  if (!key) {
    throw new Error(
      "Supabase server misconfigured: missing SUPABASE_SERVICE_ROLE_KEY (or anon key fallback)."
    );
  }

  cached = createClient(url, key, {
    auth: { persistSession: false }, // never persist session on server
    global: { fetch },               // use Next.js runtime fetch
  });

  return cached;
}
