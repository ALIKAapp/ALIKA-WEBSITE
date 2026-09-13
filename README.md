# Alika website

A small, static, multi-page website that sits alongside the Alika app. It is
**informational only** — creating events, adding guests, sending invitations
and scanning check-ins all still happen in the app. This site covers the two
things that need to work *outside* the app:

1. **`rsvp.html`** — what a guest sees when they tap their personal invitation
   link. It's now a full animated invitation page ("classic" template, the
   first of what can become several): a hero photo with a slow zoom, a live
   countdown to the event, a swipeable photo gallery with tap-to-enlarge, a
   background-music toggle (the host's own uploaded song), a "Get
   Directions" button, dress code, and the same accept/decline buttons as
   before at the end — all on the guest's existing personal link, same
   `?code=` format as always. Every one of those extras is optional: an
   event with no gallery photos and no song still shows a clean, simple
   invitation, so nothing breaks for events created before this update. This
   replaces `web-rsvp/index.html` (same underlying Supabase RPC calls) — it's
   now one page inside a real website instead of a single standalone file.
2. **`dashboard.html`** + **`dashboard-home.html`** — a read-only,
   password-protected view for you (the host). `dashboard.html` is just the
   sign-in form; once you sign in with your existing Alika account (same
   email/password as the app), it takes you to `dashboard-home.html` — a
   separate page showing live accepted/declined/pending counts and guest
   lists for every event. It only ever reads data — everything RLS already
   restricts to `auth.uid() = host_id` in `supabase/schema.sql` applies here
   exactly as it does in the app, so a host can only ever see their own
   events.

Everything else (`index.html`, `features.html`, `pricing.html`,
`support.html`) is marketing/informational content about Alika itself.

## Structure

```
index.html           Home
features.html        Feature list
pricing.html         Free vs Premium, payment methods
support.html         Download Alika (WhatsApp) + FAQ
rsvp.html             Guest RSVP page (?code=XXXXX) — the animated invitation
dashboard.html        Host sign-in page
dashboard-home.html   The actual dashboard (only reachable once signed in)
assets/
  css/style.css        shared site styles, icons, scroll-reveal animations
  js/site.js           mobile nav toggle, active-link highlight, scroll-reveal
  js/supabase-client.js shared Supabase client (rsvp.html + dashboard*.html)
supabase-migration-v10-rsvp-cover-photo.sql      run this once — see below
supabase-migration-v11-animated-invitation.sql   run this once — see below
```

No build step, no dependencies to install — it's plain HTML/CSS/JS. Open any
page in a browser once deployed, or serve the folder locally with e.g.
`npx serve .` or `python3 -m http.server` (opening `rsvp.html`/`dashboard.html`
directly via `file://` will not run their scripts, since browsers block
`type="module"` imports from `file://` — this only matters for local
preview, not for how it works once deployed).

## One-time database update — event cover photos on the RSVP page

The RSVP page now shows the event's cover photo (the same one the host
picked or uploaded in the app) behind the purple header. The database
function guests use to look up their invitation didn't send that column
before, so **run `supabase-migration-v10-rsvp-cover-photo.sql` once** in your
Supabase project — same process as the other `schema_vX.sql` files: open
your project → SQL Editor → New query → paste the whole file → Run. Safe to
re-run any time. Skip this and the RSVP page still works fine, it just won't
show a cover photo.

## One-time database update — the animated invitation (gallery, song, dress code)

Run `supabase-migration-v11-animated-invitation.sql` once too (after v10,
same SQL Editor → New query → paste → Run process). This adds:

- `gallery_photos`, `song_url`, `dress_code`, `invitation_template` columns
  on `events` (all optional — an event with none of these set just shows the
  simpler invitation, nothing breaks).
- A new `invitation-media` storage bucket for the gallery photos and song
  files the app will upload, public to read, but a host can only write
  inside their own folder (`${host_id}/${event_id}/...`).
- An updated `get_guest_for_rsvp` function that sends these fields to the
  RSVP page.

**This migration only prepares the database and website side.** The app
itself doesn't have a screen yet for a host to upload gallery photos, pick a
song, or set a dress code — that's a separate change inside the app's code.
See the note below for a ready-to-use Claude Code prompt for that part.

### Wiring up the app side (Claude Code prompt)

Once the migration above has been run, paste this into Claude Code in your
Alika app project to add the host-facing side:

