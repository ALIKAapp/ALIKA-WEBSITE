-- Alika schema v11 — animated invitation page (gallery + song + dress code).
--
-- What this adds, in plain terms: the guest's personal RSVP link (the same
-- one from RSVP_BASE_URL + ?code=...) now opens a richer, animated
-- invitation page instead of a plain card — with a photo gallery, the
-- host's own background song, a countdown to the event, and a "get
-- directions" button — before the same accept/decline buttons as before.
--
-- How to run this: same as every other schema_vX.sql file in this project —
-- Supabase project -> SQL Editor -> New query -> paste this whole file ->
-- Run. Safe to re-run any time. Run this AFTER
-- supabase-migration-v10-rsvp-cover-photo.sql.
--
-- Nothing here is required for an event to keep working exactly as it does
-- today — every new column is optional. An event with no gallery photos and
-- no song still shows the same simple invitation as before; the new visual
-- extras only appear once the host actually adds them.

-- 1. New optional columns on events ------------------------------------------
alter table events add column if not exists gallery_photos jsonb not null default '[]'::jsonb;
alter table events add column if not exists song_url text;
alter table events add column if not exists dress_code text;
-- Which visual template this event's invitation page uses. Only "classic"
-- exists today; this column is here so more templates can be added later
-- without another migration — the app just needs to start writing a
-- different value here once more templates exist.
alter table events add column if not exists invitation_template text not null default 'classic';

-- 2. Storage bucket for gallery photos + song files --------------------------
-- Public to read (so the invitation page — which guests view with no
-- login — can display them), but a host can only upload/replace/delete
-- files inside their OWN folder: the app should upload to
--   ${host_id}/${event_id}/gallery/<filename>
--   ${host_id}/${event_id}/song.<ext>
-- (This mirrors the pattern already used for the `avatars` bucket in
-- schema_v4.sql, and is a bit stricter than the older `cards`/`covers`
-- buckets, which allow any signed-in host to write anywhere in them.)
insert into storage.buckets (id, name, public)
  values ('invitation-media', 'invitation-media', true)
  on conflict (id) do nothing;

drop policy if exists "public read invitation media" on storage.objects;
create policy "public read invitation media" on storage.objects
  for select using (bucket_id = 'invitation-media');

drop policy if exists "hosts manage own invitation media" on storage.objects;
create policy "hosts manage own invitation media" on storage.objects
  for all to authenticated
  using (bucket_id = 'invitation-media' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'invitation-media' and (storage.foldername(name))[1] = auth.uid()::text);

-- 3. Expose the new fields (plus the venue address/coordinates already
--    added back in schema_v4.sql, for the "Get Directions" button) to the
--    public, no-login RSVP lookup. As before, this replaces the function
--    rather than editing it in place, since its return columns are
--    changing again.
drop function if exists get_guest_for_rsvp(text);

create or replace function get_guest_for_rsvp(p_code text)
returns table (
  id uuid,
  name text,
  rsvp_status text,
  invitation_type text,
  event_name text,
  event_date date,
  event_time text,
  venue text,
  cover_photo_url text,
  gallery_photos jsonb,
  song_url text,
  dress_code text,
  invitation_template text,
  address text,
  address_lat numeric,
  address_lng numeric
)
language sql
security definer
set search_path = public
as $$
  select
    g.id, g.name, g.rsvp_status, g.invitation_type,
    e.name, e.event_date, e.event_time, e.venue, e.cover_photo_url,
    e.gallery_photos, e.song_url, e.dress_code, e.invitation_template,
    e.address, e.address_lat, e.address_lng
  from guests g
  join events e on e.id = g.event_id
  where g.code = upper(p_code)
  limit 1;
$$;

grant execute on function get_guest_for_rsvp(text) to anon, authenticated;
