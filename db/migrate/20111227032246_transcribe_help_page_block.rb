class TranscribeHelpPageBlock < ActiveRecord::Migration
  def self.up
    make_block "static", "transcribe_help", "Transcribe Help Left Block", "left", STATIC_HELP_LEFT
    make_block "static", "transcribe_help", "Transcribe Help Right Block", "right", STATIC_HELP_RIGHT
  end

  def self.down
    pbs = PageBlock.find_all_by_view('transcribe_help')
    pbs.each {|pb| pb.delete }
  end


  def self.make_block(controller, view, description, tag="right", default=nil)
    pb = PageBlock.new
    pb.controller=controller
    pb.view=view
    pb.tag=tag
    pb.description=description
    pb.html=default
    pb.save!
  end


  STATIC_HELP_LEFT = <<STATICHELPLEFT
<h3>Transcribing</h3>
<p>Once you sign up for an account, a new <code>transcribe</code> tab will appear above each page.</p>

<p>You can create or edit transcriptions by modifying the
text entry field and saving.  Each modification is
stored as a separate version of the page, so that it should
be easy to revert to older versions if necessary.</p>

<p>Registered users can also add notes to pages to comment on
difficult words, suggest readings, or discuss the texts</p>

<h3>Linking Subjects</h3>
<p>To create a
link within a transcription, surround the text with double square braces.
 <br><br>Example: Say that we want to create a subject
 link for <i>Dr. Owen</i> in the text<br>

<code>Dr. Owen and his wife came by for fried chicken today.</code>
<br>
Place [[ and ]] around Dr Owen like this:<br>
<code>[[Dr. Owen]] and his wife came by for fried chicken today.</code><br>
<br>When you save the page, a new subject will be
created for <i>Dr. Owen</i>, and
the page will be added to its index. You can add an article about Dr.
Owen&mdash;perhaps biographical notes or references&mdash;to
the subject by clicking on &quot;Dr. Owen&quot; and clicking the &quot;Edit&quot; tab.
<br>

<br>To create a subject link with a different name from that used within the text, use double braces with a
pipe as follows: [[official name of subject|name used in the text]].
For example:<br>
<code>[[Dr. Owen]] and [[Dr. Owen&#39;s wife|his wife]] came by for fried chicken today. </code><br>

This will create a subject for <i>Dr. Owen&#39;s wife</i> and link the text
 &quot;his wife&quot; to that subject.
 </p>

 <h3>Renaming Subjects</h3>
 <p>In the example above, we don&#39;t know Dr.
Owen&#39;s wife&#39;s name, but created a subject for her anyway. If we
later discover that her name is &quot;Juanita&quot;, all we have to do is edit the subject title:
<ul><li>Click on &quot;his wife&quot; on the page, or navigate to <i>Dr. Owen&#39;s
 wife</i> on the home page for the project.</li>
 <li>Click the <code>edit</code> tab.</li>
<li>Change &quot;Dr. Owen&#39;s wife&quot; to &quot;Juanita Owen&quot;.</li>
</ul>This will
change the links on the pages that mention that subject, so our page is automatically updated:<br>
<code>[[Dr. Owen]] and [[Juanita Owen|his wife]] came by for fried chicken today.</code>
</p>

<h3>Combining Subjects</h3>
<p>Occasionally you may find that two subjects actually refer to the same person.=A0 When this
happens, rather than painstakingly updating each link, you can use the Combine button
at the bottom of the subject page.<br>
<br>For example, if one page reads:<br>
<code>[[Dr. Owen]] and [[Juanita Owen|his wife]] came by for [[fried chicken]] today.</code><br>
while a different page contains<br>
<code>Jim bought a [[chicken]] today.</code>
<br>you can combine <i>chicken</i> with <i>fried chicken</i> by going to the <i>chicken</i> article
and reviewing the combination suggestions at the bottom of the screen. Combining <i>fried chicken</i>
into <i>chicken</i> will update all links to point to <i>chicken</i> instead, copy any article text
from the <i>fried chicken</i> article onto the end of the <i>chicken</i> article, then delete the
 <i>fried chicken</i> subject.</p>

<h3>Auto-linking Subjects</h3>
<p>Whenever text is linked to a subject, that fact can be used by the system to suggest links
in new pages. At the bottom of the transcription screen, there is an &quot;Autolink&quot;
button. This will refresh the transcription text with suggested links, which should then be reviewed and may
be saved. </p>

<p>Using our example, the system already knows that &quot;Dr.
Owen&quot; links to <i>Dr. Owen</i> and &quot;his wife&quot; links to <i>Juanita Owen</i>. If a new page reads <br>
<code>We told Dr. Owen about Sam Jones and his wife.</code><br>
pressing Autolink will suggest these links:<br>
<code>We told [[Dr. Owen]] about Sam Jones and [[Juanita Owen|his wife]].</code><br>
<br>
In this case, the link around &quot;Dr. Owen&quot; is correct, but we must
edit the suggested link that incorrectly links Sam Jones&#39;s wife to <i>Juanita Owen</i>.
 The autolink feature can save a great deal of labor and
 prevent editors from forgetting to link a subject they previously thought
was important, but its suggestions still need to be reviewed before the transcription is saved.</p>

STATICHELPLEFT

  STATIC_HELP_RIGHT = <<STATICHELPRIGHT
STATICHELPRIGHT
end
