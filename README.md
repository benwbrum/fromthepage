[![Coverage Status](https://coveralls.io/repos/github/benwbrum/fromthepage/badge.svg)](https://coveralls.io/github/benwbrum/fromthepage)

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

### Single sign-on deployment

OmniAuth sign-in requests must use POST forms with Rails authenticity tokens; SAML provider callbacks must remain accessible to the identity provider. `omniauth-rails_csrf_protection` supplies the Rails-compatible request-phase validator.

Capistrano links `config/initializers/omniauth.rb` from the shared deployment directory. Before deploying, review that shared initializer and its provider configuration for OmniAuth 2 compatibility; do not enable GET request-phase authentication or disable CSRF validation. Configure `OmniAuth.config.full_host` or `OmniAuth.config.allowed_hosts` with trusted deployment hosts to prevent forged callback hosts. If Google sign-in is enabled, configure its provider and credentials in the deployment's shared initializer. Verify each configured SAML identity provider and its existing callback URL after deployment. SAML providers using cross-site POST callbacks may require a `SameSite=None; Secure` session cookie; verify this with the deployment's HTTPS and cookie configuration.

### Developer resources

- [Contributing guidelines](CONTRIBUTING.md)
- [Pull request guidelines](doc/pull_request_guidelines.md)
- [GitHub Copilot Agent setup](doc/copilot_agent_setup.md)
