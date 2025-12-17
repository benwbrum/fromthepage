# Gemini AI Text Transcription

FromThePage supports automatic transcription of page images using Google's Gemini AI multi-modal model. This feature allows for automated extraction of text from handwritten or printed documents.

## Setup

### 1. Install the Gem

The `gemini-ai` gem is already included in the Gemfile. Run:

```bash
bundle install
```

### 2. Configure API Key

Set the `GEMINI_API_KEY` environment variable with your Google Gemini API key:

```bash
export GEMINI_API_KEY='your-api-key-here'
```

To obtain a Gemini API key:
1. Visit [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Create a new API key

### 3. (Optional) Configure Model

By default, the integration uses `gemini-1.5-flash`. You can override this by setting:

```bash
export GEMINI_MODEL='gemini-1.5-pro'
```

Available models include:
- `gemini-1.5-flash` (default, stable, fast, good for transcription)
- `gemini-1.5-pro` (stable, more accurate, slower)
- `gemini-pro-vision` (older model with vision capabilities)

## Usage

### Via Interactor

```ruby
# For a given page
page = Page.find(123)

# Fetch AI transcription
result = Page::FetchAiText.new(page: page).call

if result.success?
  puts "Transcription saved to page.ai_plaintext"
  puts page.ai_plaintext
else
  puts "Error: #{result.message}"
end
```

### Programmatic Usage

You can also use the transcriber directly:

```ruby
require 'gemini/text_transcriber'

image_url = 'https://example.com/path/to/page-image.jpg'
transcribed_text = Gemini::TextTranscriber.transcribe_image(image_url)
```

### With Custom Prompt

```ruby
custom_prompt = "Transcribe this document and pay special attention to dates and proper nouns."
text = Gemini::TextTranscriber.transcribe_image(image_url, prompt: custom_prompt)
```

## How It Works

1. The interactor retrieves the page image URL using `page.image_url_for_download`
2. The image is downloaded and encoded as base64 (automatically follows HTTP redirects)
3. The encoded image and prompt are sent to the Gemini API
4. The API returns transcribed text in a streaming response
5. The transcribed text is saved to the page using `page.ai_plaintext=`

### Redirect Handling

The image fetcher automatically follows HTTP redirects (301, 302, etc.) up to a maximum of 10 redirects. This ensures compatibility with image URLs that use CDNs or redirect services.

## Storage

Transcribed text is stored in the filesystem at:
```
public/text/{work_id}/{page_id}_ai_plaintext.txt
```

This follows the existing pattern for AI-generated text in FromThePage.

## Prompt Customization

The default prompt is stored in `lib/gemini/transcription_prompt.txt`. This prompt:
- Instructs the AI to preserve original formatting
- Handles both handwritten and printed text
- Requests accurate transcription without commentary
- Provides guidance for unclear or illegible text

You can modify this prompt to better suit your document collection's needs.

## Error Handling

The interactor handles several error cases:

- **No image**: Returns failure if the page has no associated image
- **Missing API key**: Raises `ArgumentError` if `GEMINI_API_KEY` is not set
- **Network errors**: Raises exception if image download fails
- **Too many redirects**: Raises exception if more than 10 redirects are encountered
- **API errors**: Logs error and raises exception if Gemini API call fails
- **503 Server Overload**: Automatically retries with exponential backoff (up to 5 attempts)
- **429 Rate Limit**: Automatically retries with exponential backoff (up to 5 attempts)

### Automatic Retry with Exponential Backoff

When the Gemini API returns a 503 error (server overload) or 429 error (rate limit), the system automatically retries the request with exponential backoff:

- **Attempt 1**: Immediate first request
- **Attempt 2**: Retry after 2 seconds
- **Attempt 3**: Retry after 4 seconds
- **Attempt 4**: Retry after 8 seconds
- **Attempt 5**: Retry after 16 seconds
- **Attempt 6**: Final retry after 32 seconds

After 5 retries (6 total attempts), if the error persists, the operation fails. This follows Google's recommended best practices for handling temporary service overload and rate limiting.

## Testing

Run the test suite:

```bash
bundle exec rspec spec/interactors/page/fetch_ai_text_spec.rb
```

The tests use mocked Gemini API responses to avoid requiring actual API credentials.

## Bulk Operations with Rake Tasks

For processing multiple pages at once, use the provided rake tasks:

### Transcribe all pages in a work

```bash
# By work slug (skips pages with existing AI plaintext)
rake fromthepage:gemini:transcribe_work[my-work-slug]

# By work ID
rake fromthepage:gemini:transcribe_work[123]

# Force re-transcribe (overwrites existing AI plaintext)
rake fromthepage:gemini:transcribe_work[my-work-slug,retranscribe]
```

This task:
- Processes all pages in the specified work
- By default, skips pages that already have AI plaintext
- Pass `retranscribe` as second parameter to overwrite existing AI plaintext
- Provides progress updates and statistics
- Includes a small delay between requests to avoid rate limiting

### Transcribe all pages in a collection

```bash
# By collection slug (skips pages with existing AI plaintext)
rake fromthepage:gemini:transcribe_collection[my-collection-slug]

# By collection ID
rake fromthepage:gemini:transcribe_collection[456]

# Force re-transcribe (overwrites existing AI plaintext)
rake fromthepage:gemini:transcribe_collection[my-collection-slug,retranscribe]
```

This task:
- Processes all pages in all works within the collection
- By default, skips pages that already have AI plaintext
- Pass `retranscribe` as second parameter to overwrite existing AI plaintext
- Shows progress for each work and overall statistics
- Includes a small delay between requests to avoid rate limiting

### Example Output

Normal mode (skips existing):
```
Starting Gemini AI transcription for work: Historical Letters Collection
Mode: NORMAL (skips existing)
Total pages: 25
================================================================================
[1/25] Page 101 (Letter 1, Page 1): SUCCESS
[2/25] Page 102 (Letter 1, Page 2): SKIPPED (already has AI plaintext)
[3/25] Page 103 (Letter 2, Page 1): SUCCESS
...
================================================================================
Transcription complete!
Success: 20, Skipped: 3, Errors: 2
```

Retranscribe mode (overwrites existing):
```
Starting Gemini AI transcription for work: Historical Letters Collection
Mode: RETRANSCRIBE (will overwrite existing)
Total pages: 25
================================================================================
[1/25] Page 101 (Letter 1, Page 1): SUCCESS
[2/25] Page 102 (Letter 1, Page 2): SUCCESS
[3/25] Page 103 (Letter 2, Page 1): SUCCESS
...
================================================================================
Transcription complete!
Success: 23, Errors: 2
```
Transcription complete!
Success: 20, Skipped: 3, Errors: 2
```

## Limitations

- Currently supports JPEG images only (as specified in the API call)
- Requires internet connectivity to access the Gemini API
- Subject to Gemini API rate limits and quotas
- Accuracy depends on image quality and legibility
- Rake tasks include a 0.5 second delay between requests to avoid rate limiting

## Future Enhancements

When Gemini 2.5 is released, simply update the `GEMINI_MODEL` environment variable or change the default in `lib/gemini/text_transcriber.rb`.

## Related Features

- **OpenAI Integration**: See `lib/openai/` for existing AI features
- **ALTO OCR**: See `Page#alto_xml` for alternative OCR format
- **Manual Transcription**: Users can still manually transcribe or edit AI-generated text
