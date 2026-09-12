// Shared Supabase client for the Alika website (RSVP page + host dashboard).
//
// These are the SAME public values already committed in this project's
// web-rsvp/index.html and .env — the anon/publishable key is meant to be
// public. It is safe because every table it can touch is protected by the
// Row Level Security policies in supabase/schema.sql (a guest can only ever
// reach their own row via their unique code, and a host can only ever see
// events/guests where host_id = their own auth.uid()).
//
// If you ever move this site to a different Supabase project, update both
// values here AND in the app's .env (EXPO_PUBLIC_SUPABASE_URL /
// EXPO_PUBLIC_SUPABASE_ANON_KEY) so the app and website stay in sync.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

export const SUPABASE_URL = 'https://ojtumuwujcvaxjqbzera.supabase.co';
export const SUPABASE_ANON_KEY = 'sb_publishable_2QYOlp2dUNOpTA_0NoSmhQ_UZJIDIEa';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});
