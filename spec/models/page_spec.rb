require 'spec_helper'

describe Page do
  before(:each) do
    @user = FactoryGirl.create(:user1)
    User.current_user = @user
    @work = FactoryGirl.create(:work1)
    @page = Page.new

    @page.title = "Wednesday, January 2, 1918"
    @page.source_text  = "From the Page is awesoooooome"
    @page.base_image = "/home/fromthe/fromthepage/current/public/images/working/6/img_3862.jpg"
    @page.base_width = 1944
    @page.base_height = 2592
    @page.shrink_factor = 2
    @page.position = 1
    @page.lock_version = 3
    @page.xml_text = "<?xml version='1.0' encoding='ISO-8859-15'?> \n <page>\n <p/>\n
\ </page>\n"
    @work.pages << @page
  end

  subject { @page }

  it { should respond_to(:title) }

  it { should belong_to(:work) }
  it { should have_many(:page_article_links) }
  it { should have_many(:articles).through(:page_article_links) }
  it { should have_many(:page_versions).order('page_version DESC') }
  it { should belong_to(:current_version).class_name('PageVersion') }
  it { should have_many(:notes).order(:created_at) }
  it { should have_one(:ia_leaf) }

  describe "create version tests" do

    it "should create version" do
      @page.source_text = "jdjdaohflasdfhpoagh"
      expect{ @page.save }.to change{ PageVersion.count }.by(1)
      @page.source_text = "kdkdkdkddk"
      expect{ @page.save }.to change{ PageVersion.count }.by(1)
    end
  end

  it "creates a new link" do
    article = FactoryGirl.create(:article1)
    d_text = "Chumba-Wumba"
    PageArticleLink.count.should == 0
    @page.create_link(article, d_text)
    PageArticleLink.count.should == 1
    pal = PageArticleLink.last
    pal.article_id.should == article.id
    pal.display_text.should == d_text

    # this does it all in one line, but I think the above gives more validation
    # expect{ @page.create_link(a_id, d_text).to change{ PageArticleLink.count }.by(1) }
  end

  it 'tests collection' do
    work1 = FactoryGirl.create(:work1)
    @page.collection.should == work1.collection
  end

end
