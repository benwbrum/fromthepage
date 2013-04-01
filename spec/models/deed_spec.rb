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

  it 'tests short partial method' do
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    # deed.deed_type = Deed::NOTE_ADDED
    deed.user = FactoryGirl.create(:user1)
    types.each do |type|
      deed.deed_type = type
      puts "Here is deed.short_partial: #{deed.short_partial}"
      puts "Here is deed.deed_type: #{deed.deed_type}"
      # puts "Here is deed::SHORT_PARTIALS[deed.deed_type]: #{Deed::SHORT_PARTIALS[deed.deed_type]}"
      puts "Here is deed::SHORT_PARTIALS[deed.deed_type]: #{Deed::SHORT_PARTIALS[type]}"
      # puts "Here is deed::SHORT_PARTIALS[deed.deed_type]: #{Deed::SHORT_PARTIALS}"
      deed.short_partial.should == Deed::SHORT_PARTIALS[type]
    end
    # @deed.short_partial.should == 'deed/' + @deed.deed_type + '_short.html.erb'
  end

end
