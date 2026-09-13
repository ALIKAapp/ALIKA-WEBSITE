-- Alika schema v10 — expose each event's cover photo to the public RSVP page.
--
-- Why this is needed: the rsvp.html page on the website now shows the same
-- cover photo the host picked or uploaded for the event, behind the purple
-- header. The guest-facing lookup function (get_guest_for_rsvp) didn't
-- return that column before, so it has nothing to show without this update.
--
-- How to run this: same as the other schema_vX.sql files in this project —
-- open your Supabase project -> SQL Editor -> New query -> paste this whole
-- file -> Run. Safe to re-run any time.

-- Postgres won't let CREATE OR REPLACE change a function's return columns,
-- so the old version is dropped first, then recreated with cover_photo_url
-- added to what it returns.
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
  cover_photo_url text
)
language sql
security definer
set search_path = public
as $$
  select g.id, g.name, g.rsvp_status, g.invitation_type, e.name, e.event_date, e.event_time, e.venue, e.cover_photo_url
  from guests g
  join events e on e.id = g.event_id
  where g.code = upper(p_code)
  limit 1;
$$;

grant execute on function get_guest_for_rsvp(text) to anon, authenticated;
