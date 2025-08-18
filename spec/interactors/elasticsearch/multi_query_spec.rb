require 'spec_helper'

describe Elasticsearch::MultiQuery do
  let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

  let!(:owner) { create(:unique_user, :owner) }
  let!(:other_user) { create(:unique_user, :owner) }

  # Collection that is restricted, but is owned by current_user
  let!(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      title: identifier,
      restricted: true,
    )
  end
  let!(:work_1) do
    create(
      :work,
      collection: collection,
      title: identifier
    )
  end
  let!(:page_1) do
    create(
      :page,
      :with_image,
      work: work_1,
      source_text: "#{identifier} + some other text"
    )
  end
  let!(:page_2) do
    create(
      :page,
      :with_image,
      work: work_1
    )
  end
  let!(:work_2) do
    create(
      :work,
      collection: collection
    )
  end
  let!(:page_3) do
    create(
      :page,
      :with_image,
      work: work_2,
      source_text: "#{identifier} + some other words"
    )
  end
  let!(:document_set) do
    create(:document_set, :public, :with_picture, collection_id: collection.id, owner_user_id: owner.id, works: [])
  end

  let!(:other_collection) do
    create(:collection, owner_user_id: other_user.id)
  end

  let(:result) do
    described_class.new(
      query: "#{identifier} some other words",
      query_params: {},
      user: owner
    ).call
  end

  before(:each) do
    stub_const('ELASTIC_ENABLED', true)

    [owner, other_user, collection, other_collection, document_set, work_1, work_2, page_1, page_2, page_3]
      .each(&:save!)
  end

  after(:each) do
    stub_const('ELASTIC_ENABLED', true)

    [page_1, page_2, page_3, work_1, work_2, document_set, other_collection, collection, other_user, owner]
      .each(&:destroy!)
  end

  context 'Guest user' do
    let(:result) do
      described_class.new(
        query: "#{identifier} some other-words",
        query_params: {},
        user: nil
      ).call
    end

    context 'Collection restricted' do
      it 'performs multiquery' do
        expect(result.success?).to be_truthy
        expect(result.results).to eq([])
      end

      it 'performs multiquery including docset' do
        document_set.update!(title: "docset #{identifier}")

        expect(result.success?).to be_truthy
        expect(result.results).to contain_exactly(
          document_set
        )
      end

      it 'performs multiquery including page_3 when work_2 added to public document set' do
        document_set.works << work_2
        document_set.reload.works.each(&:save!)
        document_set.reload.works.flat_map(&:pages).each(&:save!)

        expect(result.success?).to be_truthy

        expect(result.results).to contain_exactly(
          page_3
        )
      end
    end

    context 'Collection is public' do
      let!(:collection) do
        create(
          :collection,
          owner_user_id: owner.id,
          title: identifier,
          restricted: false
        )
      end

      it 'performs multiquery' do
        expect(result.success?).to be_truthy

        expect(result.results).to contain_exactly(
          collection,
          work_1,
          page_1,
          page_3
        )
      end

      it 'performs multiquery including newly transcribed page' do
        page_2.update!(source_text: "New transcription #{identifier}")

        expect(result.success?).to be_truthy
        expect(result.results).to contain_exactly(
          collection,
          work_1,
          page_1,
          page_2,
          page_3
        )
      end

      it 'performs multiquery excluding newly restricted collection' do
        collection.update!(restricted: true)
        collection.reload.works.each(&:save!)
        collection.reload.pages.each(&:save!)

        expect(result.success?).to be_truthy
        expect(result.results).to eq([])
      end
    end
  end

  context 'Owner user' do
    let(:result) do
      described_class.new(
        query: "#{identifier} some other words",
        query_params: {},
        user: owner
      ).call
    end

    context 'Collection restricted' do
      it 'performs multiquery' do
        expect(result.success?).to be_truthy
        expect(result.results).to contain_exactly(
          collection,
          work_1,
          page_1,
          page_3
        )
      end
    end
  end

  context 'Other user' do
    let(:result) do
      described_class.new(
        query: "#{identifier} some other-words",
        query_params: {},
        user: other_user
      ).call
    end

    context 'Collection is public' do
      let!(:collection) do
        create(
          :collection,
          owner_user_id: owner.id,
          title: identifier,
          restricted: false
        )
      end

      it 'performs multiquery' do
        expect(result.success?).to be_truthy
        expect(result.results).to contain_exactly(
          collection,
          work_1,
          page_1,
          page_3
        )
      end

      it 'performs multiquery and blocks blocked users' do
        collection.blocked_users << other_user
        collection.works.each(&:save!)
        collection.works.flat_map(&:pages).each(&:save!)

        expect(result.success?).to be_truthy
        expect(result.results).to eq([])
      end
    end
  end
end
