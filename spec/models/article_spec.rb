require 'spec_helper'

describe Article do

  before(:each) do
    @article = Article.new
    @article.title = "Hello"
    @article.collection_id = FactoryGirl.create(:collection).id
    @article.save
    @user = User.first
    User.current_user = @user
  end

  subject { @article }

  it { should respond_to(:title) }
  it { should respond_to(:source_text) }

  it "should create version" do
   
    @article.source_text = "Chumba My Wumba"
    
    expect{ @article.save }.to change{ ArticleVersion.count }.by(1)
  end

  it "should create links" do
    article2 = Article.new
    article2.title = "Hello 2"
    article2.collection_id = Collection.first.id
    article2.save
    expect{ @article.create_link(article2, "display_text") }.to change{ ArticleArticleLink.count }.by(1)
  end

  it "should delete links" do
    aa = 10
    aa.times { |i| 
      article_i = Article.new
      article_i.title = "x" * i
      article_i.collection_id = Collection.first.id
      article_i.save
      expect{ @article.create_link(article_i, "display text" + i.to_s) }.to change{ ArticleArticleLink.count }.by(1)
    }
    
    expect{ @article.clear_links }.to change{ ArticleArticleLink.count }.to(0)

  end

  it "tests possible_duplicates" do
    liv = FactoryGirl.create(:liv)
    lin = FactoryGirl.create(:lin)
    rva = FactoryGirl.create(:rva)
    cent_il = FactoryGirl.create(:cent_il)
    pd = liv.possible_duplicates
    pd.include?(cent_il).should be_false
    pd.size.should == 2
  end

end
