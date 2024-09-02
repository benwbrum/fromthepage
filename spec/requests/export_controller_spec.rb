require 'spec_helper'

describe ExportController do
  before do
    User.current_user = owner
  end

  let(:owner) { User.first }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:xml_text) { "<?xml version='1.0' encoding='UTF-8'?> <page> This <u>shouldn't</u> break export. </page>" }
  let!(:page) { create(:page, work: work, xml_text: xml_text, status: :transcribed) }

  describe '#index' do
    let(:action_path) { collection_export_path(owner, collection) }
    let(:params) { {} }

    let(:subject) { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'with search params' do
      let(:params) { { search: work.title, sort: 'title', order: 'desc', per_page: '-1' } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#list' do
    let(:action_path) { export_list_path }
    let(:params) do
      {
        collection_id: collection.id,
        search: work.title,
        sort: 'title',
        order: 'desc',
        per_page: '-1'
      }
    end

    let(:subject) { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(partial: '_list')
    end
  end

  describe '#printable' do
    let(:action_path) { export_printable_path(collection, work) }
    let(:params) { {} }

    let(:subject) { post action_path, params: params }

    context 'as pdf' do
      let(:params) { { edition: 'text', format: 'pdf' } }

      it 'renders status' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
      end
    end

    context 'as doc' do
      let(:params) { { edition: 'text', format: 'doc' } }

      it 'renders status' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
