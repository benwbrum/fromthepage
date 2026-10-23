# Elasticsearch Configuration 

## Layout

- /pipeline
  - Ingestion pipeline configuration
- /schema
  - Index template and individual schema config files for setting up a fresh deployment
- /scripts
  - Painless scripts in cleantext, used to power ingestion pipeline

## Current Schema

The schema is currently configured to utilize an `Index Template` to share analyzer settings between individual indices. Collection/Page/User/Work are split up into their own individual configurations.

### Analyzer Notes

Stemmers for different languages have been configured with the recommended algorithmic stemmer from Elastic.  Elastic recommends `porter_stem` for English however configuring the stemmer filter with the english language provides the same functionality.

Stopword filters have also been setup for each language.  Usage of the different language analyzers is still TBD.

### Current Language Support

- English
- French
- German
- Portuguese
- Spanish
- Swedish
