# Client-side performance notes

New Relic showed a gap between browser-measured response time and Rails
duration, plus long image-page load times. Queueing, third-party downloads,
asset caching and full-size images are candidates to investigate, not proven
causes of every slow page. This note records the app changes and operator
settings to evaluate.

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

The sampled asset responses had `Cache-Control: max-age=14400` (four hours).
Content-digested assets can safely have longer freshness lifetimes; files with
stable, non-digested names cannot. In Cloudflare -> **Caching -> Cache Rules**,
restrict a one-year rule to the compiled, digested assets you have verified:

- If `/assets/` contains only content-digested files, the expression is
  `(starts_with(http.request.uri.path, "/assets/"))`. Otherwise narrow the
  match to verified digested files; do not extend the lifetime of the whole
  directory.
- **Then**: Eligible for cache; Edge TTL override -> 1 year; Browser TTL
  override -> 1 year. Leave the default cache key, including query strings.
- Keep older digested files available across deployments, including during
  rollbacks.

Alternatively set equivalent headers in the existing nginx static-asset
location, scoped only to digested files:

```nginx
expires 1y;
add_header Cache-Control "public, immutable";
```

Check a compiled asset's response headers and `CF-Cache-Status` before and
after deployment. Do not apply this policy to HTML, Active Storage URLs,
private images or authenticated routes.

### Self-host the remaining third-party scripts (follow-up)

`openseadragon.min.js` (cdnjs), `popper`/`tippy` (jsdelivr), `chart.js` (jspm)
and Google Fonts add third-party connections to a cold load. A CDN outage can
break the features that depend on it. Vendoring them into
`vendor/assets/javascripts` (or via the importmap `./bin/importmap pin`) removes
~4 connections from the critical path; this was not done in this change because
the agent sandbox cannot reach those CDNs to fetch the files.

### Page images (follow-up)

The sampled `display_page` LCP p95 was about 24 s. Pages below
`TranscribeHelper::OSD_DIRECT_IMAGE_MAX_DIMENSION` (16,384 px) can be served to
OpenSeadragon as a single full-size blob via a redirect to object storage.
This is a candidate contributor; confirm with a browser waterfall before
changing delivery. Options to evaluate:

1. Evaluate an edge cache for public image derivatives. Preserve authorization
   and signed-URL semantics, exclude private material and verify CORS; do not
   put a blanket shared-cache rule on Active Storage or the object store.
2. Lower `OSD_DIRECT_IMAGE_MAX_DIMENSION` so large scans use the tiled
   `/image-service/:id/info.json` source — but only after the `riiif`
   controller (currently 2.8 s average) is fronted by a cache, otherwise the
   first uncached tile request could add origin work and increase latency.
3. Serve a pre-generated pyramidal TIFF/IIIF derivative at upload time.

Compare the same pages and image dimensions before and after each change,
including cold/warm loads, desktop/mobile, zooming and orientation. Track LCP,
CLS, bytes transferred and image-service latency/error rates. Inspect layout
shifts before adding dimensions to the viewer; preserve its existing resize
and monitor-view behavior.

Use signed-in user telemetry where possible. `request_kind = 'human'` in
`doc/new_relic_instrumentation.md` is a heuristic label, not proof of a person.
Image-delivery and CLS code changes remain follow-up work; this PR does not
change the tiling threshold or shared-cache policy.
