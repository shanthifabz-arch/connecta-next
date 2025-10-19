// lib/supabaseClient.ts
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Read env using multiple common names so CI/hosting differences don't break imports.
 * Primary: NEXT_PUBLIC_* (browser-safe)
 * Fallbacks: SUPABASE_* (some CI setups)
 */
const url =
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  process.env.SUPABASE_URL ||
  '';

const anon =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  process.env.SUPABASE_ANON_KEY ||
  '';

declare global {
  // Avoid multiple instances in dev/HMR
  // eslint-disable-next-line no-var
  var __supabase__: SupabaseClient | undefined;
}

function makeClient(): SupabaseClient | undefined {
  if (!url || !anon) {
    if (process.env.NODE_ENV !== 'production') {
      console.warn(
        '[supabase] Missing public URL and/or anon key; client disabled in this env. ' +
        'Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY (or SUPABASE_URL/SUPABASE_ANON_KEY).'
      );
    }
    return undefined;
  }
  try {
    // Disable session persistence for SSR/CI safety; adjust if needed
    return createClient(url, anon, { auth: { persistSession: false } });
  } catch (e: any) {
    if (process.env.NODE_ENV !== 'production') {
      console.warn('[supabase] createClient failed:', e?.message || String(e));
    }
    return undefined;
  }
}

/**
 * Single instance across the app (kept for HMR).
 * NOTE: If envs are missing, this will be undefined at runtime.
 */
export const supabase: SupabaseClient =
  (globalThis.__supabase__ ??= (makeClient() as unknown as SupabaseClient));

if (process.env.NODE_ENV === 'development') {
  globalThis.__supabase__ = supabase;
}

/** Optional helpers (no behavior change unless you use them) */
export const isSupabaseReady = Boolean(url && anon);
export const getSupabase = (): SupabaseClient | undefined => supabase;

/** Throws a clear error if you intentionally want to require a ready client */
export function requireSupabase(): SupabaseClient {
  if (!supabase) {
    throw new Error(
      'Supabase client is not initialized. Ensure NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY are set in this environment.'
    );
  }
  return supabase;
}
