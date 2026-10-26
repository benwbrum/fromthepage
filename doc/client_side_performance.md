# Client-side performance notes

Browser-measured page load on fromthepage.com is dominated by things that
happen *after* Rails has answered: third-party script downloads, static asset
revalidation and full-size page images. This note records what the app does and
the operator-side settings that go with it.

## What the app does

- `<link rel="preconnect">` for `fonts.googleapis.com`, `fonts.gstatic.com`,
  `cdn.jsdelivr.net` and `cdnjs.cloudflare.com` so the TLS handshakes overlap
  with HTML parsing.
- Google Fonts are requested with `display=swap`, so text renders in a fallback
  font immediately instead of staying invisible until the webfont arrives.
- `popper.js` and `tippy.js` are loaded with `defer`; they are only called from
  `$(function () {...})` handlers, so they never need to block parsing.
- `slick` is served from the asset pipeline (`landing/slick.min.js`) and only
  on the two pages that have a carousel (landing page, owner profile).

## Operator steps

### Static asset TTL (Cloudflare Cache Rule)

Fingerprinted assets under `/assets/*` are immutable, but the origin currently
sends `Cache-Control: max-age=14400`, so every returning visitor revalidates
~80 files each day. In Cloudflare → **Caching → Cache Rules** add:

- **When**: `(starts_with(http.request.uri.path, "/assets/"))`
- **Then**: Eligible for cache · Edge TTL *Override origin* → 1 year ·
  Browser TTL *Override origin* → 1 year · Cache key: ignore query string off
  (the digest is in the path, the query string is unused).

Alternatively set it at the origin in the nginx `location ~ ^/assets/` block:

```nginx
expires 1y;
add_header Cache-Control "public, immutable";
```

### Self-host the remaining third-party scripts (follow-up)

`openseadragon.min.js` (cdnjs), `popper`/`tippy` (jsdelivr), `chart.js` (jspm)
and Google Fonts each add a DNS lookup + TLS handshake to a cold load, and the
site is down if any of those CDNs is. Vendoring them into
`vendor/assets/javascripts` (or via the importmap `./bin/importmap pin`) removes
~4 connections from the critical path; this was not done in this change because
the agent sandbox cannot reach those CDNs to fetch the files.

### Page images (follow-up)

`display_page` LCP p95 is ~24 s because pages below
`TranscribeHelper::OSD_DIRECT_IMAGE_MAX_DIMENSION` (16 384 px) are served to
OpenSeadragon as a single full-size blob via a 302 to object storage. Options,
in rough order of effort:

1. Put the object-storage host behind Cloudflare (or any cache) so repeated
   loads of the same image are served from the edge.
2. Lower `OSD_DIRECT_IMAGE_MAX_DIMENSION` so large scans use the tiled
   `/image-service/:id/info.json` source — but only after the `riiif`
   controller (currently 2.8 s average) is fronted by a cache, otherwise the
   first tile request is slower than the blob.
3. Serve a pre-generated pyramidal TIFF/IIIF derivative at upload time.

Measure each with the `request_kind = 'human'` filter described in
`doc/new_relic_instrumentation.md`.
