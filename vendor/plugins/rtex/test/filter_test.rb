require File.dirname(__FILE__) << '/test_helper'

context "Filtering Documents" do
  
  specify "can filter through textile" do
    doc = document('text.textile', :filter => 'textile')
    source = doc.source(binding)
    assert source.include?('\item')
  end
  
  specify "does not affect layouts" do
    doc = document('text.textile',
            :filter => 'textile',
            :layout => "* layout\n* is\n<%= yield %>")
    source = doc.source(binding)
    assert source.include?("* layout"), "filtered layout"
    assert source.include?('\item'), "didn't filter content"
  end

end