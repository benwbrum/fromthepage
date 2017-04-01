# IIIF Services, Renderings, See-Also Links, and Annnotation Lists in FromThePage

In addition to basic client support for transcribing IIIF-hosted content and server support for publishing FromThePage content as IIIF, the following value-added services allow for a more full-featured integration between the FromThePage platform, IIIF servers and IIIF clients:

## FromThePage IIIF Lookup API

## IIIF Presentation API Additions
FromThePage's IIIF server supports 

#### `dc:source` for Derivatives
Although the IIIF specifications support stand-alone documents like layers and sequences, as of 2017 manifests are the only document type that is commonly supported by IIIF clients.  When a IIIF client adds content to a manifest--as when a FromThePage user imports a document from a external content provider--it must produce a derivative manifest to publish its additional content for reuse by other IIIF clients.  

For IIIF content imported into FromThePage, the FromThePage IIIF server implemention exposes new, derivative manifests with an `@id` corresponsing to itself, replacing the `metadata` block with a single `dc:source` entry listing the originating IIIF manifest.

Derivative manifests are produced for Collections and Manifests.  Canvases are re-presented within the derivative using the originating `@id`, since these rarely are amended and it is important for annotation targets to point to the originating canvas for collation purposes.


### IIIF Collections



### IIIF Manifests

### IIIF Canvases

### AnnotationLists
