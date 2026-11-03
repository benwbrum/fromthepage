# Cloudflare: bot mitigation and safe caching

These are operator instructions for the `fromthepage.com` zone, following the
New Relic performance investigation. They do not change production settings.
Dashboard labels and available rate-limit periods vary by plan.

Related work: [crawler error fixes](https://github.com/benwbrum/fromthepage/pull/5973),
[New Relic instrumentation](https://github.com/benwbrum/fromthepage/pull/5974)
and [client-side performance](https://github.com/benwbrum/fromthepage/pull/5975).
These instructions supersede the earlier chat suggestions to block visitors
based on challenge solve rate or force-cache anonymous Rails HTML.

## 1. Pilot a Managed Challenge, without Bot Management scores

The observed high-volume cohort used `Macintosh; Intel Mac OS X 10_15_7`.
That string also occurs in legitimate browsers; it is not proof of automation.
The session cookie is `_fromthepage_session`
(`config/initializers/session_store.rb`). Its presence does not prove a person
is authenticated, and any client can send a cookie with that name.

Prefer the cookie-based condition over a country list as an initial experiment:
it is not limited to particular countries and excludes existing sessions.
Neither condition is a durable defense against an adaptive scraper. Start with
a narrow set of HTML page routes, not every request:

1. Select the zone. Open **Security -> WAF -> Custom rules** (in some dashboard
   versions, **Security -> Security rules -> Custom rules**).
2. Select **Create rule**, name it `Pilot anonymous macOS page challenge`, then
   choose **Edit expression** and enter:

   ```text
   (http.user_agent contains "Macintosh; Intel Mac OS X 10_15_7"
    and not http.cookie contains "_fromthepage_session"
    and not cf.client.bot
    and http.request.method eq "GET"
    and any(http.request.headers["accept"][*] contains "text/html")
    and (http.request.uri.path contains "/display/"
         or http.request.uri.path contains "/transcribe/"
         or http.request.uri.path contains "/article/"))
   ```

3. Choose **Managed Challenge**, not Block. Review rule order: an earlier Skip
   rule may prevent evaluation. Deploy during a staffed observation window.
4. Open **Security -> Events**, filter by this rule, and inspect matched paths,
   actions and sampled user agents. Compare origin request rate and signed-in
   user latency in New Relic before and after the change.
5. Test a real Chrome browser's first visit, navigation, sign-in, images and
   transcription flow. Passing the challenge may set Cloudflare's clearance
   cookie; it does not itself create a Rails session. Subsequent challenges
   depend on clearance, browser behavior and zone settings.

The positive route and HTML filters keep this pilot away from assets, IIIF,
Active Storage, API and AJAX requests. A challenge is an HTML interstitial,
so do not apply it broadly to subresources. Requests without these paths or
headers are deliberately outside this pilot's scope.

No matches after ten minutes does not necessarily mean a broken rule. Check
the selected zone, deployed/enabled state, rule order, time range and a recent
matching navigation. Security event visibility may be sampled or delayed.
Confirm origin traffic is still present before widening a rule.

A high challenge solve rate can mean legitimate people passed it, or automation
passed it. **Do not switch to Block solely because of the solve rate**, and do
not use an arbitrary percentage as a blocking threshold. Inspect sustained
request behavior and false positives first. Disable the pilot immediately if
ordinary navigation is affected.

If experimenting with a geographic condition separately, each ISO country code
must be its own quoted value, for example
`ip.geoip.country in {"BR" "SG" "HK" "AR" "CO" "VN" "ID" "MX"}`.
One value containing spaces is not a country list. Geography misses other
origins and can disproportionately challenge legitimate users in those regions.

## 2. Add a behavioral rate limit only after observing legitimate traffic

Open **Security -> WAF -> Rate limiting rules -> Create rule** (or the rate
limiting section under **Security rules**). Use the same HTML route/method
scope as above. Unlike the pilot, a behavioral rule need not depend on the
macOS user agent, since it is easily changed.

- Use the source IP characteristic where available. Shared networks/NAT mean
  one IP may represent many people.
- If the plan supports a one-minute period, 100 matching navigations per IP per
  minute is an example pilot threshold, not a measured safe limit. Compare it
  with legitimate traffic peaks first.
- Select the least disruptive supported mitigation. Some plans only offer
  Block or shorter counting periods; do not broaden the match just to fit a
  preset. If suitable settings are unavailable, leave this rule disabled.
- Keep mitigation duration short initially and observe the resulting 429s or
  challenges. Keep APIs, tiles, downloads and transcription-save POSTs outside
  this rule.

A bot can bypass a no-session-cookie filter by sending a cookie. If origin
traffic remains abusive, investigate measured request behavior before adding a
separately tuned rule for cookie-bearing traffic. Do not remove the exemption
globally without checking legitimate user impact.

## 3. Do not force-cache anonymous Rails HTML yet

**If the earlier suggested anonymous HTML cache rule was enabled, disable it
and purge the affected HTML URLs through Caching -> Configuration -> Purge
Cache -> Custom Purge.** Changing a rule alone does not remove existing cached
objects. Leave unrelated static assets cached.

The application layout emits session-specific CSRF meta tags and a cookie
consent form. Anonymous GETs can establish a Rails session. An incoming
no-session-cookie condition does not guarantee a cacheable response, and broad
path wildcards can match private or stateful pages. Overriding `private`,
`no-cache` or `Set-Cookie` handling risks sharing session-dependent HTML,
breaking CSRF/consent flows or exposing private content. Ignoring query strings
can also serve the wrong pagination or search results.

For now, retain Cloudflare's normal HTML caching behavior and respect origin
cache directives. Do not deploy the proposed ten-minute HTML override.
Future HTML caching needs an explicit origin-side contract: allowlisted public
routes, no user/session-specific content or `Set-Cookie`, correct query and
authorization variation, an invalidation policy, and tests for consent,
sign-in, private collections and revocation. This is separate implementation
work, not a safe dashboard-only optimization.

## 4. Cache verified content-digested public assets

First inspect the deployed `/assets/` directory or asset manifest. One-year
freshness is safe only for files whose URL changes with their content.

1. Open **Caching -> Cache Rules -> Create rule**.
2. If every served file under `/assets/` is content-digested, use
   `(starts_with(http.request.uri.path, "/assets/"))`. Otherwise narrow the rule
   to verified digested files; do not apply it to the whole directory.
3. Set **Cache eligibility -> Eligible for cache**.
4. Set **Edge TTL -> Override origin -> 1 year** and **Browser TTL -> Override
   origin -> 1 year** for this static-only scope.
5. Leave the default cache key, including query strings. Keep older digested
   assets available across deploys and rollbacks.
6. Verify a known compiled asset: its Cache-Control/browser TTL and, after
   repeat requests, `CF-Cache-Status` and `Age`. A first cache miss is normal.

Do not extend this rule to HTML, `/rails/active_storage/`, `/image-service/`,
private images or object-storage signed URLs. Image caching requires its own
authorization, CORS and expiry review.

## Measuring impact and rollback

Once the instrumentation PR is deployed, compare the suspect cohort reaching
Rails, without treating it as a definitive bot count:

```sql
SELECT rate(count(*), 1 minute) FROM Transaction
WHERE request_kind = 'suspect' SINCE 1 day ago TIMESERIES
```

After enabling the Browser attribute allowlist from that PR, compare signed-in
user experience separately:

```sql
SELECT percentile(backendDuration, 50, 95) FROM PageView
WHERE logged_in = true SINCE 1 day ago COMPARE WITH 1 week ago
```

Also track request-queue time, errors, database connections and normal navigation.
Change one rule at a time and record its activation time. To roll back a WAF
pilot, disable that rule. To roll back a cache change, disable it and purge its
affected URLs; a long browser TTL cannot be remotely revoked, which is why the
one-year rule must only cover content-digested public assets.
