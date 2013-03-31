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

end
