# New Relic instrumentation for end-user performance

This runbook collects the instrumentation changes needed to separate real-user
experience from crawler traffic and to see where time is spent *outside* Rails
(Cloudflare → nginx → Passenger queue). The code side ships with the app; the
server/UI steps below have to be done by an operator.

## What the app records

`ApplicationController` includes `NewRelicRequestAttributes`, which tags
controller transactions with the following attributes. Propagating attributes
to Browser events requires the configuration below; it is not automatic.

| Attribute | Values | Use |
| --- | --- | --- |
| `request_kind` | `human`, `bot`, `suspect` | Heuristic classification: `bot` = declared crawler (per the `browser` gem); `suspect` = the macOS user-agent fragment below with no session cookie; `human` = signed-in or otherwise unclassified |
| `logged_in` | `true`/`false` | Devise session present |
| `owner` | `true`/`false` | Signed-in user's global `owner` flag, not collection-level staff authorization |
| `has_session_cookie` | `true`/`false` | Whether the request carried `_fromthepage_session` |
| `collection_slug` | string | Collection in scope, when any |

The macOS fragment occurs in legitimate browsers too. A bot can send arbitrary
cookies, and a real person may reject cookies. Neither `human` nor `suspect`
proves identity. These labels support comparison, not access control. No cookie
values or user identifiers are recorded. An agent error is logged by class
without breaking the request.

Example queries:

```sql
-- heuristic non-crawler backend latency by action
SELECT percentile(duration, 50, 95), count(*) FROM Transaction
WHERE request_kind = 'human' SINCE 1 day ago FACET name

-- track the suspect cohort reaching Rails (not a definitive bot count)
SELECT rate(count(*), 1 minute) FROM Transaction
WHERE request_kind = 'suspect' SINCE 1 day ago TIMESERIES

-- browser-measured backend timing after enabling Browser attributes
SELECT average(backendDuration), average(webAppDuration), average(queueDuration)
FROM PageView WHERE logged_in = true SINCE 1 day ago
```

## Operator steps

### 1. Request-queue timing (`X-Request-Start`)

The sampled events had no queue timing. In the nginx location handing requests
to Passenger, have an operator set the start timestamp at the trusted ingress,
overwriting any incoming client header:

```nginx
passenger_set_header X-Request-Start "t=${msec}";
```

Have the operator validate with `nginx -t` and reload using the server's normal
procedure. Check New Relic APM for non-null `queueDuration` values. This measures
time from nginx to the app, not Cloudflare time or the client-to-edge network.
Zero may be correct when there is no queue. If there are multiple proxies,
review where the timestamp is created before interpreting it.

### 2. Distributed tracing

`config/newrelic.yml` is a Capistrano linked file (not in git). Merge these
settings into the existing production configuration; do not replace the file
or its account settings:

```yaml
common: &default_settings
  distributed_tracing:
    enabled: true
  browser_monitoring:
    auto_instrument: true
    attributes:
      enabled: true
      include:
        - request_kind
        - logged_in
        - owner
        - has_session_cookie
```

Check inherited overrides and existing attribute exclusions. These settings are
supported by the installed Ruby agent; Browser attribute capture defaults to
disabled. The Browser allowlist intentionally omits `collection_slug` and raw
request headers. Verify the effective configuration, then restart only this
application using the normal deployment procedure.

### 3. Upgrade the Browser agent

The sampled pages served the **Lite** loader (`nr-loader-rum`), and the queried
data lacked AJAX and JS error events. In New Relic -> Browser -> the production
application -> application/agent settings (labels vary by UI and plan):

- Agent type: **Pro + SPA**
- Enable **Session traces**, **AJAX**, **JS errors**, **Core Web Vitals**
- Keep the existing `ajax.deny_list` entry for `bam.nr-data.net`
- Leave session replay disabled unless separately approved after reviewing
  privacy, masking and retention.

For APM auto-instrumentation, check the selected agent type and reload the app
as needed. If a separate manual Browser snippet is used, update it using New
Relic's generated snippet instead; do not install a second copy.

After rollout, verify events rather than assuming a loader change succeeded:

```sql
SELECT keyset() FROM PageView SINCE 30 minutes ago
SELECT count(*) FROM AjaxRequest SINCE 30 minutes ago
SELECT count(*) FROM JavaScriptError SINCE 30 minutes ago
```

A zero JS error count can be legitimate. Visit a normal page while signed in,
exercise an existing AJAX interaction, and confirm the allowlisted attributes
on its Browser events. Compare browser `backendDuration` with APM `duration`
and `queueDuration` separately; the timings have different boundaries.

### 4. Queue limits

Measure request queuing first. Review any proposed queue caps against the
installed Passenger edition/version and normal burst traffic. Queue limits
can turn delays into errors; blanket request timeouts can interrupt
transcription saves and exports. Do not add them solely from these samples.

### 5. Database connections

The sampled `Too many connections` errors show connection exhaustion, not its
cause. Inventory all app processes, actual thread counts, background workers,
other clients and databases/pools. Compare their possible connections with
MySQL's `max_connections`, current/peak connections and memory headroom.
Pools are per process and per database and grow on demand: `pool: 20` is a
ceiling, not evidence that each process holds twenty connections.

Do not blindly lower the pool or raise the server limit. Size pools for actual
concurrency, check for leaks/long-held connections, and have an operator roll
out one measured change at a time with a rollback plan.
