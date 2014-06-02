require "spec_helper"

# This spec describes the features and experience a reader should
# have using the site
#
# We should consider using fixtures rather than relying on the db dump


##################################
# First-importance pages
##################################



# The Dashboard page has links to collections and to activity.
# If a site-visitor sees it, their goal will be to read works, pages, and articles
# They should not see admin or owner actions they are not authorized to perform
describe "dashboard page" do
  # actions on the dashboard page which should be only visible to owner users
  OWNER_ACTIONS = [
    "Create an empty work",
    "Create an empty collection",
    "Import a book from the Internet Archive",
    "Create an image set",
    "Explore OAI repositories",
    "Import a work from an OAI collection"
  ]

  # actions on the dashboard page which should be only visible to admin users
  ADMIN_ACTIONS = [
    "Edit Help Text",
    "Edit Page Blocks",
    "View Logfile",
    "Recent Errors"
  ]


  it "should have a list of collections if not logged in" do
    binding.pry
#   capybara code to make sure we're logged out
#   visit dashboard_path
#   expect(page).to have_content("Julia Brumfield Diaries")  #consider replacing with a fixture
#   
  end

  it "should not have owner actions if not logged in" do
#    visit dashboard_path
#    OWNER_ACTIONS.each do |action|
#      expect(page).not_to have_content(action)
#    end
    
  end

  it "should not have admin actions if not logged in" do
#    visit dashboard_path
#    OWNER_ACTIONS.each do |action|
#      expect(page).not_to have_content(action)
#    end
    
  end


end


# The Collection page has links to works and to subjects mentioned in the 
# collection's works.
#.
# If a site-visitor sees it, their goal will be to read works, pages, and articles
# They should not see admin or owner actions they are not authorized to perform
describe "collection page" do
  it "should display works in the collection"
  it "should display subjects in the collection"
  it "should display activity"
  
end


# The Work page has paginated work content and links to pages within the works.
# It also has a table of contents as well as an about page and a history of edits
# to the transcripts
#.
# If a site-visitor sees it, their goal will be to read a specific work works, pages, and articles
# They should not see owner actions they are not authorized to perform
describe "read work page" do

  # don't forget pagination
end


# If a site visitor sees a page view page, they will be reading the transcript in detail,
# page-by-page.  They will also be comparing the transcript with the page image.
# there should be links to transcribe, links to view the page history, and links within
# the text to subjects (if any)
describe "single page page" do
  
  # don't forget pagination
end


describe "subject page"


##################################
# Second-tier pages
##################################

describe "collection stats page"

describe "collection subjects page"

# If a site visitor sees the contents page, they will be scanning for pages they
# want to read
describe "table of contents page"

# The Work versions page has a history of edits to a work, with links to view invidiual edits
#.
# If a site-visitor sees it, their goal will be to see the history of the edition
describe "work versions page"

describe "page versions page"

describe "subject graph screen"

describe "pages which mention this subject"

describe "search results"

describe "user profile page"

##################################
# Third-tier pages
##################################
describe "subject article history screen"

describe "pages which mention this subject but do not link to it"
