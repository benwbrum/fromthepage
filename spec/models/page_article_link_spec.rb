require 'spec_helper'

describe PageArticleLink do

  before(:each) do
    @page_article_link = FactoryGirl.create(:page_article_link1)
  end

  it { should belong_to(:article) }
  it { should belong_to(:page) }
end
