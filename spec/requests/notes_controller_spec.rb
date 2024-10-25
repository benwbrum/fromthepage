require 'spec_helper'

describe NotesController do
  before do
    User.current_user = owner
  end

  let(:owner) { User.first }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:note) { create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: owner.id) }

  describe '#index' do
    let(:action_path) { notes_path(collection_id: collection.id) }
    let(:params) { {} }
    let(:headers) { {} }

    let(:subject) { get action_path, params: params, headers: headers }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'filters and paginate show all' do
      let(:params) { { search: note.title, per_page: -1 } }
      let(:headers) { { 'X-Requested-With': 'XMLHttpRequest' } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(partial: 'notes/_table')
      end
    end

    context 'sort by user' do
      let(:params) { { sort: 'user', order: 'ASC' } }
      let(:headers) { { 'X-Requested-With': 'XMLHttpRequest' } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(partial: 'notes/_table')
      end
    end

    context 'sort by note' do
      let(:params) { { sort: 'note', order: 'DESC' } }
      let(:headers) { { 'X-Requested-With': 'XMLHttpRequest' } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(partial: 'notes/_table')
      end
    end

    context 'sort by page' do
      let(:params) { { sort: 'page', order: 'ASC' } }
      let(:headers) { { 'X-Requested-With': 'XMLHttpRequest' } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(partial: 'notes/_table')
      end
    end

    context 'sort by work' do
      let(:params) { { sort: 'work', order: 'DESC' } }
      let(:headers) { { 'X-Requested-With': 'XMLHttpRequest' } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(partial: 'notes/_table')
      end
    end

    context 'without collection_id' do
      let(:action_path) { notes_path }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#create' do
    let(:action_path) { notes_path(collection_id: collection.id, work_id: work.id, page_id: page.id) }
    let(:params) { { note: { body: 'New note' } } }

    let(:subject) { post action_path, params: params }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
    end

    context 'success' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'error' do
      let(:params) { { note: { body: '' } } }
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#update' do
    let(:action_path) { note_path(note) }
    let(:params) { { note: { body: 'Edited note' } } }

    let(:subject) { put action_path, params: params }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
    end

    context 'success' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'error' do
      let(:params) { { note: { body: '' } } }
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#destroy' do
    let(:action_path) { note_path(note) }

    let(:subject) { delete action_path }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
    end

    context 'logged in' do
      it 'renders status' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#discussions' do
    let(:action_path) { collection_page_discussions_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:discussions)
    end
  end
end
