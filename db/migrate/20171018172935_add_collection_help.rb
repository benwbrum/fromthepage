class AddCollectionHelp < ActiveRecord::Migration
  def up
    add_column :collections, :help, :text
    add_column :collections, :link_help, :text

    Collection.reset_column_information

    Collection.all.each do |c|
      unless c.help.present?
        c.update_attribute :help, "<h2> Transcribing</h2>\n<p> Once you sign up for an account, a new Transcribe tab will appear above each page.</p>\n<p> You can create or edit transcriptions by modifying the text entry field and saving. Each modification is stored as a separate version of the page, so that it should be easy to revert to older versions if necessary.</p>\n<p> Registered users can also add notes to pages to comment on difficult words, suggest readings, or discuss the texts.</p>"
      end

      unless c.link_help.present?
        c.update_attribute :link_help, "<h2>Linking Subjects</h2>\n<p> To create a link within a transcription, surround the text with double square braces.</p>\n<p> Example: Say that we want to create a subject link for &ldquo;Dr. Owen&rdquo; in the text:</p>\n<code> Dr. Owen and his wife came by for fried chicken today.</code>\n<p> Place <code>[[ and ]]</code> around Dr Owen like this:</p>\n<code>[[Dr. Owen]] and his wife came by for fried chicken today.</code>\n<p> When you save the page, a new subject will be created for &ldquo;Dr. Owen&rdquo;, and the page will be added to its index. You can add an article about Dr. Owen&mdash;perhaps biographical notes or references&mdash;to the subject by clicking on &ldquo;Dr. Owen&rdquo; and clicking the Edit tab.</p>\n<p> To create a subject link with a different name from that used within the text, use double braces with a pipe as follows: <code>[[official name of subject|name used in the text]]</code>. For example:</p>\n<code> [[Dr. Owen]] and [[Dr. Owen's wife|his wife]] came by for fried chicken today.</code>\n<p> This will create a subject for &ldquo;Dr. Owen's wife&rdquo; and link the text &ldquo;his wife&rdquo; to that subject.</p></a>\n<h2> Renaming Subjects</h2>\n<p> In the example above, we don't know Dr. Owen's wife's name, but created a subject for her anyway. If we later discover that her name is &ldquo;Juanita&rdquo;, all we have to do is edit the subject title:</p>\n<ol><li>Click on &ldquo;his wife&rdquo; on the page, or navigate to &ldquo;Dr. Owen's wife&rdquo; on the home page for the project.</li>\n<li>Click the Edit tab.</li>\n<li> Change &ldquo;Dr. Owen's wife&rdquo; to &ldquo;Juanita Owen&rdquo;.</li></ol>\n<p> This will change the links on the pages that mention that subject, so our page is automatically updated:</p>\n    <code>[[Dr. Owen]] and [[Juanita Owen|his wife]] came by for fried chicken today.</code>\n<h2> Combining Subjects</h2>\n<p> Occasionally you may find that two subjects actually refer to the same person. When this happens, rather than painstakingly updating each link, you can use the Combine button at the bottom of the subject page.</p>\n <p> For example, if one page reads:</p>\n<code>[[Dr. Owen]] and [[Juanita Owen|his wife]] came by for [[fried chicken]] today.</code>\n<p> while a different page contains</p>\n<code> Jim bought a [[chicken]] today.</code>\n<p> you can combine &ldquo;chicken&rdquo; with &ldquo;fried chicken&rdquo; by going to the &ldquo;chicken&rdquo; article and reviewing the combination suggestions at the bottom of the screen. Combining &ldquo;fried chicken&rdquo; into &ldquo;chicken&rdquo; will update all links to point to &ldquo;chicken&rdquo; instead, copy any article text from the &ldquo;fried chicken&rdquo; article onto the end of the &ldquo;chicken&rdquo; article, then delete the &ldquo;fried chicken&rdquo; subject.</p>\n<h2> Auto-linking Subjects</h2>\n<p> Whenever text is linked to a subject, that fact can be used by the system to suggest links in new pages. At the bottom of the transcription screen, there is an Autolink button. This will refresh the transcription text with suggested links, which should then be reviewed and may be saved.</p>\n<p> Using our example, the system already knows that &ldquo;Dr. Owen&rdquo; links to &ldquo;Dr. Owen&rdquo; and &ldquo;his wife&rdquo; links to &ldquo;Juanita Owen&rdquo;. If a new page reads:</p>\n<code> We told Dr. Owen about Sam Jones and his wife.</code>\n<p> pressing Autolink will suggest these links:</p>\n<code> We told [[Dr. Owen]] about Sam Jones and [[Juanita Owen|his wife]].</code>\n<p> In this case, the link around &ldquo;Dr. Owen&rdquo; is correct, but we must edit the suggested link that incorrectly links Sam Jones's wife to &ldquo;Juanita Owen&rdquo;. The autolink feature can save a great deal of labor and prevent collaborators from forgetting to link a subject they previously thought was important, but its suggestions still need to be reviewed before the transcription is saved.</p>"
      end
    end

  end

  def down
    remove_column :collections, :help
    remove_column :collections, :link_help
  end

end
