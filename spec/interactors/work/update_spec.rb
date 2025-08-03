require 'spec_helper'

describe Work::Update do
  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, transcription_conventions: "Original convention \n") }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work, source_text: '[[link]]', source_translation: '[[link]]') }
  let!(:deed) { create(:deed, deed_type: DeedType::WORK_ADDED, work: work, collection: collection, user: owner) }
  let(:work_params) { {} }

  let(:result) do
    described_class.new(
      work: work,
      work_params: work_params
    ).call
  end

  context 'when missing collection_id' do
    it 'fails to update' do
      expect(result.success?).to be_falsey
      expect(result.work.errors).to include(:collection_id)
    end
  end

  context 'when invalid params' do
    let(:work_params) do
      {
        title: '',
        collection_id: collection.id,
        slug: work.slug,
        transcription_conventions: 'Original convention'
      }
    end

    it 'fails to update' do
      expect(result.success?).to be_falsey
      expect(result.work.errors).to include(:title)
    end
  end

  context 'success' do
    let(:work_params) do
      {
        title: 'New title',
        collection_id: collection.id,
        transcription_conventions: "Original convention \r\n"
      }
    end

    it 'updates work' do
      expect(result.success?).to be_truthy
      expect(result.work).to have_attributes(
        title: 'New title',
        collection_id: collection.id,
        transcription_conventions: nil
      )
      expect(deed.reload).to have_attributes(collection_id: collection.id)
      expect(page.reload).to have_attributes(
        source_text: '[[link]]',
        source_translation: '[[link]]'
      )
    end

    context 'when overriding transcription conventions' do
      let(:work_params) do
        {
          title: 'New title',
          collection_id: collection.id,
          slug: 'new-slug',
          transcription_conventions: "New convention \n"
        }
      end

      it 'updates work' do
        expect(result.success?).to be_truthy
        expect(result.work).to have_attributes(
          title: 'New title',
          collection_id: collection.id,
          slug: a_string_including('new-slug'),
          transcription_conventions: "New convention \n"
        )
        expect(deed.reload).to have_attributes(collection_id: collection.id)
        expect(page.reload).to have_attributes(
          source_text: '[[link]]',
          source_translation: '[[link]]'
        )
      end
    end

    context 'when submitting blank transcription conventions' do
      let(:work_params) do
        {
          title: 'New title',
          collection_id: collection.id,
          transcription_conventions: ''
        }
      end

      it 'inherits from collection (sets to nil)' do
        expect(result.success?).to be_truthy
        expect(result.work).to have_attributes(
          title: 'New title',
          collection_id: collection.id,
          transcription_conventions: nil
        )
      end
    end

    context 'when submitting whitespace-only transcription conventions' do
      let(:work_params) do
        {
          title: 'New title',
          collection_id: collection.id,
          transcription_conventions: "  \n\r  "
        }
      end

      it 'inherits from collection (sets to nil)' do
        expect(result.success?).to be_truthy
        expect(result.work).to have_attributes(
          title: 'New title',
          collection_id: collection.id,
          transcription_conventions: nil
        )
      end
    end

    context 'when work already has conventions but submitting collection conventions' do
      let!(:work_with_conventions) { create(:work, collection: collection, owner_user_id: owner.id, transcription_conventions: "Old work convention") }
      let(:work_params) do
        {
          title: 'Updated title',
          collection_id: collection.id,
          transcription_conventions: "Original convention \n"
        }
      end
      let(:result) do
        described_class.new(
          work: work_with_conventions,
          work_params: work_params
        ).call
      end

      it 'removes work-level conventions to inherit from collection' do
        expect(result.success?).to be_truthy
        expect(result.work).to have_attributes(
          title: 'Updated title',
          collection_id: collection.id,
          transcription_conventions: nil
        )
      end
    end

    context 'when collection is changed' do
      let!(:collection_2) { create(:collection, owner_user_id: owner.id) }
      let!(:article) { create(:article, collection: collection, pages: [page]) }

      let(:work_params) do
        {
          title: 'New title',
          collection_id: collection_2.id,
          slug: 'new-slug',
          transcription_conventions: "Original convention \r\n"
        }
      end

      it 'updates work, deeds and pages' do
        expect(result.success?).to be_truthy
        expect(result.work).to have_attributes(
          title: 'New title',
          collection_id: collection_2.id,
          slug: a_string_including('new-slug'),
          transcription_conventions: "Original convention \r\n"
        )
        expect(deed.reload).to have_attributes(collection_id: collection_2.id)
        expect(page.reload).to have_attributes(
          source_text: 'link',
          source_translation: 'link'
        )
      end
    end

    context 'when collection is changed and articles blank' do
      let!(:collection_2) { create(:collection, owner_user_id: owner.id) }

      let(:work_params) do
        {
          title: 'New title',
          collection_id: collection_2.id,
          slug: 'new-slug',
          transcription_conventions: "Original convention \r\n"
        }
      end

      it 'updates work, deeds and pages' do
        expect(result.success?).to be_truthy
        expect(result.work).to have_attributes(
          title: 'New title',
          collection_id: collection_2.id,
          slug: a_string_including('new-slug'),
          transcription_conventions: "Original convention \r\n"
        )
        expect(deed.reload).to have_attributes(collection_id: collection_2.id)
        expect(page.reload).to have_attributes(
          source_text: '[[link]]',
          source_translation: '[[link]]'
        )
      end
    end
  end
end
