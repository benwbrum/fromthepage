require 'spec_helper'

describe ExportController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:source_text) do
    File.read(Rails.root.join('test_data', 'transcripts', 'special_tags.txt'))
  end

  let(:xml_text) do
    File.read(Rails.root.join('test_data', 'transcripts', 'special_tags.xml'))
  end
  let!(:page) do
    create(:page, work: work, source_text: source_text, xml_text: xml_text, search_text: 'Search text',
      status: :transcribed)
  end

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

    context 'sort by title asc' do
      let(:params) { { search: work.title, sort: 'title' } }
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context 'sort by title desc' do
      let(:params) { { search: work.title, sort: 'title', order: 'desc' } }
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context 'sort by page count' do
      let(:params) { { search: work.title, sort: 'page_count', order: 'asc' } }
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context 'sort by indexed count' do
      let(:params) { { search: work.title, sort: 'indexed_count', order: 'desc' } }
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context 'sort by completed count' do
      let(:params) { { search: work.title, sort: 'completed_count' } }
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context 'sort by reviewed count' do
      let(:params) { { search: work.title, sort: 'reviewed_count' } }
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#show' do
    let(:action_path) { export_show_path(work_id: work.id) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
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

  describe '#tei' do
    let(:action_path) { export_tei_path(work.slug) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:tei)
    end
  end

  describe '#subject_details_csv' do
    let(:action_path) { export_subject_details_csv_path(collection_id: collection.id) }

    let(:subject) { get action_path }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#subject_coocurrence_csv' do
    let(:action_path) { export_subject_coocurrence_csv_path(collection_id: collection.id) }

    let(:subject) { get action_path }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#subject_distribution_csv' do
    let!(:article) { create(:article, collection_id: collection.id) }
    let(:action_path) { collection_subject_distribution_path(owner, collection, article) }

    let(:subject) { get action_path }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#subject_index_csv' do
    let(:action_path) { export_subject_csv_path(collection_id: collection.id) }

    let(:subject) { get action_path }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#work_metadata_csv' do
    let(:action_path) { export_work_metadata_path(collection) }
    let(:params) { {} }

    let(:subject) { get action_path, params: params }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
    end

    context 'as example' do
      let(:params) { { filename: 'example' } }

      it 'renders status' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '#table_csv' do
    let(:action_path) { export_table_csv_path(work_id: work.id) }

    let(:subject) { get action_path }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#export_all_tables' do
    let(:action_path) { export_export_all_tables_path(collection_id: collection.id) }

    let(:subject) { get action_path }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#page_plaintext_verbatim' do
    let(:action_path) { collection_page_export_plaintext_verbatim_path(owner, collection, work, page) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(page.verbatim_transcription_plaintext)
    end
  end

  describe '#page_plaintext_translation_verbatim' do
    let(:action_path) { collection_page_export_plaintext_translation_verbatim_path(owner, collection, work, page) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(page.verbatim_translation_plaintext)
    end
  end

  describe '#page_plaintext_emended' do
    let(:action_path) { collection_page_export_plaintext_emended_path(owner, collection, work, page) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(page.emended_transcription_plaintext)
    end
  end

  describe '#page_plaintext_translation_emended' do
    let(:action_path) { collection_page_export_plaintext_translation_emended_path(owner, collection, work, page) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(page.emended_translation_plaintext)
    end
  end

  describe '#page_plaintext_searchable' do
    let(:action_path) { collection_page_export_plaintext_searchable_path(owner, collection, work, page) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(page.search_text)
    end
  end

  describe '#work_plaintext_verbatim' do
    let(:action_path) { }

    let(:subject) { get action_path }

    context 'from export' do
      let(:action_path) { export_work_plaintext_verbatim_path(work_id: work.id) }

      it 'renders status and text' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('text/plain; charset=utf-8')
        expect(response.body).to eq(work.verbatim_transcription_plaintext)
      end
    end

    context 'from collection' do
      let(:action_path) { collection_work_export_plaintext_verbatim_path(owner, collection, work) }

      it 'renders status and text' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('text/plain; charset=utf-8')
        expect(response.body).to eq(work.verbatim_transcription_plaintext)
      end
    end
  end

  describe '#work_plaintext_translation_verbatim' do
    let(:action_path) { collection_work_export_plaintext_translation_verbatim_path(owner, collection, work) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(work.verbatim_translation_plaintext)
    end
  end

  describe '#work_plaintext_emended' do
    let(:action_path) { collection_work_export_plaintext_emended_path(owner, collection, work) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(work.emended_transcription_plaintext)
    end
  end

  describe '#work_plaintext_translation_emended' do
    let(:action_path) { collection_work_export_plaintext_translation_emended_path(owner, collection, work) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(work.emended_translation_plaintext)
    end
  end

  describe '#work_plaintext_searchable' do
    let(:action_path) { collection_work_export_plaintext_searchable_path(owner, collection, work) }

    let(:subject) { get action_path }

    it 'renders status and text' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('text/plain; charset=utf-8')
      expect(response.body).to eq(work.searchable_plaintext)
    end
  end

  describe '#edit_contentdm_credentials' do
    let(:action_path) { export_edit_contentdm_credentials_path(collection_id: collection.id) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_contentdm_credentials)
    end
  end
end
