require 'spec_helper'

describe "subject link accessibility" do
  let!(:owner)      { create(:owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work)       { create(:work, collection: collection) }
  let!(:work_page)  { create(:page, work: work, status: :transcribed) }
  let!(:article)    { create(:article, collection: collection, title: 'Test Subject') }

  before :each do
    # Set xml_text directly so the overview renders a subject link without
    # going through the transcription UI.  The tooltip anchor's aria-describedby
    # is always "tooltip-{article.id}" (see abstract_xml_helper.rb).
    # link_id is not consumed by the tooltip renderer (abstract_xml_helper.rb
    # only reads target_id to build the aria-describedby / href attributes).
    work_page.update_columns(
      xml_text: "<?xml version='1.0' encoding='UTF-8'?><page><p>" \
                "<link link_id='1' target_id='#{article.id}' " \
                "target_title='Test Subject'>Test Subject</link>" \
                " mentioned in this document.</p></page>"
    )
    create(:page_article_link, page: work_page, article: article, display_text: 'Test Subject')

    login_as(owner, scope: :user)
  end

  def visit_page_overview
    visit collection_read_work_path(work.collection.owner, work.collection, work)
    page.find('.work-page_title', text: work_page.title).click_link(work_page.title)
  end

  let(:tooltip_id) { "tooltip-#{article.id}" }

  it "displays existing subject links with proper accessibility attributes", js: true do
    visit_page_overview

    subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
    expect(subject_link['aria-describedby']).to eq(tooltip_id)
    expect(subject_link['tabindex']).to eq('0')
  end

  it "shows tooltip on focus for keyboard accessibility", js: true do
    visit_page_overview

    subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
    subject_link.click

    expect(page).to have_selector("##{tooltip_id}", visible: true, wait: 2)
  end

  it "allows dismissing tooltip with Escape key", js: true do
    visit_page_overview

    subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
    subject_link.click
    expect(page).to have_selector("##{tooltip_id}", visible: true, wait: 2)

    page.send_keys(:escape)

    expect(page).not_to have_selector("##{tooltip_id}", visible: true)
  end

  it "keeps tooltip visible when hovering over it", js: true do
    visit_page_overview

    subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
    subject_link.hover
    expect(page).to have_selector("##{tooltip_id}", visible: true)

    tooltip = page.find("##{tooltip_id}")
    tooltip.hover

    expect(page).to have_selector("##{tooltip_id}", visible: true)
  end
end
