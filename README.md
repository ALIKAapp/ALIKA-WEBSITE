# Alika website

A small, static, multi-page website that sits alongside the Alika app. It is
**informational only** — creating events, adding guests, sending invitations
and scanning check-ins all still happen in the app. This site covers the two
things that need to work *outside* the app:

1. **`rsvp.html`** — what a guest sees when they tap their personal invitation
   link. Shows the event details and one tap to accept/decline. This
   replaces `web-rsvp/index.html` (same Supabase RPC calls, same `?code=`
   link format) — it's now one page inside a real website instead of a
   single standalone file.
2. **`dashboard.html`** — a read-only, password-protected view for you (the
   host). Sign in with your existing Alika account (same email/password as
   the app) to see live accepted/declined/pending counts and guest lists for
   every event, from any browser. It only ever reads data — everything RLS
   already restricts to `auth.uid() = host_id` in `supabase/schema.sql`
   applies here exactly as it does in the app, so a host can only ever see
   their own events.

Everything else (`index.html`, `features.html`, `pricing.html`,
`support.html`) is marketing/informational content about Alika itself.

## Structure

```
index.html         Home
features.html      Feature list
pricing.html       Free vs Premium, payment methods
support.html       Get Alika (WhatsApp) + FAQ
rsvp.html          Guest RSVP page  (?code=XXXXX)
dashboard.html     Host login + live RSVP dashboard
assets/
  css/style.css        shared site styles
  js/site.js           mobile nav toggle, active-link highlight
  js/supabase-client.js shared Supabase client (rsvp.html + dashboard.html)
```

No build step, no dependencies to install — it's plain HTML/CSS/JS. Open any
page in a browser once deployed, or serve the folder locally with e.g.
`npx serve .` or `python3 -m http.server` (opening `rsvp.html`/`dashboard.html`
directly via `file://` will not run their scripts, since browsers block
`type="module"` imports from `file://` — this only matters for local
preview, not for how it works once deployed).

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

## Content notes / assumptions

A few things were written from what's in the app today — worth a look
before you consider this final:

- **"Get Alika" (support.html)** links out to WhatsApp (the number from
  `SUPPORT_WHATSAPP_NUMBER` in `config.ts`) since there's no App Store/Play
  Store listing yet per the app's own README. Swap this for real store
  badges once Alika is listed.
- **Pricing copy** (Free vs Premium, TZS 300/card, payment methods) is taken
  directly from `ChoosePlanScreen.tsx` — update here if pricing changes.
- The dashboard shows accepted/declined/pending counts and a guest table per
  event; it does not expose phone numbers or let you edit/check in guests
  from the browser — that's intentionally left to the app.
