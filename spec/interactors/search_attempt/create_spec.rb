require 'spec_helper'

describe SearchAttempt::Create do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:xml_text) do
    "<?xml version='1.0' encoding='UTF-8'?><page><p>The quick <unclear> <link link_id='1428965' target_id='62422' target_title='fox'>fox</link> brown </unclear></p></page>"
  end
  let!(:page) { create(:page, work: work, xml_text: xml_text, search_text: "The quick fox brown\n\nfox\n\n") }
  let!(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id, works: [work]) }

  let(:search_attempt_params) { {} }

  let(:result) do
    described_class.new(
      search_attempt_params: search_attempt_params,
      user: owner
    ).call
  end

  context 'when search is empty' do
    it 'creates search attempt' do
      expect(result.success?).to be_falsey
    end
  end

  context 'search_type work' do
    let(:search_attempt_params) do
      {
        work_id: work.id,
        search: 'brown fox'
      }
    end

    it 'creates search attempt' do
      expect(result.success?).to be_truthy
      expect(result.search_attempt).to have_attributes(
        query: 'brown fox',
        slug: "brown-fox-#{result.search_attempt.id}",
        search_type: 'work',
        work_id: work.id
      )
      expect(result.search_attempt.query_results.pluck(:id)).to eq([page.id])
    end
  end

  context 'search_type collection' do
    let(:search_attempt_params) do
      {
        collection_id: collection.id,
        search: 'brown fox'
      }
    end

    it 'creates search attempt' do
      expect(result.success?).to be_truthy
      expect(result.search_attempt).to have_attributes(
        query: 'brown fox',
        slug: "brown-fox-#{result.search_attempt.id}",
        search_type: 'collection',
        collection_id: collection.id
      )
      expect(result.search_attempt.query_results.pluck(:id)).to eq([page.id])
    end
  end

  context 'search_type collection-title' do
    let(:search_attempt_params) do
      {
        collection_id: collection.id,
        search_by_title: work.title
      }
    end

    it 'creates search attempt' do
      expect(result.success?).to be_truthy
      expect(result.search_attempt).to have_attributes(
        query: work.title,
        slug: "#{work.title.parameterize}-#{result.search_attempt.id}",
        search_type: 'collection-title',
        collection_id: collection.id
      )
      expect(result.search_attempt.query_results.pluck(:id)).to eq([work.id])
    end
  end

  context 'search_type findaproject' do
    let(:search_attempt_params) do
      {
        search: collection.title
      }
    end

    let(:result) do
      described_class.new(search_attempt_params: search_attempt_params).call
    end

    it 'creates search attempt' do
      expect(result.success?).to be_truthy
      expect(result.search_attempt).to have_attributes(
        query: collection.title,
        slug: "#{collection.title.parameterize}-#{result.search_attempt.id}",
        search_type: 'findaproject',
        user_id: nil
      )
      expect(
        result.search_attempt.query_results.pluck(:id).include?(collection.id)
      ).to be_truthy
    end
  end

  context 'highlight terms' do
    let(:transcription_text) do
      "<p>The quick <span class=\"unclear\">[ <a title=\"fox\">fox</a> brown ]</span></p>"
    end
    let(:search_string) { 'brown fox' }

    let(:result) do
      SearchAttempt::Lib::Utils.highlight_terms(transcription_text.strip, search_string)
    end

    it 'adds highlights correctly on nested tags' do
      expect(result).to eq(
        "<p>The quick <span class=\"unclear\">[ <a title=\"fox\"><span class=\"highlighted\">fox</span></a> <span class=\"highlighted\">brown</span> ]</span></p>"
      )
    end
  end
end
