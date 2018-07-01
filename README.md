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

FromThePage has been run successfully under both Linux and Windows. It currently requires Ruby on Rails version 4.1.1 and the RMagick, hpricot, will_paginate, and OAI gems.

### Installation

Install Ruby, RubyGems, Bundler, ImageMagick, MySQL and Git

Clone the repository

    git clone https://github.com/cientopolis/transcriptor-backend.git

Install required gems

    bundle install

Install Graphviz

    apt-get install graphviz (or see the graphviz documentation at http://www.graphviz.org/)

Create a database and user account for Transcriptor-Backend to use.

Then update the config/application.yml file to point to the MySQL user account and database you created above.

Run

    rake db:migrate
to load the schema definition into the database account.
    
    rake db:seed
  
to load init data.


Modify the configuration parameters in config/initializers/01fromthepage.rb for connect with metagame-api.

Modify the config/environments/production.rb (or development.rb) file to configure your mailer.  (Search for "action_mailer".)

If you wish to use latex formulas in your transcriptions, you'll need to install "pdflatex" and "pdfcrop".
You can usually install them by typing:
sudo apt-get install texlive-latex-base texlive-extra-utils


Finally, start the application

    rails server
    
    
## Testing

The API contains a folder inside spec/ which has unit tests.
To run all tests, move to the main folder of the project and execute:
```
$ rspec

