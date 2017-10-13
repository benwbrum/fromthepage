class AddNewOwnerToBlock < ActiveRecord::Migration
  def change
    pb = PageBlock.new
    pb.controller="admin"
    pb.view="new_owner"
    pb.tag="top"
    pb.description="New Owner Welcome Email"
    pb.html="<p> Congratulations! You're now a project owner in FromThePage!</p>
      <p> Here are a couple of resources to get you started:</p>
      <p>  Details on <a href='https://fromthepage.com/static/faq#Uploads'>upload formats for material</a></p>
      <p>  Our <a href='https://www.getdrip.com/forms/42410437/submissions/new'>email course on starting a crowdsourcing project</a>.</p>
      <p>  Some thoughts on how to <a href='http://content.fromthepage.com/finding-transcribers-for-the-yaquina-lighthouse-project/'>find volunteers</a> and <a href='http://content.fromthepage.com/smithsonian_volunpeers/'>engage with them</a>.</p>
      <p>  If you run into any problems give us a shout at <a href='mailto:support@fromthepage.com'>support@fromthepage.com</a>. Happy transcribing!</p>"
    pb.save!
  end
end
