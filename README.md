# Alika website

A small, static, multi-page website that sits alongside the Alika app. It is
**informational only** — creating events, adding guests, sending invitations
and scanning check-ins all still happen in the app. This site covers the two
things that need to work *outside* the app:

1. **`rsvp.html`** — what a guest sees when they tap their personal invitation
   link. Shows the event details (including the event's cover photo, if the
   host set one, and a live countdown to the event) and one tap to
   accept/decline. This replaces `web-rsvp/index.html` (same Supabase RPC
   calls, same `?code=` link format) — it's now one page inside a real
   website instead of a single standalone file.
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
rsvp.html             Guest RSVP page (?code=XXXXX) — with a live countdown
dashboard.html        Host sign-in page
dashboard-home.html   The actual dashboard (only reachable once signed in)
assets/
  css/style.css        shared site styles, icons, scroll-reveal animations
  js/site.js           mobile nav toggle, active-link highlight, scroll-reveal
  js/supabase-client.js shared Supabase client (rsvp.html + dashboard*.html)
supabase-migration-v10-rsvp-cover-photo.sql   run this once — see below
```

No build step, no dependencies to install — it's plain HTML/CSS/JS. Open any
page in a browser once deployed, or serve the folder locally with e.g.
`npx serve .` or `python3 -m http.server` (opening `rsvp.html`/`dashboard.html`
directly via `file://` will not run their scripts, since browsers block
`type="module"` imports from `file://` — this only matters for local
preview, not for how it works once deployed).

## One-time database update — event cover photos on the RSVP page

The RSVP page shows the event's cover photo (the same one the host picked or
uploaded in the app) behind the purple header. The database function guests
use to look up their invitation didn't send that column before, so **run
`supabase-migration-v10-rsvp-cover-photo.sql` once** in your Supabase
project — same process as the other `schema_vX.sql` files: open your
project → SQL Editor → New query → paste the whole file → Run. Safe to
re-run any time. Skip this and the RSVP page still works fine, it just won't
show a cover photo.

The live countdown timer needs no database change — it's built from
`event_date`/`event_time`, which the app already saves for every event.

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

- **RSVP page reverted to the simple card design** — a photo gallery,
  background music and dress-code version was built and tried, but it's
  being kept as a separate idea for later rather than merged into the
  everyday RSVP page (see "Parked idea" below). The one piece from that
  experiment that's staying is the **live countdown timer** to the event.
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

## Parked idea: a separate animated invitation page

There's an appetite for a richer, animated invitation experience (photo
gallery, background music, dress code, "Get Directions" button) as its own
thing — not merged into the everyday RSVP link, but a distinct
service/page a host could opt into per event. That version was built once
already (hero photo with a slow zoom, live countdown, swipeable gallery
with a lightbox, a music toggle, directions button, dress code) and worked
well in testing, so it can be brought back as its own page (e.g.
`invite.html`, on its own link) rather than living inside `rsvp.html`,
whenever that's wanted. Nothing from that version is in this delivery
except the countdown, which is now part of the plain RSVP page above.

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
