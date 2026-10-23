# FromThePage WayBack Machine Archive Support

This document describes the improvements made to help the WayBack Machine and other web crawlers better discover and archive transcript content on FromThePage.

## Problem

The WayBack Machine (Internet Archive's web crawler) was not archiving transcript pages because:

1. **No sitemap.xml** - Crawlers couldn't discover deeply nested transcript URLs
2. **Complex URL structure** - URLs like `/:user_slug/:collection_id/:work_id/display/:page_id` are hard to discover
3. **Basic robots.txt** - No guidance for crawlers about important content
4. **Missing metadata** - No structured data to help crawlers understand content

## Solution

### 1. Dynamic Sitemap Generation

**Routes added:**
- `/sitemap.xml` - Main sitemap index
- `/sitemap_collections.xml` - All public collections  
- `/sitemap_works.xml` - All works in public collections
- `/sitemap_pages.xml` - All transcript pages (non-blank)

**Features:**
- Only includes public, active collections (respects `restricted` flag)
- Excludes blank pages from page sitemap
- Includes proper `lastmod`, `changefreq`, and `priority` values
- Handles large datasets with pagination support

### 2. Enhanced robots.txt

**Added to `/public/robots.txt`:**
```
# Allow crawling of transcripts and other content for archival purposes
Allow: /*/display/*
Allow: /*/*/*/display/*

# Sitemap location for better content discovery
Sitemap: https://fromthepage.com/sitemap.xml
```

### 3. SEO Meta Tags and Structured Data

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

### 4. Static Sitemap Generation (Rake Task)

For larger installations, use the rake task:

```bash
rake sitemap:generate
```

**Features:**
- Generates static XML files in `/public/sitemaps/`
- Handles pagination (50,000 URLs per file)
- Creates sitemap index file
- Copies main sitemap to `/public/sitemap.xml`

## Usage

### Dynamic Sitemaps (Default)

The dynamic sitemaps are automatically available once deployed:
- `https://fromthepage.com/sitemap.xml`
- `https://fromthepage.com/sitemap_collections.xml`
- `https://fromthepage.com/sitemap_works.xml`  
- `https://fromthepage.com/sitemap_pages.xml`

### Static Sitemaps (For Large Sites)

For sites with many thousands of items, generate static sitemaps:

```bash
# In production
RAILS_ENV=production rake sitemap:generate

# This creates:
# /public/sitemaps/sitemap_collections.xml
# /public/sitemaps/sitemap_works.xml  
# /public/sitemaps/sitemap_pages.xml
# /public/sitemap.xml (index)
```

Set up a cron job to regenerate periodically:
```bash
# Daily at 2 AM
0 2 * * * cd /path/to/fromthepage && RAILS_ENV=production rake sitemap:generate
```

## Testing

Test the sitemaps:

```bash
# Check sitemap accessibility
curl -I https://fromthepage.com/sitemap.xml

# Validate XML structure  
curl https://fromthepage.com/sitemap.xml | xmllint --format -

# Check specific sitemaps
curl https://fromthepage.com/sitemap_pages.xml | head -20
```

Run the test suite:
```bash
rspec spec/requests/sitemap_controller_spec.rb
```

## Impact on WayBack Machine

With these changes, the WayBack Machine will:

1. **Discover the sitemap** via robots.txt reference
2. **Follow sitemap links** to find all public transcript pages
3. **Understand content better** via structured data
4. **Archive more efficiently** with proper meta tags and HTTP headers

The structured data helps crawlers understand that pages contain historical document transcripts, which may improve archival priority and frequency.

## Performance Considerations

- Dynamic sitemaps limit to 10,000 collections, 1,000 works/pages per request
- Use static generation for sites with >10,000 items  
- Consider CDN caching for sitemap files
- Monitor server resources during large sitemap generation

## Privacy and Security

- Only public collections (`restricted: false, is_active: true`) are included
- No authentication is required to access sitemaps
- Blank pages are excluded from page sitemaps
- All URLs respect existing access controls