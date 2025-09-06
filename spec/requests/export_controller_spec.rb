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

    context 'with organization articles' do
      let!(:organizations_category) { create(:category, title: 'Organizations', collection: collection, org_fields_enabled: true) }
      let!(:organization_article) do
        create(:article,
               title: 'T. & R. Slevin & Cain',
               begun: '1854',
               ended: '1877',
               collection: collection,
               uri: 'O00007391')
      end

      before do
        organization_article.categories << organizations_category
        # Link the organization article to the work through the page
        page.page_article_links.create!(article: organization_article)
      end

      it 'includes organization data in TEI export' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:tei)

        # Check that the organization is included in the TEI output
        expect(response.body).to include('<listOrg>')
        expect(response.body).to include('<org xml:id="S' + organization_article.id.to_s + '">')
        expect(response.body).to include('<orgName>T. &amp; R. Slevin &amp; Cain</orgName>')
        expect(response.body).to include('<event type="begun"  when="1854">')
        expect(response.body).to include('<event type="ended"  when="1877">')
        expect(response.body).to include('<idno>O00007391</idno>')
      end
    end

    context 'with multiple organization categories' do
      let!(:companies_category) { create(:category, title: 'Companies', collection: collection, org_fields_enabled: true) }
      let!(:universities_category) { create(:category, title: 'Universities', collection: collection, org_fields_enabled: true) }
      let!(:company_article) do
        create(:article,
               title: 'ABC Manufacturing Co.',
               begun: '1890',
               ended: '1920',
               collection: collection,
               uri: 'O00001')
      end
      let!(:university_article) do
        create(:article,
               title: 'State University',
               begun: '1875',
               collection: collection,
               uri: 'O00002')
      end

      before do
        company_article.categories << companies_category
        university_article.categories << universities_category
        # Link the organization articles to the work through the page
        page.page_article_links.create!(article: company_article)
        page.page_article_links.create!(article: university_article)
      end

      it 'includes multiple organization types in TEI export' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:tei)

        # Check that both organizations are included in the TEI output
        expect(response.body).to include('<listOrg>')
        expect(response.body).to include('<org xml:id="S' + company_article.id.to_s + '">')
        expect(response.body).to include('<org xml:id="S' + university_article.id.to_s + '">')
        expect(response.body).to include('<orgName>ABC Manufacturing Co.</orgName>')
        expect(response.body).to include('<orgName>State University</orgName>')
        expect(response.body).to include('<event type="begun"  when="1890">')
        expect(response.body).to include('<event type="begun"  when="1875">')
        expect(response.body).to include('<event type="ended"  when="1920">')
        expect(response.body).to include('<idno>O00001</idno>')
        expect(response.body).to include('<idno>O00002</idno>')
      end
    end

    context 'with articles containing complex TEI bibliography data' do
      let!(:people_category) { create(:category, title: 'People', collection: collection) }
      
      let!(:person_article_complex) do
        create(:article,
               title: 'Test Person',
               collection: collection,
               bibliography: ' (1850), Population Schedules, Mississippi, Wilkinson County, p. 295A.<lb>
<hi rend="italic">Eighth Manuscript Census of the United States</hi> (1860), Population Schedules, Kentucky, Jefferson County, Louisville Ward 5, p. 119.<lb>
<hi rend="italic">Eighth Manuscript Census of the United States</hi> (1860), Slave Schedules, Kentucky, Jefferson County, Louisville, p. 272B.<lb>')
      end

      before do
        person_article_complex.categories << people_category
        # Link the article to the work through the page
        page.page_article_links.create!(article: person_article_complex)
      end

      it 'preserves complex TEI formatting with line breaks and italics in bibliography' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:tei)

        # Check that the complex TEI content is preserved
        expect(response.body).to include('<listPerson>')
        expect(response.body).to include('<person xml:id="S' + person_article_complex.id.to_s + '">')
        
        # Check for preserved line breaks
        expect(response.body).to match(/<lb\/>\s*\n/)
        
        # Check for preserved italic formatting (allowing for single or double quotes)
        expect(response.body).to match(/<hi rend=['"]italic['"]>Eighth Manuscript Census of the United States<\/hi>/)
        
        # Check that both elements appear multiple times as expected
        person_section = response.body[response.body.index('<person xml:id="S' + person_article_complex.id.to_s + '">')..response.body.index('</person>', response.body.index('<person xml:id="S' + person_article_complex.id.to_s + '">'))]
        hi_count = person_section.scan(/<hi rend=['"]italic['"]>/).count
        lb_count = person_section.scan(/<lb\/>/).count
        
        expect(hi_count).to eq(2)  # Two instances of hi rend="italic"
        expect(lb_count).to eq(3)  # Three line breaks
      end
    end

    context 'with articles containing bibliography data' do
      let!(:people_category) { create(:category, title: 'People', collection: collection) }
      let!(:places_category) { create(:category, title: 'Places', collection: collection) }
      let!(:organizations_category) { create(:category, title: 'Organizations', collection: collection, org_fields_enabled: true) }
      
      let!(:person_article) do
        create(:article,
               title: 'John Doe',
               collection: collection,
               bibliography: 'Sample person bibliography entry with <hi rend="italic">italic text</hi>.')
      end
      
      let!(:place_article) do
        create(:article,
               title: 'Louisville',
               collection: collection,
               bibliography: 'Sample place bibliography entry.')
      end
      
      let!(:organization_article) do
        create(:article,
               title: 'Test Company',
               collection: collection,
               bibliography: 'Sample organization bibliography entry.')
      end

      before do
        person_article.categories << people_category
        place_article.categories << places_category
        organization_article.categories << organizations_category
        # Link the articles to the work through the page
        page.page_article_links.create!(article: person_article)
        page.page_article_links.create!(article: place_article)
        page.page_article_links.create!(article: organization_article)
      end

      it 'includes bibl elements for all article types with bibliography data and preserves TEI formatting' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:tei)

        # Debug: Print the actual response body around the person bibliography
        person_section = response.body[response.body.index('<person xml:id="S' + person_article.id.to_s + '">')..response.body.index('</person>', response.body.index('<person xml:id="S' + person_article.id.to_s + '">'))]
        puts "\n=== DEBUG: Person section ==="
        puts person_section
        puts "=== END DEBUG ===\n"

        # Check that person bibliography is wrapped in bibl element
        expect(response.body).to include('<listPerson>')
        expect(response.body).to include('<person xml:id="S' + person_article.id.to_s + '">')
        expect(response.body).to include('<bibl>')
        expect(response.body).to include('Sample person bibliography entry')
        # Check that TEI formatting is preserved in bibliography (allowing for single or double quotes)
        expect(response.body).to match(/<hi rend=['"]italic['"]>italic text<\/hi>/)

        # Check that place bibliography is wrapped in bibl element
        expect(response.body).to include('<listPlace>')
        expect(response.body).to include('<place xml:id="S' + place_article.id.to_s + '">')
        expect(response.body).to include('Sample place bibliography entry')

        # Check that organization bibliography is wrapped in bibl element
        expect(response.body).to include('<listOrg>')
        expect(response.body).to include('<org xml:id="S' + organization_article.id.to_s + '">')
        expect(response.body).to include('Sample organization bibliography entry')

        # Ensure all bibliography entries are properly wrapped in bibl tags
        person_bibl_count = response.body.scan(/<bibl>.*Sample person bibliography entry.*<\/bibl>/m).count
        place_bibl_count = response.body.scan(/<bibl>.*Sample place bibliography entry.*<\/bibl>/m).count
        org_bibl_count = response.body.scan(/<bibl>.*Sample organization bibliography entry.*<\/bibl>/m).count
        
        expect(person_bibl_count).to eq(1)
        expect(place_bibl_count).to eq(1)
        expect(org_bibl_count).to eq(1)
      end
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
