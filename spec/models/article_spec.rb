require 'spec_helper'

describe Article do

  before(:each) do
    # FactoryGirl does not seem to work here
    @article = Article.new
    @article.title = "Hello"
    @article.collection_id = FactoryGirl.create(:collection).id
    @article.save
    
  end

  subject { @article }

  it { should respond_to(:title) }
  it { should respond_to(:source_text) }

  it "should create version" do
    # puts "article title: #{@article.title}"
    # puts "@article.instance_variable_names: #{@article.instance_variable_names.sort}"
    # puts "@article.instance_variable_get(@title_dirty): #{@article.instance_variable_get("@title_dirty")}"
    
    puts "ArticleVersion.count: #{ArticleVersion.count}"
    @article.source_text = "Chumba My Wumba"
    puts "@article.id: #{@article.id}"
    
    expect{ @article.save }.to change{ ArticleVersion.count }.by(1)
    puts "ArticleVersion.count: #{ArticleVersion.count}"
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
    puts "ArticleArticleLink.count: #{ArticleArticleLink.count}"
    
    expect{ @article.clear_links }.to change{ ArticleArticleLink.count }.to(0)
    puts "after clear_links: ArticleArticleLink.count: #{ArticleArticleLink.count}"

    # ArticleArticleLink.count
  end

end
