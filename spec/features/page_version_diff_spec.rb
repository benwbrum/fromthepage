require 'spec_helper'

# SEC-05: the page history prints the raw source escaped, and the diff widget reads it as text.
describe 'page version diff', js: true do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner_user_id: owner.id, supports_translation: true) }
  let(:page_record) { create(:page, work: work, title: 'Diff page') }
  # The diff widget replaces the containers before a broken image's onerror fires, so the <script>
  # (which runs while the page is parsed) is what proves the source is escaped.
  let(:payload) { '<script>window.__xss = true</script><img src=x onerror="window.__xss = true">' }

  let!(:older_version) do
    create(:page_version, page: page_record, user: owner, page_version: 1, title: 'Smith & Sons',
                          transcription: "#{payload}<lb/>Dear sir", source_translation: "#{payload}Hola")
  end
  let!(:newer_version) do
    create(:page_version, page: page_record, user: owner, page_version: 2, title: 'Smith & Sons Ltd',
                          transcription: "#{payload}<lb/>Dear sir, thanks", source_translation: "#{payload}Hola amigo")
  end

  before do
    login_as owner
    visit page_version_show_path(page_version_id: newer_version.id)
  end

  it "doesn't run markup from the source" do
    expect(page).to have_css('table.diff-versions')
    expect(page.evaluate_script('window.__xss')).to be_nil
    expect(page).to have_no_css('div.source-code img, div.source-code script', visible: :all)
  end

  it 'shows the source verbatim in the code view, with the change marked' do
    find('span.view-code').click

    original = find('[data-diff-transcription=original] div.source-code')
    expect(original.text).to include('<lb/>Dear sir')
    expect(original.text).not_to include('&lt;')
    expect(original).to have_css('ins', text: ', thanks')

    changed = find('[data-diff-transcription=changed] div.source-code')
    expect(changed.text).to include("#{payload}<lb/>Dear sir, thanks")

    translation = find('[data-diff-translation=original] div.source-code')
    expect(translation).to have_css('ins', text: 'amigo')
  end

  it 'diffs titles without double-escaping ampersands' do
    title = find('h4[data-diff-title=original]')

    expect(title.text).to include('Smith & Sons')
    expect(title.text).not_to include('&amp;')
    expect(title).to have_css('ins', text: 'Ltd')
  end
end
