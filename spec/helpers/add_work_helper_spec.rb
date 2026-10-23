require 'spec_helper'

RSpec.describe AddWorkHelper, type: :helper do
  describe '#document_upload_params' do
    it 'permits expected document upload attributes' do
      params = ActionController::Parameters.new(
        document_upload: {
          document_upload: 'upload', file: 'file', attachment: 'attachment', collection_id: '1',
          ocr: '1', preserve_titles: '0', generate_ai_draft: '1', unexpected: 'nope'
        }
      )
      allow(helper).to receive(:params).and_return(params)

      permitted = helper.send(:document_upload_params)

      expect(permitted.to_h).to include(
        'document_upload' => 'upload', 'file' => 'file', 'attachment' => 'attachment',
        'collection_id' => '1', 'ocr' => '1', 'preserve_titles' => '0', 'generate_ai_draft' => '1'
      )
      expect(permitted.to_h).not_to have_key('unexpected')
    end
  end

  describe '#work_params' do
    it 'permits expected work attributes' do
      params = ActionController::Parameters.new(
        work: { title: 'Title', description: 'Description', collection_id: '1', unexpected: 'nope' }
      )
      allow(helper).to receive(:params).and_return(params)

      permitted = helper.send(:work_params)

      expect(permitted.to_h).to eq('title' => 'Title', 'description' => 'Description', 'collection_id' => '1')
    end
  end
end
