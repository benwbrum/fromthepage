# New Relic instrumentation for end-user performance

This runbook collects the instrumentation changes needed to separate real-user
experience from crawler traffic and to see where time is spent *outside* Rails
(Cloudflare → nginx → Passenger queue). The code side ships with the app; the
server/UI steps below have to be done by an operator.

## What the app records

`ApplicationController` includes `NewRelicRequestAttributes`, which tags every
APM transaction (and the linked Browser `PageView`) with:

| Attribute | Values | Use |
| --- | --- | --- |
| `request_kind` | `human`, `bot`, `suspect` | `bot` = self-declared crawler (per the `browser` gem); `suspect` = the anonymous `Macintosh; Intel Mac OS X 10_15_7` Chrome fingerprint fleet with no session cookie |
| `logged_in` | `true`/`false` | Devise session present |
| `owner` | `true`/`false` | Project owner (or staff) |
| `has_session_cookie` | `true`/`false` | Whether the request carried `_fromthepage_session` |
| `collection_slug` | string | Collection in scope, when any |

Example queries:

```sql
-- real-user backend latency by action
SELECT percentile(duration, 50, 95), count(*) FROM Transaction
WHERE request_kind = 'human' SINCE 1 day ago FACET name

-- how much of the fleet is still getting through Cloudflare
SELECT rate(count(*), 1 minute) FROM Transaction
WHERE request_kind = 'suspect' SINCE 1 day ago TIMESERIES

-- browser-measured TTFB for humans vs Rails-measured duration
SELECT average(backendDuration), average(webAppDuration), average(queueDuration)
FROM PageView WHERE logged_in = true SINCE 1 day ago
```

## Operator steps

### 1. Request-queue timing (`X-Request-Start`)

`queueDuration` is currently `null` on every transaction, which hides time spent
waiting for a Passenger process. In the nginx server block for fromthepage.com
add, inside the `location` that hands off to Passenger:

```nginx
passenger_set_header X-Request-Start "t=${msec}";
```

then `nginx -t && systemctl reload nginx`. New Relic picks the header up
automatically and shows a "Request queuing" band in APM.

### 2. Distributed tracing

`config/newrelic.yml` is a Capistrano linked file (not in git). Add:

```yaml
common: &default_settings
  distributed_tracing:
    enabled: true
  browser_monitoring:
    auto_instrument: true
  attributes:
    include:
      - request.headers.userAgent
      - request.headers.referer
```

and restart Passenger (`passenger-config restart-app /`).

### 3. Upgrade the Browser agent

The site currently serves the **Lite** loader (`nr-loader-rum`), which records
only `PageView` and `PageViewTiming`. In New Relic → Browser → *FromThePage
(production)* → **Application settings**:

- Agent type: **Pro + SPA**
- Enable **Session traces**, **AJAX**, **JS errors**, **Core Web Vitals**
- Keep the existing `ajax.deny_list` entry for `bam.nr-data.net`
- Optional: **Session replay** with sampling ≤ 5% (check privacy policy first)

Because `browser_monitoring.auto_instrument` is on, the Ruby agent injects the
new loader on the next deploy/restart; nothing else changes in the app.

### 4. Fail fast on queue overflow (optional)

Once request queuing is visible, cap it so bursts of crawler traffic time out
instead of stalling humans:

```nginx
passenger_max_request_queue_size 100;
passenger_max_request_queue_time 10;
```

Requests beyond that receive a 503 from nginx without touching Rails. Pair
this with `rack-timeout` (`gem 'rack-timeout'`, `RACK_TIMEOUT_SERVICE_TIMEOUT=30`)
if long-running exports/sitemaps still hold processes.

### 5. Database connections

`ActiveRecord::ConnectionNotEstablished: Too many connections` bursts indicate
`pool: 20` × (Passenger processes + SolidQueue workers) exceeds MySQL's
`max_connections`. Either lower `pool` to match the Passenger thread count
(Passenger is single-threaded per process; `pool: 5` is ample) or raise
`max_connections` on the database server.
