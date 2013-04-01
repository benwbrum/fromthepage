require 'spec_helper'

describe Deed do

  types = [ 'page_trans', 'page_edit', 'page_index', 'art_edit', 'note_add' ]

  before(:each) do
    @deed = FactoryGirl.create(:deed1)
  end

  # subject { @article }

  it { should belong_to(:article) } 
  it { should belong_to(:collection) }
  it { should belong_to(:note) }
  it { should belong_to(:page) }
  it { should belong_to(:user) } 
  it { should belong_to(:work) }

  it { should ensure_inclusion_of(:deed_type).in_array( types ) } 

  it 'tests short and long partials methods' do
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed.user = FactoryGirl.create(:user1)
    types.each do |type|
      deed.deed_type = type
      deed.short_partial.should == Deed::SHORT_PARTIALS[type]
      # is there a better way to test long_partials?
      if type == 'note_add'
        deed.long_partial.should == Deed::LONG_PARTIALS[type]
      else
        deed.long_partial.should == Deed::SHORT_PARTIALS[type]
      end
    end
  end

  

end
