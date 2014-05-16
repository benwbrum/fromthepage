require 'spec_helper'

describe Category do

  before(:each) do
    @category = FactoryGirl.create(:category1)
    # @article.title = "Hello"
    # @article.collection_id = FactoryGirl.create(:collection1).id
    # @article.save
    # @user = User.first
    # User.current_user = @user
  end

  # subject { @category }

  # it { should respond_to(:title) }
  # it { should respond_to(:source_text) }

  it { should belong_to(:collection) }
  it { should have_and_belong_to_many(:articles).order(:title) }

end
