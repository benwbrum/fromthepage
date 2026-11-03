# Testing session-change recovery (#5995 / PR #5997)

Use a disposable page on a local or staging instance. Reload its editor after
updating the PR branch so the form contains the new recovery marker. Use two tabs
in the same browser profile and on the same site so they share session cookies.

Automatic restoration uses the shared Rails cache for up to 30 minutes. Production
uses Solid Cache. For development, enable caching with `bin/rails dev:cache` and
ensure that the cache database is configured/migrated; with a disabled or
unavailable cache, the styled copy-and-resume fallback remains available.

## Signed back into the same account

1. Sign in in tab A, open a page's Transcribe tab, and save a known baseline.
2. Open the site in tab B to establish that it shares the login.
3. In A, type a recognizable new draft and leave the editor open without saving.
4. In B, log out, then log back into **the same account**. Do not reload A.
5. Press Save in A.

Expected: A returns to the normal Transcribe editor with the unsaved text already
populated, the application header/layout, and a warning that the session changed
and the restored draft has **not** been saved. There should be no sign-in prompt.
The rejected POST redirects with 303 to a GET editor URL containing an opaque
recovery reference; draft content is not in the URL or session cookie.

Inspect saved page content, status, version history, and deeds: the recovery must
not have saved the new content. Press Save again from the restored editor: this
fresh request should work normally and remove the temporary cached draft.
The recovery warning should disappear and the normal Saved notice should appear;
the editor URL should no longer contain a recovery reference.

Repeat with field-based and spreadsheet transcription, and with translation.
Values should populate their real editor controls, without copying JSON manually.
AI-draft attribution should be retained when applicable.

## Still logged out

Repeat steps 1–3, but only log out in B; do not sign back in before saving in A.

Expected: A shows a recovery screen inside the application layout with styled
buttons and retained, copyable content. Sign-in opens in a new tab. After signing
back into the same account, return to A and choose **Resume editing**. The normal
editor should be populated and show the same unsaved-draft warning. The user must
still explicitly save it.

## Identity and access checks

- Log into a different account in B: do not automatically move the draft into
  that account. Keep the copyable fallback; do not show an unnecessary sign-in
  prompt to a currently signed-in user.
- Copy a recovery URL to another account or another page: it must not reveal the
  draft or populate that editor.
- Revoke editing permission between opening the form and submitting it: do not
  restore into an unauthorized editor or disclose private collection layout data.
- Repeat in a public document set whose parent collection is private. An authorized
  user should retain the document-set context and its normal access rules.
- Submit a missing/tampered/expired recovery marker: retain safe manual recovery;
  possession of a marker never authorizes a database save.
- Evict/expire a cached draft before following its editor link: show an explicit
  warning that only the saved version is available, rather than claiming recovery.
- Test a large text/field submission: no cookie overflow; source text, fields,
  recovery markers, and references must be filtered from ordinary request logs.

Forms already open before this update do not have the new signed marker. Their
content remains copyable on the styled fallback screen, but automatic restoration
requires a form loaded with the updated code.
