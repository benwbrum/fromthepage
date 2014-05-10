require File.dirname(__FILE__) + '/../test_helper'

class PageTest < Test::Unit::TestCase
  include AuthenticatedTestHelper
  fixtures :users
  fixtures :collections
  fixtures :works
  fixtures :pages
  fixtures :page_article_links

  def setup
    @page_one = Page.find(1)
    @page_two = Page.find(2)
  end
  

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_fixture
    assert_not_nil @page_one
    assert_not_nil @page_one
  end

  ######################
  # Save Tests
  ######################
  
  # base tags
  def test_no_tags_save
    assert_no_difference Article, :count do
      @page_one.source_text = "foo"
      @page_one.save!
    end
  end

  # create new article
  def test_basic_tags_save
    assert_difference Article, :count do
      @page_one.source_text = "foo [[bar]] baz"
      @page_one.save!
    end
  end

  # identify old article
  def test_existing_tag_save
    assert_difference Article, :count do
      @page_one.source_text = "foo [[bar]] baz"
      @page_one.save!
    end
    assert_no_difference Article, :count do
      @page_two.source_text = "foo [[bar]] baz"
      @page_two.save!
    end
  end

  def test_twice_in_same_page
    assert_equal(0, Article.where(title: 'bar').length)
    @page_one.source_text = "foo [[bar]] baz [[bar]] quux"
    @page_one.save!
    assert_equal(1, Article.where(title: 'bar').length)
  end

  # base tags with display text
  def test_basic_display
    assert_equal(0, Article.where(title: 'bar').length)
    @page_one.source_text = "foo [[bar|baz]] quux"
    @page_one.save!
    assert_equal(1, Article.where(title: 'bar').length)
  end
  
  def test_basic_display_twice_in_same_page
    assert_equal(0, Article.where(title: 'bar').length)
    @page_one.source_text = "foo [[bar|baz]] quux [[bar|quuux]] quuuuux"
    @page_one.save!
    assert_equal(1, Article.where(title: 'bar').length)
  end
  
  def test_basic_display_with_existing_article
    assert_difference Article, :count do
      @page_one.source_text = "foo [[bar|baz]] baz"
      @page_one.save!
    end
    assert_no_difference Article, :count do
      @page_two.source_text = "foo [[bar|quux]] baz"
      @page_two.save!
    end
  end


  # base tags with linebreak
  CANONICAL_TITLE = 'John Smith'
  
  TEXT_WITH_LB_TITLE =<<EOF
foo bar [[John
Smith]] baz quux
EOF

  TEXT_WITH_LB_TITLE_AND_NON_LB_TITLE =<<EOF
foo bar [[John
Smith]] baz [[John Smith]] quux
EOF

  TEXT_WITH_LB_TITLE_PLUS_WS =<<EOF
foo bar [[John  
  Smith]] baz quux
EOF

  TEXT_WITH_LB_DISPLAY =<<EOF
foo bar [[John Smith|John
Smith]] baz quux
EOF

  TEXT_WITH_LB_DISPLAY_PLUS_WS =<<EOF
foo bar [[John Smith|John  
  Smith]] baz quux
EOF

  TEXT_WITH_EXPLICIT_LB_TITLE =<<EOF
foo bar [[John
Smith|John Smith]] baz quux
EOF

  TEXT_WITH_EXPLICIT_LB_PLUS_WS_TITLE =<<EOF
foo bar [[John 
 Smith|John Smith]] baz quux
EOF

  def check_canonical_creation(page_text)
    assert_difference PageArticleLink, :count do
      assert_equal(0, Article.where(title: CANONICAL_TITLE).length)
      @page_one.source_text = page_text
      @page_one.save!
      assert_equal(1, Article.where(title: CANONICAL_TITLE).length)
    end
  end

  def check_display_name
    display_text = @page_one.page_article_links[0].display_text
    #p "test saw #{display_text}"
    assert_match( /John/, display_text, "No John in #{display_text}")
    assert_match( /Smith/, display_text, "No Smith in #{display_text}")
  end

  # does an article get created at all?
  def test_basic_lb_tag
    assert_difference Article, :count do
      @page_one.source_text = TEXT_WITH_LB_TITLE
      @page_one.save!
    end
  end
      
  # is the article retrievable if it doesn't have the linefeed?
  def test_retrievable_basic_lb_tag
    check_canonical_creation(TEXT_WITH_LB_TITLE)
    check_display_name
  end

  # TODO: Fix this in the code!      
  # is the article retrievable if it doesn't have the linefeed?
  def test_padded_lb_tag
    check_canonical_creation(TEXT_WITH_LB_TITLE_PLUS_WS)
    check_display_name
  end
 
  def test_lb_display
    check_canonical_creation(TEXT_WITH_LB_DISPLAY)
    check_display_name
  end
  
  def test_padded_lb_display
    check_canonical_creation(TEXT_WITH_LB_DISPLAY_PLUS_WS)
    check_display_name
  end
 
  def test_lb_title
    check_canonical_creation(TEXT_WITH_EXPLICIT_LB_TITLE)
    check_display_name
  end
  
  def test_padded_lb_title
    check_canonical_creation(TEXT_WITH_EXPLICIT_LB_PLUS_WS_TITLE)
    check_display_name
  end
      



  # do duplicates get created?
  def test_existing_tag_save
    assert_difference Article, :count do
      @page_one.source_text = TEXT_WITH_LB_TITLE
      @page_one.save!
    end
    assert_no_difference Article, :count do
      @page_one.source_text = TEXT_WITH_LB_TITLE_AND_NON_LB_TITLE
      @page_one.save!
    end
    assert_no_difference Article, :count do
      @page_two.source_text = TEXT_WITH_LB_TITLE_AND_NON_LB_TITLE
      @page_two.save!
    end
  end




  # invalid format tests
  
    
  ######################
  # Autolink Tests
  ######################

  # Basic autolink
  # No duplicate autolink
  # Ben Senior, Franklin
  
  ######################
  # Preview Tests
  ######################
  
end
