// src/lib/supabase-browser.ts
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/** Singleton Supabase client for the BROWSER (client components only). */
let _client: SupabaseClient | null = null;

export function getSupabaseBrowser(): SupabaseClient {
  if (!_client) {
    _client = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL as string,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY as string,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      }
    );
  }
  return _client;
}

/** Convenience named export for modules that do `import { supabase } ...` */
export const supabase = getSupabaseBrowser();
