require File.dirname(__FILE__) + '/../test_helper'

class CommentsEviltwinTest < Test::Unit::TestCase
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

  ######################
  # Save Tests
  ######################
  
  # base tags
  # test page comment
  def test_comment_at_all
    comment = Comment.new
    comment.title = 'foo'
    comment.body = 'bar baz quux'
    @page_one.comments << comment
    new_page = Page.find(@page_one.id)
    assert_equal('foo', new_page.comments[0].title)
  end

  # test page comment
  def test_comment_to_html
    comment = Comment.new
    comment.title = 'foo'
    comment.body = 'bar < baz quux'
    @page_one.comments << comment
    new_page = Page.find(@page_one.id)
    assert (new_page.comments[0].to_html.include? 'lt')
  end


  def test_whitelist_mod
    comment = Comment.new
    comment.title = 'foo'
    comment.body = 'bar <script src="foo"> baz'
    @page_one.comments << comment
    assert_no_match /script/, comment.to_html
  end
end