```
I've added new fields to the `events` table and a new `invitation-media`
storage bucket in Supabase (see supabase-migration-v11-animated-invitation.sql
if you want the exact schema). I'd like the app to let a host, from the
event form (or a new step in it), optionally:

1. Upload multiple photos for a "gallery" — save them to the
   `invitation-media` bucket at path
   `${host_id}/${event_id}/gallery/<filename>`, and store the resulting
   public URLs as a JSON array in the event's `gallery_photos` column.
2. Upload one audio file as the event's background song — save it to
   `${host_id}/${event_id}/song.<ext>` in the same bucket, and store its
   public URL in the event's `song_url` column.
3. Optionally type a short dress code — save it to the event's `dress_code`
   text column.

All three are optional edits to an existing event (update, not insert), and
none of this should block or change how creating an event or generating a
guest's invitation link works today. Please check whichever screen handles
editing an event's cover/details (I believe that's EventFormScreen.tsx) and
add this there, following the existing patterns for uploading the cover
photo to Supabase Storage in this codebase.
```

## Deploying

Same as the original `web-rsvp/index.html` — any static host works
(Netlify, Vercel, GitHub Pages, or your own server). Deploy this whole
folder as-is.

**Important — update `RSVP_BASE_URL`:** once this is deployed, update
`src/lib/config.ts` in the app so guest links point at the new page:

```ts
export const RSVP_BASE_URL = "https://your-domain.com/rsvp.html";
```

(Previously this pointed at wherever `web-rsvp/index.html` was deployed —
just repoint it at `rsvp.html` on the new site. Guest links are still built
as `${RSVP_BASE_URL}?code=<code>`, unchanged.)

You can now retire the standalone `web-rsvp/` folder — `rsvp.html` here is
its replacement, restyled to match the rest of the site but using the exact
same `get_guest_for_rsvp` / `submit_rsvp` calls.

## Supabase project

`assets/js/supabase-client.js` uses the same public project URL and anon
key already committed in `web-rsvp/index.html` and `.env` — this is safe,
since it's the same anon key your app ships with and every table it touches
is protected by Row Level Security, not by keeping the key secret. If you
ever move to a different Supabase project, update the two values in that
one file (and your app's `.env`) together.

## What changed in this update

- **Animated invitation page** — hero photo with a slow zoom, live
  countdown, photo gallery with lightbox, background-music toggle, "Get
  Directions" button and dress code, all on the guest's existing personal
  link. See the migration note above — the app side still needs the Claude
  Code prompt above to let hosts actually upload the photos/song.
- **Event cover photo on the RSVP page** (from the previous update) — still
  used as the hero photo when there's no gallery yet.
- **"Download Alika"** replaces "Get Alika" everywhere (button text, the
  `support.html#download-alika` section/anchor, page titles).
- **Scroll animations** — cards, steps and section headers on the marketing
  pages now fade/slide into view as you scroll (alternating from the left
  and right on feature grids), respecting the visitor's OS-level "reduce
  motion" setting.
- **Icons instead of emoji** — every feature/contact icon is now a small
  line-drawing in Alika's brand purple/gold, matching the app's visual style
  instead of relying on emoji rendering (which looks different across
  devices and operating systems).
- **Dashboard is now two pages** — `dashboard.html` (sign in) hands off to
  `dashboard-home.html` (the actual dashboard) with a real page navigation,
  instead of swapping content in and out on one page. Visiting
  `dashboard-home.html` directly without a session just bounces you back to
  the sign-in page.

## About "multiple templates"

`invitation_template` on `events` (default `"classic"`) is there so more
visual templates can be added later without another schema change — a
second template would mean a new `rsvp-<name>.html`-style page (or the same
page branching on `guest.invitation_template`), plus a way for the host to
pick a template in the app. Only "classic" (this one) exists today.

## Content notes / assumptions

- **Pricing copy** (Free vs Premium, TZS 300/card, payment methods) is taken
  directly from `ChoosePlanScreen.tsx` — update here if pricing changes.
- The dashboard shows accepted/declined/pending counts and a guest table per
  event; it does not expose phone numbers or let you edit/check in guests
  from the browser — that's intentionally left to the app.
- There's still no App Store/Play Store listing per the app's own README, so
  "Download Alika" links out to WhatsApp (the number from
  `SUPPORT_WHATSAPP_NUMBER` in `config.ts`) rather than store badges. Swap
  this once Alika is listed.
