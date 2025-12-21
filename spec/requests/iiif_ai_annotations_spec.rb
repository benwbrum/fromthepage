require 'spec_helper'

describe 'IIIF AI Annotations' do
  let(:owner) { User.find_by(owner: true) || create(:user, owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:ai_transcription) do
    create(:ai_transcription,
           page: page,
           source_text: 'AI generated text content',
           model: 'GPT-4o',
           reasoning: '## Reasoning\nThis is the AI reasoning.')
  end

  before do
    Current.user = owner
  end

  describe 'Canvas with AI annotations' do
    it 'includes AI text annotation in canvas' do
      get iiif_canvas_path(work.id, page.id)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Check that AI text annotation list is present
      ai_text_annotation = json['otherContent']&.find { |content| content['label'] == 'AI Text' }
      expect(ai_text_annotation).to be_present
      expect(ai_text_annotation['@id']).to include('annotation_type=ai_text')
    end

    it 'includes AI reasoning annotation when reasoning is present' do
      get iiif_canvas_path(work.id, page.id)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Check that AI reasoning annotation list is present
      ai_reasoning_annotation = json['otherContent']&.find { |content| content['label'] == 'AI Reasoning' }
      expect(ai_reasoning_annotation).to be_present
      expect(ai_reasoning_annotation['@id']).to include('annotation_type=ai_reasoning')
    end
  end

  describe 'AI text annotation' do
    it 'returns AI text annotation with correct format and content' do
      get iiif_annotation_path(page.id, 'ai_text')

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['resource']['format']).to eq('text/plain')
      expect(json['resource']['chars']).to eq('AI generated text content')
      expect(json['generator']['type']).to eq('Software')
      expect(json['generator']['name']).to eq('GPT-4o')
      expect(json['generated']).to be_present
    end
  end

  describe 'AI reasoning annotation' do
    it 'returns AI reasoning annotation with correct format and content' do
      get iiif_annotation_path(page.id, 'ai_reasoning')

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['motivation']).to eq('oa:commenting')
      expect(json['resource']['format']).to eq('text/html')
      expect(json['resource']['chars']).to include('<h2>Reasoning</h2>')
      expect(json['generator']['type']).to eq('Software')
      expect(json['generator']['name']).to eq('GPT-4o')
      expect(json['generated']).to be_present
    end
  end

  describe 'Annotation list for AI text' do
    it 'returns annotation list with AI text annotation' do
      get iiif_list_path(page.id, 'ai_text')

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['resources']).to be_present
      expect(json['resources'].first['resource']['chars']).to eq('AI generated text content')
    end
  end
end
