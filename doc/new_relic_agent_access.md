# Safe New Relic access for Copilot cloud agent

This runbook supports read-only telemetry access from Copilot cloud/coding agent's
execution tools, not every github.com chat. It does not depend on a particular model.
See also the [repository instructions](../.github/copilot-instructions.md#new-relic-read-only-access).
This documentation does not create secrets or firewall permissions, change settings,
or run the smoke test.

## Operator setup

1. In New Relic, confirm the intended account's numeric ID and region with its
   administrator. Prefer a dedicated least-privilege identity limited to that account.
   A human must verify its roles permit the required telemetry reads and prohibit
   mutations/admin actions. A User API key inherits its owner's permissions:
   naming a key `read-only` does not restrict it. Do not test permissions by attempting
   a mutation.
2. In New Relic's **API keys** page, create a **User** API key for that identity.
   NerdGraph uses this key in the `API-Key` header, not an ingest/license or browser key.
   Transfer it directly to GitHub's secret form; never store credentials in Git,
   task text, issues/PRs, artifacts, logs, or `.env` files.
3. As a repository administrator, open `benwbrum/fromthepage` →
   **Settings → Secrets and variables → Agents**:
   - Add `NEW_RELIC_API_KEY` as an Agents **secret**.
   - Add `NEW_RELIC_ACCOUNT_ID` as an Agents **variable**, containing the numeric
     account ID. An existing Agents secret with this name also works.
   - Prefer explicitly setting the optional Agents variable `NEW_RELIC_REGION`
     to `US` or `EU`, after confirming the account's region.

   Agents secrets and variables automatically appear as environment variables to
   tools/scripts. Ordinary Actions secrets are not available to the agent.
   Values from the old `copilot` Actions environment were automatically migrated
   to Agents; manage them there now. No `COPILOT_` or `SECRET_` prefix is required
   for shell tools. `COPILOT_MCP_` is specific to MCP configuration, not this direct
   HTTP approach.
4. Choose exactly one endpoint based on the confirmed region:

   | `NEW_RELIC_REGION` | NerdGraph endpoint | Firewall host |
   | --- | --- | --- |
   | `US` | `https://api.newrelic.com/graphql` | `api.newrelic.com` |
   | `EU` | `https://api.eu.newrelic.com/graphql` | `api.eu.newrelic.com` |

   If the variable is absent, this runbook explicitly defaults to **US**; the
   operator must confirm that choice before testing and set `EU` if applicable.
   Never guess the region or try endpoints sequentially with the credential.
   For any other region, stop and ask the operator for its documented endpoint;
   do not send credentials to an unverified host.
5. Under **Settings → Copilot → Internet access**, add only the selected regional
   API host to the cloud agent's custom allowlist. Keep the firewall enabled;
   no browser/UI host or wildcard is needed.
6. Save settings, then start a **fresh cloud agent session**. Request the smoke
   test below only after configuration and role verification are complete.
   Revoke the dedicated key when access is no longer needed, and rotate it
   according to your security policy.

## Copy/paste access smoke-test prompt

Copy the entire block into a fresh cloud agent task. It authorizes only this
bounded access test, not a performance investigation or remediation.

```text
Test New Relic access only. Do not modify repository files, create commits or
PRs, deploy, make production application requests, generate load, or perform
any New Relic mutations. Do not run application tests or change settings.

Use NEW_RELIC_API_KEY and NEW_RELIC_ACCOUNT_ID from the environment. Check
presence without printing values; require the account ID to contain only ASCII
digits and be a valid NerdGraph Int. If missing or invalid, stop before network
access and tell the operator which Agents secret/variable to configure.
Never request pasted credentials.

Resolve NEW_RELIC_REGION using doc/new_relic_agent_access.md:
US -> https://api.newrelic.com/graphql
EU -> https://api.eu.newrelic.com/graphql
Absent -> the documented US default, only if the operator has confirmed US.
If region confirmation is missing, ask the operator before sending the key.
For any other region, stop and ask for an operator-confirmed documented endpoint.
Do not guess, probe both regions, or accept arbitrary endpoint overrides.

Use an existing HTTP client with TLS verification enabled, redirects disabled,
and a bounded total request timeout of 30 seconds. Send the API-Key header only
to the selected official endpoint; never forward credentials. Read the key
inside the client process from its environment, not by expanding it into a
shell command or command-line argument. Disable verbose/debug HTTP logging and
shell tracing. Keep requests/responses in memory, not files or artifacts.
If these safeguards cannot be met with available tools, stop safely.

Make at most 3 read-only API calls in total, with no retries or retry loop.
Normally use just these 2 NerdGraph queries:
1. Prove authentication and intended-account authorization by querying only
   actor { account(id: $accountId) { id } }. Do not request user names/emails.
   Pass the validated numeric account ID as an Int! GraphQL variable; compare
   the returned ID internally without printing it. Stop if not authorized.
2. Run this bounded aggregate, again passing the account ID as a variable:
   query AccessSmokeTest($accountId: Int!) {
     actor {
       account(id: $accountId) {
         nrql(query: "SELECT count(*) FROM Transaction SINCE 1 HOUR AGO") {
           results
         }
       }
     }
   }
Do not expand the time window, facet by app name, or request event details.

For each call inspect HTTP status AND GraphQL errors (even on HTTP 200).
Validate expected fields and reject null, missing, malformed, or partial data
as proof of full success. A valid zero count proves the API query worked but
there were no matching events; it is not an authentication failure.

Never print environment values, key fragments, headers, raw responses,
identities/emails, URLs containing tokens, SQL, or request parameters.
Do not echo request payloads or raw exception/error messages; they may contain
sensitive data. Never output the full GraphQL response. Do not rely on masking.

Return a sanitized PASS / FAIL / NOT TESTED checklist for:
- Configuration present and valid (presence/validity only, no values).
- DNS/TLS/network connectivity.
- Authentication.
- Intended-account authorization.
- Telemetry query executed (only aggregate count and "last 1 hour" if valid).
Mark unattempted or unproven checks NOT TESTED; don't infer success from HTTP
200 alone. For failure, provide a sanitized evidence-based category and exact
operator next step: unset/invalid Agents configuration; observed DNS/TLS/firewall
block; authentication/permission denial; confirmed region mismatch; rate limit;
or upstream failure. A generic error does not conclusively prove bad credentials,
a blocked firewall, or a wrong region. For ambiguous evidence, state uncertainty
and ask the operator to verify the relevant setting instead of trying another
endpoint, disabling security controls, or retrying.

Examples of operator fixes: save the named Agents secret/variable and start a
fresh session; allow only the confirmed regional API host; verify the User key
and intended-account roles in New Relic; confirm region and correct the region
variable/allowlist before a new test; or wait for a rate limit/upstream incident
to clear before requesting a new test. Never ask for credentials in chat.
Report least-privilege/read-only roles separately as "operator verification
required"; successful reads do not prove that mutations are forbidden. Do not
attempt any mutation to check this. Stop safely when access is unavailable.
```

## Official references

- [GitHub: Configure secrets and variables for Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/configure-secrets-and-variables)
- [GitHub: Customize the cloud agent firewall](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-the-firewall)
- [New Relic: Introduction to NerdGraph (authentication and regional endpoints)](https://docs.newrelic.com/docs/apis/nerdgraph/get-started/introduction-new-relic-nerdgraph/)
- [New Relic: API keys (User key permissions)](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/)
- [New Relic: NerdGraph NRQL tutorial](https://docs.newrelic.com/docs/apis/nerdgraph/examples/nerdgraph-nrql-tutorial/)
