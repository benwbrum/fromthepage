# Spam Detection System

## Overview

FromThePage includes an automated spam detection system that flags potentially suspicious content in transcriptions, article versions, and notes. The system uses pattern matching against a configurable denylist to identify spam content.

## How It Works

The spam detection system (`Flagger` class) checks content against two lists:

1. **Denylist**: Patterns that trigger spam detection (e.g., `href`, `.com`, `.net`)
2. **Allowlist**: Trusted domain patterns that are excluded from spam detection

When content is checked:
1. The system first looks for patterns matching the denylist
2. If a match is found, it checks if the matched content contains any allowlist patterns
3. Content is only flagged as spam if it matches the denylist but NOT the allowlist

## Configuring the Allowlist

Administrators can configure the allowlist through the Admin Settings page at `/admin/settings`.

The allowlist should contain trusted domain patterns, one per line, such as:
- `merriam-webster.com` - Dictionary definitions
- `ancestry.com` - Genealogy research
- `findagrave.com` - Cemetery records
- `wikipedia.org` - Encyclopedia entries
- `books.google.com` - Book references
- `thefreedictionary.com` - Dictionary
- `newspapers.com` - Historical newspapers

## Use Cases

The allowlist is particularly useful for:
- Research websites commonly referenced in transcriptions
- Educational and reference sites
- Genealogy and historical research databases
- Government and institutional websites

## Technical Details

### Database Storage

Both the denylist and allowlist are stored in the `page_blocks` table with:
- `controller`: 'admin'
- `view`: 'flag_denylist' or 'flag_allowlist'
- `html`: Newline-separated list of patterns

### Code Location

- Main implementation: `lib/flagger.rb`
- Flag model: `app/models/flag.rb`
- Admin settings: `app/controllers/admin_controller.rb`
- Settings view: `app/views/admin/settings.html.slim`

### Testing

Tests are located in `spec/lib/flagger_spec.rb` and cover:
- Allowlist functionality
- Denylist functionality
- Edge cases (nil content, clean content, mixed content)

## Viewing Flagged Content

Administrators can view flagged content at `/admin/flag_list`. From there, they can:
- Review flagged content
- Mark content as OK (false positive)
- Revert spam content
- Mark all content from a user as OK

## Background Jobs

### Flag New Content

The spam detection can be run as a background job to check all existing content:

```bash
rake fromthepage:flag_abuse
```

This rake task checks all PageVersions, ArticleVersions, and Notes that haven't already been flagged.

### Re-check Existing Flags with Allowlist

After updating the allowlist, you can re-examine existing unconfirmed flags to automatically clear any that now match the allowlist criteria:

```bash
rake fromthepage:recheck_flags_with_allowlist
```

This rake task:
- Finds all unconfirmed flags created by the regex-based spam detection
- Re-checks the content against the current allowlist
- Automatically removes flags if the content is now allowed
- Provides a summary of how many flags were removed

This is particularly useful after:
- Adding new trusted domains to the allowlist
- Initially enabling the allowlist feature on an existing installation
- Adjusting allowlist patterns to reduce false positives
