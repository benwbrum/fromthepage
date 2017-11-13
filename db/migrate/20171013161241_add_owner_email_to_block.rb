class AddOwnerEmailToBlock < ActiveRecord::Migration
  def up
    if (PageBlock.find_by(view: 'new_owner')).nil?
      pb = PageBlock.new
      pb.controller="admin"
      pb.view="new_owner"
      pb.tag="top"
      pb.description="New Owner Welcome Email"
      pb.html="<p> Congratulations! You're now a project owner in FromThePage!</p>\n<p> Here are a couple of resources to get you started:</p>\n<p>  Details on <a href='https://fromthepage.com/static/faq#Uploads'>upload formats for material</a></p>\n<p>  Our <a href='https://www.getdrip.com/forms/42410437/submissions/new'>email course on starting a crowdsourcing project</a>.</p>\n<p>  Some thoughts on how to <a href='http://content.fromthepage.com/finding-transcribers-for-the-yaquina-lighthouse-project/'>find volunteers</a> and <a href='http://content.fromthepage.com/smithsonian_volunpeers/'>engage with them</a>.</p>\n<p>  If you run into any problems give us a shout at <a href='mailto:#{ADMIN_EMAILS}'>#{ADMIN_EMAILS}</a>. Happy transcribing!</p>"
      pb.save!
    end
  end
  
  def down
  end
end
