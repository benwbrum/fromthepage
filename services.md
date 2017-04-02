# IIIF Services, Renderings, See-Also Links, and Annnotation Lists in FromThePage
In addition to basic client support for transcribing IIIF-hosted content and server support for publishing FromThePage content as IIIF, the following value-added services allow for a more full-featured integration between the FromThePage platform, IIIF servers and IIIF clients.

_NB: FromThePage uses the following terms for internal data structures: a "page" corresponds to a IIIF "canvas", a "work" corresponds to a IIIF "manifest" and its default "sequence", a "collection" corresponds to IIIF a "collection"._

## FromThePage IIIF Lookup API
Since a transcription project on FromThePage may be initiated by a user, it is important for content providers to know which of their materials may be in use on a FromThePage system.  

A `GET` request to `/iiif/for/` followed with a manifest IRI will respond with a redirect to the corresponding FromThePage manifest for the IRI, if any exists on the server.  If no collection, manifest, or canvas has been imported into FromThePage with that IRI, a `404` response will be returned.

This lookup API differs in nature from the WebMention-based notification pattern being discussed in the IIIF community, as its purpose is to alert providers to incipient or ongoing projects so that they may be exposed to content providers' users in other contexts.  It makes no claim about completeness of a text, nor even the presence of annotations on a canvas. 

## IIIF Presentation API Usage
The IIIF presentation API exposed on a FromThePage server (browsable under the top-level URL `/iiif/collections` exposes these elements in addition to the minimal elements.

#### `dc:source` for Derivatives
Although the IIIF specifications support stand-alone documents like layers and sequences, as of April 2017 manifests are the only document type that is commonly supported by IIIF clients.  When a IIIF client adds content to a manifest--as when a FromThePage user imports a document from a external content provider--it must produce a derivative manifest to publish its additional content for reuse by third-party IIIF clients.  

For IIIF content imported into FromThePage, the FromThePage IIIF presenation server implemention exposes new derivative manifests -- each with an `@id` corresponsing to itself, replacing the originating `metadata` block with a single `dc:source` entry listing the originating IIIF manifest.

Derivative manifests are produced for Collections and Manifests.  Canvases are re-presented within the derivative using the originating `@id`, since these rarely are amended by content providers and it is important for annotation targets to point to the originating canvas for collation purposes.


### IIIF Collections
FromThePage collections are listed in the top-level collection manifest for FromThePage collections marked public.  This should correspond to the same collections displayed to an anonymous user at `/dashboard`

#### Collection-level Services

A link to the collection homepage will be listed under
```
TODO: example
```


A link to a CSV download of subjects tagged within texts across the collection will be listed under
```
TODO: example
```




### IIIF Manifests

#### Manifest-level Services
A link to the multi-page, "read work" screen will be listed under
```
TODO: example
```


#### Manifest-level Renderings
A link to an unstyled, single-page XHTML file containing full text of a work's transcript and translation, subects with any articles and index entries to pages they appear in, and page edit histories will be exposed as a `rendering` under the manifest's default sequence:
```
TODO: example
```

#### Manifest-level `within`
Each manifest presented by FromThePage will contain a `within` elmement containing the dereferencable ID of the collection the work is part of.
```
TODO: example
```


### IIIF Canvases

#### Canvas-level Services

A link to a screen displaying a single page's facsimile and transcript will be listed under
```
TODO: example
```

A link to a screen allowing the user to transcribe the page corresponding to this canvas will be listed under
```
TODO: example
```


If a FromThePage work supports translation, a link to a screen allowing the user to translate the page corresponding to this canvas will be listed under
```
TODO: example
```

#### Canvas-level Renderings
A link to an HTML document containing the formatted text for a page, including links to subject pages on the FromThePage server but excluding the facsimile view or navigation wrappers.
```
TODO: example
```

A link to an HTML document containing the formatted transcript for a page (as with transcript rendering, but only present if the work supports translation).
```
TODO: example
```
#### Canvas-level `within`
Each canvas presented by FromThePage will contain a `within` elmement containing the dereferencable ID of the manifest the canvas is part of.
```
TODO: example
```

### AnnotationLists
In addition to the existing `annotationList`s producing plaintext comments, transcripts, and translations, new annotations of content time `text/html` will be produced with contents identical to the canvas-level `rendering` described above.
