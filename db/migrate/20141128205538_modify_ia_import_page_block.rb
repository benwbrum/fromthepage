class ModifyIaImportPageBlock < ActiveRecord::Migration[5.2]
  def change
    pb = PageBlock.where(:controller => 'ia', :view => 'manage').first
    pb.html=STATIC_HELP_RIGHT
    pb.save!
  end


  STATIC_HELP_RIGHT = <<STATICHELPRIGHT
      <p>
      This page displays a book that has been imported from the Internet Archive
      but has not yet been converted to a FromThePage work.  
    </p>
    <p>
      For more information on this screen, see the Wiki article
      <a href="https://github.com/benwbrum/fromthepage/wiki/Importing-Works-from-the-Internet-Archive">
        Importing Works from the Internet Archive
      </a>.
    </p>
    <dl>
        <dt>
          Retitle from top of page OCR
        </dt>
        <dd>
          This replaces the page numbers with the top line of OCR text
        on each page.  This is useful for diaries and daybooks, since the first line
        is generally a date.  This process will take several seconds to run, since
        it requires parsing the entire OCR text for the book and updating each page
        number.  After the book has been converted to a FromThePage work, you will
        be able to correct any page titles. 
        
        </dd>
        <dt>
          Retitle from bottom of page OCR
        </dt>
        <dd>
          This replaces the page numbers with the bottom line of OCR text
        on each page.  This is useful for printed works in which page numbers
        appear at the bottom.   
        </dd>
        <dt>
          Convert to FromThePage
        </dt>
        <dd>
          Once you've got titles and leaves ready, this button will convert the book
        to a ready-to-transcribe FromThePage work.  This process will take several
        minutes to run.
        </dd>
        <dt>
          Use OCR for page contents?
        </dt>
        <dd>
          Select this check-box to populate each page's initial transcript with the
          contents of the corresponding OCR. 
        </dd>
      </dl>

STATICHELPRIGHT

end
