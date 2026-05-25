# Amazon Textract Integration

FromThePage can generate ALTO-XML overlays from page images using Amazon Textract.
This integration is intended as an experimental, rake-task-driven alternative to
Transkribus for generating HTR/OCR output that can be displayed in the AI Assist overlay
and converted to plaintext for AI Draft workflows.

## Overview

The integration:

1. Fetches a page image from `Page#image_url_for_download`
2. Sends the image bytes to Amazon Textract using the synchronous `DetectDocumentText` API
3. Converts the Textract response into ALTO-XML
4. Saves the ALTO-XML as an `AiTranscription` record with `model: 'Textract'`
5. Derives plaintext from the ALTO-XML using the existing `AltoTransformer` and stores it in `source_text`

Because this implementation uses the synchronous API, it does **not** require S3 or any polling task.

## Requirements

Add `aws-sdk-textract` to the Gemfile and run `bundle install`.

Set these environment variables:

```bash
export AWS_ACCESS_KEY_ID='your-access-key-id'
export AWS_SECRET_ACCESS_KEY='your-secret-access-key'
export AWS_REGION='us-east-1'
```

The AWS credentials must have permission to call:

- `textract:DetectDocumentText`

## Important constraint: image dimensions are required

Textract returns bounding boxes as fractional coordinates (0–1). To convert these into ALTO
pixel coordinates, FromThePage must already know the page width and height.

The processor uses this precedence:

1. `page.base_width` / `page.base_height`
2. `page.sc_canvas.width` / `page.sc_canvas.height`

If neither source is available, processing **fails with an error**. There is no dimension
inference fallback.

## Rake tasks

Process one page:

```bash
bundle exec rake fromthepage:textract:process_page[123]
```

Process all pages in a work:

```bash
bundle exec rake fromthepage:textract:process_work[456,all]
bundle exec rake fromthepage:textract:process_work[456,unprocessed]
```

Process all pages in a collection or document set (by numeric ID or slug):

```bash
bundle exec rake fromthepage:textract:process_collection[789,all]
bundle exec rake fromthepage:textract:process_collection[my-collection-slug,unprocessed]
```

The `unprocessed` filter skips any page that already has an ALTO transcription (i.e. `page.has_alto?` returns true).

## Storage model

Results are stored as `AiTranscription` records:

| Field        | Contents |
|--------------|----------|
| `model`      | `'Textract'` (`AiTranscription::TEXTRACT_ALTO_MODEL`) |
| `prompt`     | The generated ALTO-XML string |
| `source_text`| Plaintext derived from the ALTO-XML via `AltoTransformer` — available for AI Drafts |

Processing activity is tracked in `ExternalApiRequest` records with `engine: 'textract'`
(`ExternalApiRequest::Engine::TEXTRACT`).

The existing `AiTranscription.alto` scope covers both Transkribus and Textract ALTO records,
so all existing overlay, IIIF, and plaintext rendering infrastructure works automatically.

## Hierarchy preservation

Textract preserves a LINE → WORD hierarchy. The ALTO conversion maps this directly to:

- `TextLine` ← Textract `LINE` block
- `String CONTENT="..."` ← Textract `WORD` block (with bounding box and confidence score)

All lines are placed into a single `TextBlock` spanning the full page, since Textract does
not provide paragraph-level groupings. This is sufficient for:

- The AI Assist OSD overlay
- `AltoTransformer.plaintext_from_alto_xml` (used for AI Drafts)
- IIIF ALTO rendering links

## Model name convention

The model name `'Textract'` (a single engine) follows the same convention as `'Transkribus+OpenAI'`
(where the `+` indicates multiple engines). Single-engine integrations use a plain name.

## Limitations

- Experimental only — no UI trigger is provided
- Synchronous API only — no async job or S3 support in this implementation
- Fails if page image dimensions are not stored on the Page or ScCanvas record
