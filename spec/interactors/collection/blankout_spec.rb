require 'spec_helper'

describe Collection::Blankout do
  before do
    Current.user = owner
  end

  let(:owner) { User.find_by(owner: true) }
  let!(:collection) do
    create(:collection, owner_user_id: owner.id, transcription_conventions: "Original convention \n", works: [])
  end
  let!(:work) { create(:work, collection_id: collection.id, owner_user_id: owner.id, transcription_version: 1) }
  let!(:page) { create(:page, work_id: work.id, source_text: 'Not blank', status: :transcribed, translation_status: :translated) }
  let!(:page_version) { create(:page_version, page_id: page.id, user_id: nil) }

  let!(:article) { create(:article, collection: collection) }
  let!(:deed_1) do
    create(:deed, deed_type: DeedType::PAGE_TRANSCRIPTION, page: page, work: work, collection: collection, user: owner)
  end
  let!(:deed_2) do
    create(:deed, deed_type: DeedType::ARTICLE_EDIT, article_id: article.id, page: page, work: work, collection: collection,
                  user: owner)
  end
  let!(:category) { create(:category, collection_id: collection.id) }
  let!(:note) { create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: owner.id) }
  let!(:page_article_link) { create(:page_article_link, page_id: page.id, article_id: article.id) }

  let(:result) do
    described_class.new(collection: collection.reload).call
  end

  it 'blanks out collection' do
    expect(result.success?).to be_truthy
    expect(Deed.where(id: [deed_1.id, deed_2.id]).any?).to be_falsey
    expect(Article.where(id: article.id).any?).to be_falsey
    expect(Category.where(id: category.id).any?).to be_falsey
    expect(Note.where(id: note.id).any?).to be_falsey
    expect(PageArticleLink.where(id: page_article_link.id).any?).to be_falsey
    expect(PageVersion.where(id: page_version.id).any?).to be_falsey
    expect(page.reload).to have_attributes(
      source_text: nil,
      status: 'new',
      translation_status: 'new'
    )
  end
end
