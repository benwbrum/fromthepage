require 'spec_helper'

describe Article do

  before(:each) do
    @article = Article.new
    @article.title = "Hello"
    @article.collection_id = FactoryGirl.create(:collection1).id
    @article.save
    @user = User.first
    User.current_user = @user
  end

  # subject { @article }

  it { should respond_to(:title) }
  it { should respond_to(:source_text) }

  it { should have_and_belong_to_many(:categories) }
  it { should belong_to(:collection) }
  it { should have_many(:target_article_links).order("articles.title ASC") }
  it { should have_many(:source_article_links) }
  it { should have_many(:page_article_links) }
  it { should have_many(:pages).through(:page_article_links) }
  it { should have_many(:article_versions).order(:version) }

  # one way to test validation
  it { should validate_presence_of(:title) }

  # validator
  it "should be invalid without a title" do
    FactoryGirl.build(:article1, title: nil).should_not be_valid
  end

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
