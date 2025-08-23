import { createClient, SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

declare global {
  // To avoid multiple instances of Supabase client in dev mode
  // eslint-disable-next-line no-var
  var supabase: SupabaseClient | undefined;
}

/**
 * Use a single Supabase client instance across your app.
 * This avoids multiple GoTrueClient instances warning in the browser console.
 */
export const supabase: SupabaseClient =
  global.supabase ?? createClient(supabaseUrl, supabaseAnonKey);

if (process.env.NODE_ENV === 'development') global.supabase = supabase;

