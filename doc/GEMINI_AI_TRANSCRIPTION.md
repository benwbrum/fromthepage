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

By default, the integration uses `gemini-2.0-flash-exp`. You can override this by setting:

```bash
export GEMINI_MODEL='gemini-1.5-pro'
```

Available models include:
- `gemini-2.0-flash-exp` (default, experimental, fast)
- `gemini-1.5-pro` (stable, more accurate)
- `gemini-1.5-flash` (stable, fast)

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
2. The image is downloaded and encoded as base64
3. The encoded image and prompt are sent to the Gemini API
4. The API returns transcribed text in a streaming response
5. The transcribed text is saved to the page using `page.ai_plaintext=`

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
- **API errors**: Logs error and raises exception if Gemini API call fails

## Testing

Run the test suite:

```bash
bundle exec rspec spec/interactors/page/fetch_ai_text_spec.rb
```

The tests use mocked Gemini API responses to avoid requiring actual API credentials.

## Limitations

- Currently supports JPEG images only (as specified in the API call)
- Requires internet connectivity to access the Gemini API
- Subject to Gemini API rate limits and quotas
- Accuracy depends on image quality and legibility

## Future Enhancements

When Gemini 2.5 is released, simply update the `GEMINI_MODEL` environment variable or change the default in `lib/gemini/text_transcriber.rb`.

## Related Features

- **OpenAI Integration**: See `lib/openai/` for existing AI features
- **ALTO OCR**: See `Page#alto_xml` for alternative OCR format
- **Manual Transcription**: Users can still manually transcribe or edit AI-generated text
