require 'spec_helper'

describe ArticleArticleLink do

  before(:each) do
    @article_article_link = FactoryGirl.create(:article_article_link1)
  end

  it { should belong_to(:source_article).class_name(:Article) }
  it { should belong_to(:target_article).class_name(:Article) }
end
