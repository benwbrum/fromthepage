FromThePage is an open-source tool that allows volunteers to collaborate to transcribe handwritten documents.

### Features

- Wiki-style Editing: Users add or edit transcriptions using simple, wiki-style syntax on one side of the screen while viewing a scanned image of the manuscript page on the other side.
- Version Control: Changes to each page transcription are recorded and may be viewed to follow the edit history of a page.
- Wikilinks: Subjects mentioned within the document may are indexed via simple wikilinks within the transcription. Users can annotate subjects with full subject articles.
- Presentation: Readers can view transcriptions in a multi-page format or alongside page images. They can also read all the pages that mention a subject
- Automatic Markup: FromThePage can suggest wikilinks to editors by mining previously edited transcriptions. This helps insure editorial consistency and vastly reduces the amount of effort involved in markup.
- Internet Archive integration: FromThePage can be pointed at manuscripts hosted on Archive.org. It will import the page structure and any printed page titles into its native format for transcription, while serving page images from the Internet Archive.

### License

FromThePage is currently issued under the Affero GPL. This license remains controversial, however, so we are trying to preserve the option to dual-license the code.

### Platform

FromThePage has been run successfully under both Linux and Windows. It currently requires Ruby on Rails version 6.0.3.2 and the RMagick, hpricot, will_paginate, and OAI gems.

### Installation

Detailed Installation Instructions are available [in the wiki](https://github.com/benwbrum/fromthepage/wiki), including a link to a Docker file.

If you install FromThePage, please join the low volume [FromThePage Google Group](https://groups.google.com/forum/#!forum/fromthepage) so we can keep you informed of bug fixes and new releases.
