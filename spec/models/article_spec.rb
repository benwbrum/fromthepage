require 'spec_helper'

describe Article do

  before(:each) do
    @article = Article.new
    @article.title = "Hello"
    @article.collection_id = FactoryGirl.create(:collection).id
    @article.save
    # puts "article.id: #{@article.id}"
    # puts "article.title: #{@article.title}"
    # puts "article.inspect: #{@article.inspect}"
  end

  subject { @article }

  it { should respond_to(:title) }
  it { should respond_to(:source_text) }

  it "should create version" do
    puts "article title: #{@article.title}"
    puts "@article.instance_variable_names: #{@article.instance_variable_names.sort}"
    puts "@article.instance_variable_get(@title_dirty): #{@article.instance_variable_get("@title_dirty")}"
    # puts "@article.title_dirty: #{@article.title_dirty}"
    puts "ArticleVersion.count: #{ArticleVersion.count}"
    @article.source_text = "Chumba My Wumba"
    puts "@article.id: #{@article.id}"
    # @article.save
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

=begin
  it "login must be unique" do
    user2 = User.new
    user2.login = @user.login
    user2.password = "1234567"
    user2.password_confirmation = "1234567"
    user2.should_not be_valid
    User.count.should == 1
  end

  it "confirms password" do
    user2 = User.new
    user2.login = "qwerrty"
    user2.password = "1234567"
    user2.password_confirmation = "1234568"
    user2.should_not be_valid
    User.count.should == 1
  end

  describe "when login is not present" do
    before { @user.login = " " }
    it { should_not be_valid }
  end

  # I don't know why this doesn't work.
  xit "when password is not present" do
    before { @user.password = nil }
    it { should_not be_valid }
  end

  describe "when password_confirmation is not present" do
    before { @user.password_confirmation = nil }
    it { should_not be_valid }
  end

  # It seems like this should work
  xit "checks the length of the username" do
    test_name = "e" * 200
    user3 = User.new
    user3.login = test_name
    user3.password = "123467"
    user3.password_confirmation = "1234657"
    user3.should_not be_valid
   
    puts "test_name: #{test_name}"
    puts "User count: #{User.count}"
  end

  describe "when login is too long" do
    before { @user.login = "a" * 41 }
    it { should_not be_valid }
  end

  describe "when login is too short" do
    before { @user.login = "a" * 2 }
    it { should_not be_valid }
  end

  describe "when password is too long" do
    before { @user.password = "a" * 41 }
    it { should_not be_valid }
  end

  describe "when password is too short" do
    before { @user.password = "a" * 3 }
    it { should_not be_valid }
  end

  it "gets the count" do
    puts "User count: #{User.count}"
  end
=end

end
