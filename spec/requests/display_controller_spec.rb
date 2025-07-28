require 'spec_helper'

describe DisplayController do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, is_active: true) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }

  describe '#read_work' do
    let(:action_path) { "/#{owner.slug}/#{collection.slug}/#{work.slug}" }

    context 'when work has description' do
      before do
        work.update!(description: '<p>This is a test work description with HTML.</p>')
      end

      it 'sets social media meta tags for work' do
        expect_any_instance_of(ApplicationHelper).to receive(:set_social_media_meta_tags).with(
          title: work.title,
          description: kind_of(String),
          image_url: anything,
          url: anything,
          type: 'article'
        )

        get action_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when work has no description' do
      before do
        work.update!(description: nil)
      end

      it 'sets social media meta tags with default description' do
        expect_any_instance_of(ApplicationHelper).to receive(:set_social_media_meta_tags).with(
          title: work.title,
          description: /A document in the .* project on FromThePage/,
          image_url: anything,
          url: anything,
          type: 'article'
        )

        get action_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end