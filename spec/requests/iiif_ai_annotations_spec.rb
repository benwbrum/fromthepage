require 'spec_helper'

describe 'IIIF AI Annotations' do
  let(:owner) { User.find_by(owner: true) || create(:user, owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, :with_image, work: work) }
  let!(:ai_transcription) do
    create(:ai_transcription,
           page: page,
           source_text: 'AI generated text content',
           model: 'GPT-4o',
           reasoning: '## Reasoning\nThis is the AI reasoning.',
           prompt: 'Please transcribe this page')
  end

  before do
    Current.user = owner
  end

  describe 'Canvas with AI annotations' do
    context 'when page has no human-transcribed source text' do
      it 'includes AI text annotation in canvas' do
        get iiif_canvas_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Check that AI text annotation list is present
        ai_text_annotation = json['otherContent']&.find { |content| content['label'] == 'AI Text' }
        expect(ai_text_annotation).to be_present
        expect(ai_text_annotation['@id']).to include('/ai_text')
      end

      it 'includes AI reasoning annotation when reasoning is present' do
        get iiif_canvas_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Check that AI reasoning annotation list is present
        ai_reasoning_annotation = json['otherContent']&.find { |content| content['label'] == 'AI Reasoning' }
        expect(ai_reasoning_annotation).to be_present
        expect(ai_reasoning_annotation['@id']).to include('/ai_reasoning')
      end

      it 'does not include AI prompt annotation even when prompt is present' do
        get iiif_canvas_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Check that AI prompt annotation list is not present
        ai_prompt_annotation = json['otherContent']&.find { |content| content['label'] == 'AI Prompt' }
        expect(ai_prompt_annotation).not_to be_present
      end
    end

    context 'when page has source text' do
      before do
        page.update!(source_text: 'Human transcribed text')
      end

      it 'does not include AI text annotation in canvas' do
        get iiif_canvas_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # AI text annotation should NOT be present when there's human source text
        ai_text_annotation = json['otherContent']&.find { |content| content['label'] == 'AI Text' }
        expect(ai_text_annotation).to be_nil
      end

      it 'does not include AI reasoning annotation when source text is present' do
        get iiif_canvas_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # AI reasoning annotation should NOT be present when there's human source text
        ai_reasoning_annotation = json['otherContent']&.find { |content| content['label'] == 'AI Reasoning' }
        expect(ai_reasoning_annotation).to be_nil
      end
    end
  end

  describe 'ALTO XML rendering' do
    context 'when page has ALTO transcription' do
      let!(:alto_transcription) do
        create(:ai_transcription,
               page: page,
               source_text: 'ALTO generated text',
               model: AiTranscription::ALTO_MODEL)
      end

      it 'includes ALTO XML as a rendering element on the canvas' do
        get iiif_canvas_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Check that rendering array exists and contains ALTO XML
        expect(json['rendering']).to be_present
        alto_rendering = json['rendering'].find { |r| r['label'] == 'ALTO XML' }
        expect(alto_rendering).to be_present
        expect(alto_rendering['format']).to eq('application/xml')
        expect(alto_rendering['profile']).to eq('http://www.loc.gov/standards/alto/')
        expect(alto_rendering['@id']).to include('alto_xml')
      end
    end

    context 'when page does not have ALTO transcription' do
      it 'does not include ALTO XML rendering element' do
        get iiif_canvas_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Check that rendering array either doesn't exist or doesn't contain ALTO XML
        if json['rendering']
          alto_rendering = json['rendering'].find { |r| r['label'] == 'ALTO XML' }
          expect(alto_rendering).to be_nil
        end
      end
    end
  end

  describe 'AI transcription seeAlso elements' do
    it 'includes AI transcription plaintext in seeAlso' do
      get iiif_canvas_path(work.id, page.id)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Check that seeAlso contains AI transcription plaintext
      ai_plaintext_see_also = json['seeAlso']&.find do |item|
        item['label']&.include?('AI-generated Transcript Plaintext')
      end
      expect(ai_plaintext_see_also).to be_present
      expect(ai_plaintext_see_also['format']).to eq('text/plain')
      expect(ai_plaintext_see_also['label']).to include('GPT-4o')
      expect(ai_plaintext_see_also['@id']).to include('plaintext/ai/transcription')
    end

    it 'includes AI reasoning in seeAlso when reasoning is present' do
      get iiif_canvas_path(work.id, page.id)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Check that seeAlso contains AI reasoning
      ai_reasoning_see_also = json['seeAlso']&.find do |item|
        item['label']&.include?('AI Reasoning Explanation')
      end
      expect(ai_reasoning_see_also).to be_present
      expect(ai_reasoning_see_also['format']).to eq('text/html')
      expect(ai_reasoning_see_also['label']).to include('Reasoning')
      expect(ai_reasoning_see_also['@id']).to include('html/ai/reasoning')
    end

    it 'includes AI prompt in seeAlso when prompt is present' do
      get iiif_canvas_path(work.id, page.id)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Check that seeAlso contains AI reasoning
      ai_prompt_see_also = json['seeAlso']&.find do |item|
        item['label']&.include?('AI Prompt')
      end
      expect(ai_prompt_see_also).to be_present
      expect(ai_prompt_see_also['format']).to eq('text/plain')
      expect(ai_prompt_see_also['label']).to include('Prompt')
      expect(ai_prompt_see_also['@id']).to include('plaintext/ai/prompt')
    end

    context 'when AI transcription has no reasoning' do
      let!(:page_no_reasoning) { create(:page, :with_image, work: work) }
      let!(:ai_no_reasoning) do
        create(:ai_transcription,
               page: page_no_reasoning,
               source_text: 'AI text',
               model: 'GPT-4o',
               reasoning: nil)
      end

      it 'does not include AI reasoning in seeAlso' do
        get iiif_canvas_path(work.id, page_no_reasoning.id)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # AI reasoning should not be in seeAlso when reasoning is blank
        ai_reasoning_see_also = json['seeAlso']&.find do |item|
          item['label']&.include?('AI Reasoning Explanation')
        end
        expect(ai_reasoning_see_also).to be_nil
      end
    end
  end


  describe 'Annotation list for AI text' do
    it 'returns annotation list with AI text annotation' do
      get iiif_page_annotation_list_for_type_path(page.id, 'ai_text')

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['resources']).to be_present
      expect(json['resources'].first['resource']['chars']).to include('AI generated text content')
    end
  end

  describe 'AI transcription export endpoints' do
    describe 'GET /iiif/:work_id/export/:page_id/plaintext/ai/transcription' do
      it 'returns AI transcription as plaintext' do
        get iiif_page_export_plaintext_ai_transcription_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('text/plain; charset=utf-8')
        expect(response.body).to eq('AI generated text content')
      end

      context 'when page has no AI transcription' do
        let!(:page_without_ai) { create(:page, :with_image, work: work) }

        it 'returns 404' do
          get iiif_page_export_plaintext_ai_transcription_path(work.id, page_without_ai.id)

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include('No AI transcription available')
        end
      end
    end

    describe 'GET /iiif/:work_id/export/:page_id/html/ai/reasoning' do
      it 'returns AI reasoning as HTML' do
        get iiif_page_export_html_ai_reasoning_path(work.id, page.id)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('text/html; charset=utf-8')
        expect(response.body).to include('Reasoning')
        expect(response.body).to include('<h2')
      end

      context 'when page has no AI reasoning' do
        let!(:page_no_reasoning) { create(:page, :with_image, work: work) }
        let!(:ai_no_reasoning) do
          create(:ai_transcription,
                 page: page_no_reasoning,
                 source_text: 'AI text',
                 model: 'GPT-4o',
                 reasoning: nil)
        end

        it 'returns 404' do
          get iiif_page_export_html_ai_reasoning_path(work.id, page_no_reasoning.id)

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include('No AI reasoning available')
        end
      end
    end
  end
end
