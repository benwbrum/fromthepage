# ChatGPT Text Transcriber

## Overview

The ChatGPT Text Transcriber uses OpenAI's GPT-4 Vision API to transcribe text from page images. This is particularly useful for historical documents and handwritten materials.

## Setup

### Environment Variables

Set your OpenAI API key:

```bash
export OPENAI_API_KEY='your-api-key-here'
```

You can obtain an API key from [OpenAI Platform](https://platform.openai.com/api-keys).

## Usage

### Using the Interactor Directly

```ruby
# Use ChatGPT to transcribe a page
result = Page::FetchAiText.new(
  page: page,
  provider: 'chatgpt',
  model: 'gpt-4o'  # Optional, defaults to 'gpt-4o'
).call

if result.success?
  puts page.ai_plaintext
else
  puts result.message
end
```

### Using the Library Directly

```ruby
require 'chatgpt/text_transcriber'

# Transcribe an image
text = Chatgpt::TextTranscriber.transcribe_image(
  'https://example.com/image.jpg',
  model: 'gpt-4o',         # Optional, defaults to 'gpt-4o'
  prompt: 'Custom prompt',  # Optional, uses default if not provided
  max_retries: 5           # Optional, defaults to 5
)
```

### Using Rake Tasks

Transcribe all pages in a work:

```bash
# Basic usage
rake fromthepage:chatgpt:transcribe_work[work-slug]

# Retranscribe existing pages
rake fromthepage:chatgpt:transcribe_work[work-slug,retranscribe]

# Use a specific model
rake fromthepage:chatgpt:transcribe_work[work-slug,retranscribe,gpt-4-turbo]
```

Transcribe all pages in a collection:

```bash
# Basic usage
rake fromthepage:chatgpt:transcribe_collection[collection-slug]

# Retranscribe existing pages
rake fromthepage:chatgpt:transcribe_collection[collection-slug,retranscribe]

# Use a specific model
rake fromthepage:chatgpt:transcribe_collection[collection-slug,retranscribe,gpt-4-turbo]
```

## Features

### Supported Models

- `gpt-4o` (default) - Latest GPT-4 model with vision capabilities
- `gpt-4-turbo` - Fast and capable GPT-4 Turbo
- `gpt-4` - Standard GPT-4 model

### Automatic Retry Logic

The transcriber implements exponential backoff retry logic for transient errors:

- **Retryable errors**: 429 (rate limit), 503 (service unavailable), 502 (bad gateway), 500 (internal server error), timeouts
- **Retry strategy**: Exponential backoff with delay = 2^attempt seconds
- **Max retries**: Configurable, defaults to 5

### Image Handling

- Automatically downloads and encodes images as base64
- Follows HTTP redirects (up to 10)
- Supports JPEG images

## Transcription Prompt

The default transcription prompt is designed for historical documents and includes instructions to:

- Preserve original formatting, line breaks, and layout
- Maintain paragraph structure and spacing
- Interpret handwritten text accurately
- Include all visible text (marginalia, headers, footers)
- Mark unclear text with [?] and illegible sections with [illegible]
- Provide transcribed text only, without commentary

You can customize the prompt by providing your own prompt text or editing `lib/chatgpt/transcription_prompt.txt`.

## Error Handling

The transcriber includes comprehensive error handling:

- Missing API key: Raises `ArgumentError`
- Image fetch failures: Raises descriptive error with HTTP status
- API errors: Logged via Rails logger and raised with details
- Non-retryable errors: Fail immediately without retry
- Retryable errors: Retry with exponential backoff up to max_retries

## Comparison with Gemini

The ChatGPT transcriber is designed to parallel the Gemini transcriber:

| Feature | Gemini | ChatGPT |
|---------|--------|---------|
| Provider | Google Gemini | OpenAI |
| Default Model | gemini-2.5-pro | gpt-4o |
| API Key | GEMINI_API_KEY | OPENAI_API_KEY |
| Vision Support | ✅ | ✅ |
| Retry Logic | ✅ | ✅ |
| Custom Prompts | ✅ | ✅ |
| Rake Tasks | ✅ | ✅ |

Both can be used interchangeably by specifying the `provider` parameter in the interactor.

## Cost Considerations

Using the OpenAI API incurs costs based on:
- Model used (gpt-4o is more cost-effective than gpt-4)
- Number of input tokens (prompt + image)
- Number of output tokens (transcribed text)

See [OpenAI Pricing](https://openai.com/pricing) for current rates.

## Troubleshooting

### API Key Not Set

```
ArgumentError: OPENAI_API_KEY environment variable is not set
```

**Solution**: Set the `OPENAI_API_KEY` environment variable with your OpenAI API key.

### Rate Limit Errors

```
the server responded with status 429
```

**Solution**: The transcriber automatically retries with exponential backoff. If you continue to see these errors, you may need to:
- Reduce the rate of requests
- Upgrade your OpenAI API tier
- Increase the delay between batch transcriptions

### Image Fetch Failures

```
Failed to fetch image from URL
```

**Solution**: Ensure the image URL is accessible and returns a valid image. Check for:
- Authentication requirements
- Network connectivity
- URL validity
