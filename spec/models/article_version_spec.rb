require 'spec_helper'

describe ArticleVersion do

  before(:each) do
    @article_version = ArticleVersion.new
    # @article.title = "Hello"
    # @article.collection_id = FactoryGirl.create(:collection1).id
    # @article.save
    # @user = User.first
    # User.current_user = @user
  end

  # subject { @article }

  it { should belong_to(:article) }
  it { should belong_to(:user) }

end
