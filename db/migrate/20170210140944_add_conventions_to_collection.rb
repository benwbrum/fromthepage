class AddConventionsToCollection < ActiveRecord::Migration[5.2]
  def self.up
    add_column :collections, :transcription_conventions, :text

    Collection.reset_column_information

    Collection.all.each do |c|
      unless c.transcription_conventions.present?
        c.update_attribute :transcription_conventions, "<p><b>Transcription Conventions</b>\n<ul><li><i>Spelling: </i>Use original spelling if possible.</li>\n <li><i>Capitalization: </i>Modernize for readability</li>\n<li><i>Punctuation: </i>Add modern periods, but don't add punctuation like commas and apostrophes.</li>\n<li><i>Line Breaks: </i>Hit <code>return</code> once after each line ends.  Two returns indicate a new paragraph, which is usually indentation  following the preceding sentence in the original.  The times at the end of each entry should get their own paragraph, since the software does not support indentation in the transcriptions.</li>\n <li><i>Illegible text: </i>Indicate illegible readings in single square brackets: <code>[Dr?]</code></li></ul></p>"
      end
    end

  end

  def self.down
    remove_column :collections, :transcription_conventions
  end

end
