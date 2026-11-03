# Manual checks for anonymous access and malformed URLs

Related issue: [#5996](https://github.com/benwbrum/fromthepage/issues/5996).

Use a local or staging instance with synthetic records. Select a public collection
with a work and page, an owner account, and an ordinary transcriber account.
Replace `OWNER`, `COLLECTION`, `WORK`, `PAGE_ID`, and `SUBJECT_ID` below with
their slugs/IDs. Use a private window for anonymous checks and inspect response
statuses in the browser network panel. Run export creation checks only on staging.

## Downloads and personal functionality

1. Open `/OWNER/COLLECTION/WORK` anonymously. Reading should still work, and
   there should be no Download tab or owner export controls.
2. Request `/OWNER/COLLECTION/WORK/download` directly. Expect a redirect to
   sign-in. The original production example was
   `/slqld/colonial-secretary-s-correspondence/work-33054-004688/download`.
3. Request `/export/WORK/tei` and
   `/export/work_plaintext_verbatim?work_id=WORK` anonymously. Expect sign-in
   redirects, without generated content. Request the Download tab's PDF and
   accessible-PDF endpoints directly; no PDF generation or bulk export should
   start for an anonymous visitor. A POST may instead be rejected first by CSRF
   validation; it must still produce no export or queued job.
4. Sign in as an ordinary transcriber. With the collection's user-download
   setting enabled, its Download tab and permitted downloads should work. Disable
   that setting as the owner: an ordinary transcriber's direct Download URL
   should now return 403. The owner should still be able to download.
5. As the owner, open the configurable-printout dialog from Download and confirm
   that its URL includes all three owner/collection/work components. The same
   direct dialog URL must return 403 for an ordinary transcriber, and a sign-in
   redirect anonymously. An ordinary transcriber must not be able to enqueue an
   owner-only work bulk export by POSTing its URL directly.
6. Repeat an allowed download using the application's supported guest-session
   flow. This is a real guest account/session, not an anonymous browser.
7. Request `/dashboard/watchlist`, `/dashboard/exports`, and
   `/dashboard/deeds?limit=10` anonymously: expect sign-in redirects. Repeat
   signed in and confirm the personal views still work. The explicitly public
   `/dashboard/deeds?all=true` feed remains public.

## IIIF integration boundary

Public IIIF manifests, annotations, and page-level representations keep their
existing API policy. Work-level generated exports are guarded separately.

1. With public API access disabled, request `/iiif/WORK_ID` anonymously: its
   public manifest should remain available. Request
   `/iiif/WORK_ID/export/plaintext/emended`: expect 401 anonymously, and 200 for
   an authorized signed-in user or owner API token. With user downloads disabled,
   an unrelated user's token should receive 403.
2. Explicitly enable public API access as the owner. The generated work export
   should now be available to server-to-server consumers without a browser
   session. This exception supports integrations such as Voyant; it does not
   make the Download tab visible anonymously. Disable the setting again to
   verify that the unauthenticated export URL returns 401.

## Missing, mismatched, and legacy contexts

The following must return actual 404 responses, without redirecting to another
collection or showing a global listing:

- `/missing-collection-5996/notes`.
- `/OWNER/missing-collection-5996/WORK`.
- `/WRONG_OWNER/COLLECTION/WORK`.
- A valid work URL using an unrelated collection or a document set that does not
  contain that work.
- `/OWNER/COLLECTION/OTHER_WORK/display/PAGE_ID` when the page belongs to WORK.
- `/OWNER/missing-collection-5996/works_list`.
- `/transcribe/guest` with no page/context. A correctly generated guest link
  must still work through the supported guest flow.

On an Elasticsearch-enabled staging instance, request
`/display/read_work?work_id=WORK_ID&page=1`. Expect a readable page and a work
search form with a fully populated owner/collection/work action URL.

For an owner account with a valid slug, its numeric profile URL should work.
Using a disposable owner record with its slug removed, the numeric profile URL
should return 404 instead of failing while building the search form.

## Subject lists and history

1. Open `/OWNER/COLLECTION/subjects` with a real collection. It should work.
2. Add `?selected_category_id=999999999`, then a category belonging to another
   collection. Both should return 404. A valid category and `uncategorized`
   should continue to work.
3. Open `/OWNER/COLLECTION/article_version/SUBJECT_ID` as HTML: valid history
   should render. Request the same URL with `Accept: application/json`: expect
   406, subject to access validation.
4. Full subject visibility, owner/context membership, and session validation are
   tracked separately by [#5988](https://github.com/benwbrum/fromthepage/issues/5988)
   and [PR #5991](https://github.com/benwbrum/fromthepage/pull/5991). Run that PR's
   access checks when both changes are integrated. This PR does not replace it.

## Search input and response formats

With Elasticsearch enabled and relevant pages indexed, open an owner or
collection search that produces results for `1` and try `term=1%29` and
`term=1%27%29`. The result list must render without a regular-expression error.
Also try literal brackets, backslashes, dots, and plus signs. Highlighting should
not interpret those characters as regex operators or turn encoded text into HTML.

For example, the originally observed search URLs included:

- `/benwbrum/search?term=1%29`
- `/benwbrum/search?term=1%27%29`
- `/tennessee-state-library-archives/tennessee-marriage-records-1975/search?term=1%29`

Request `/` with `Accept: application/json`: expect 406. HTML should still render
or redirect normally. The history endpoint's JSON check is described above.

## Forums, notes, and missing associations

- Request a forum under a missing collection or one with messageboards disabled:
  expect 404. Enable a forum on the synthetic collection. Its direct URL should
  require sign-in, matching the Forum tab's visibility; a signed-in reader should
  still be able to open it.
- Using a board slug or messageboard-group ID from a different collection under
  the enabled collection's forum prefix must return 404, even when signed in.
- Create a test note, then remove its author association. Open its page
  anonymously: expect a “Deleted user” label and placeholder picture, with no
  edit/delete controls offered to the anonymous visitor.
- Using a synthetic note, remove its page association while keeping its work.
  The collection's notes list should link the note to the work. Removing both
  page and work associations should leave a readable title without a broken link.
- Visit `/notes` anonymously with both public and private collection notes in the
  staging database. Private note titles must not appear. Signed-in owners and
  collaborators can still see their authorized notes.
- With a synthetic work whose collection association is absent, its access
  check must return no access rather than raising. Confirm a profile displaying
  its historical activity still renders without granting access to the work.

## Suspicious-behavior telemetry

Use the signed-in staging page's ordinary telemetry request, retaining its CSRF
token and cookies. Change its `collection_id` to a missing ID, and separately use
a page from a different collection. The endpoint should return 404 without a
Location header and create no SuspiciousBehavior record. A signed-in user who
cannot transcribe the requested collection should receive an authorization
denial. A normal authorized telemetry event should still succeed.

The original endpoint was a POST to
`/transcribe/suspicious_behaviors?collection_id=25000738&page_id=35896833`.
Use synthetic IDs and content for testing; the representative payload shape is:

```json
{"suspicious_behavior":{"behavior_type":"large_paste","metadata":{"content":"test"}}}
```

## Editor heartbeat and required review workflow

1. Sign in as a project owner. Under Settings → Quality Control, select the
   required-review workflow.
2. Open a new page in Transcribe, enter text, and click Done. Expect the normal
   Saved notice and navigation to the next page, without a connection warning.
3. Navigate back: the text should be present and the page should need review.
   Enter a translation and save it; its translation status should need review too.
4. Repeat transcription as an ordinary registered transcriber. In browser network
   tools, `still_editing` requests should return 200 and use the collection owner's
   URL prefix, even when the transcriber is a different user. Test a public
   document set with a private parent collection as well.
5. With synthetic records, request that heartbeat using an unrelated collection,
   another work, or the wrong owner prefix. Expect 404 with no change to the
   page's editing timestamp/user. After logout, the valid public-context heartbeat
   should return 401 rather than claiming a connection failure.

For the admin AI error detail view, use the error-detail URL with the ID of a
finished (non-error) AI transcription. Expect a direct HTTP 404 with no Location
header. Actual error records should still show their diagnostic details.
