# FromThePage WayBack Machine Archive Support

This document describes the improvements made to help the WayBack Machine and other web crawlers better discover and archive transcript content on FromThePage.

## Problem

The WayBack Machine (Internet Archive's web crawler) was not archiving transcript pages because:

1. **Complex URL structure** - URLs like `/:user_slug/:collection_id/:work_id/display/:page_id` are hard to discover
2. **Basic robots.txt** - No guidance for crawlers about important content
3. **Missing metadata** - No structured data to help crawlers understand content

## Solution

### 1. Enhanced robots.txt

**Added to `/public/robots.txt`:**
```
# Allow crawling of transcripts and other content for archival purposes
Allow: /*/display/*
Allow: /*/*/*/display/*
```

### 2. SEO Meta Tags and Structured Data

**For transcript pages** (`display#display_page`):
- Descriptive page titles: "Page Title - Work Title - Collection Title"
- Meta descriptions with transcript context
- JSON-LD structured data following schema.org DigitalDocument format
- Archive-friendly HTTP headers (`X-Robots-Tag: index, follow, archive`)

**For work pages** (`work#show`):
- Book-level structured data with author, date, collection info
- Descriptive meta tags

**For collection pages** (`collection#show`):
- Collection-level structured data with item counts
- Descriptive meta tags

## Impact on WayBack Machine

With these changes, the WayBack Machine will:

1. **Understand content better** via structured data
2. **Archive more efficiently** with proper meta tags and HTTP headers

The structured data helps crawlers understand that pages contain historical document transcripts, which may improve archival priority and frequency.
