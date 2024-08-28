require 'spec_helper'
require 'faker'

RSpec.describe OpenAi::AiTextPageProcessingTask, type: :model do
  let(:user) { create(:user, email: Faker::Internet.unique.email, login: Faker::Internet.unique.username) }
  let(:collection) { create(:collection, owner_user_id: user.id) }
  let(:work) { create(:work, collection: collection) }
  let(:page) { create(:page, work: work) }
  let(:ai_job) { create(:ai_job, user: user, collection: collection, work: work, page: page) }
  let(:page_processing_job) { create(:page_processing_job, page: page, ai_job: ai_job) }
  let(:task) { described_class.new(page_processing_job: page_processing_job) }

  describe '#process_page' do
    context 'when the page has ALTO XML' do
      before do
        allow(task).to receive(:generate_plaintext).and_return('Generated plaintext')
        ai_job.parameters = { described_class.name => { 'diff_level' => :none } }
        ai_job.save!
        page.alto_xml = '<alto>...</alto>'
        page.save!
      end

      it 'generates AI plaintext and saves it to the page' do
        task.process_page
        # test that the page has ai plaintext
        expect(page.has_ai_plaintext?).to be_truthy
        expect(page.ai_plaintext).to eq('Generated plaintext')
        expect(task.status).to eq('completed')
      end
    end

    context 'when the page does not have ALTO XML' do
      before do
        ai_job.parameters = { described_class.name => { 'diff_level' => :none } }
        ai_job.save!
        page.alto_xml = nil
        page.save!
      end

      it 'does not generate AI plaintext' do
        expect(task).not_to receive(:generate_plaintext)
        task.process_page
        expect(page.has_ai_plaintext?).to be_falsey
        expect(page.ai_plaintext).to be_blank
        expect(task.status).to eq('completed')
      end
    end

    context 'when the normalization service errors' do
      before do
        ai_job.parameters = { described_class.name => { 'diff_level' => :word } }
        ai_job.save!
        page.alto_xml=File.read(File.join(Rails.root, 'spec/fixtures/files/example_alto.xml'))
        page.save!
        allow(TextNormalizer).to receive(:normalize_text).and_raise(StandardError, 'error message')
      end

      it 'records an error as task status' do
        task.process_page
        expect(task.status).to eq('failed')
      end

      it 'records an error in the task details' do
        task.process_page
        expect(task.details['error']).to eq('error message')
      end
    end

  end

  describe '#generate_plaintext' do
    # define a minimal METS-ALTO xml file to test with
    let(:raw_alto) { File.read(File.join(Rails.root, 'spec/fixtures/files/example_alto.xml')) }
    let(:plaintext) { "Mr. John C. East\nPittsylvania.\nToutto\nVizina" }
    let(:diff_level) { :none }


    it 'returns the plaintext generated from the ALTO XML' do
      generated = task.generate_plaintext(raw_alto, diff_level)
      expect(generated).to eq(plaintext)
    end

    context 'when the diff level is not none' do
      let(:plaintext) { 'Original plaintext' }
      let(:normalized_plaintext) { 'Normalized plaintext' }
      let(:new_plaintext) { '🤔 plaintext' }

      before do
        allow(AltoTransformer).to receive(:plaintext_from_alto_xml).and_return(plaintext)
        allow(TextNormalizer).to receive(:normalize_text).with(plaintext).and_return(normalized_plaintext)
      end

      it 'generates word-level placeholders' do
        expect(task.generate_plaintext(raw_alto, :word)).to eq(new_plaintext)
      end

      it 'generates letter-level placeholders' do
        expect(task.generate_plaintext(raw_alto, :letter)).to eq(new_plaintext)
      end
    end
  end
end