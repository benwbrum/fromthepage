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
        allow(page).to receive(:has_alto?).and_return(true)
        allow(page).to receive(:alto_xml).and_return('<alto>...</alto>')
        allow(task).to receive(:generate_plaintext).and_return('Generated plaintext')
        allow(ai_job).to receive_message_chain(:parameters, :[]).with(described_class.name, 'diff_level').and_return(:none)
      end

      it 'generates AI plaintext and saves it to the page' do
        expect(page).to receive(:ai_plaintext=).with('Generated plaintext')
        expect(page).to receive(:save)
        task.process_page
      end
    end

    context 'when the page does not have ALTO XML' do
      before do
        allow(page).to receive(:has_alto?).and_return(false)
      end

      it 'does not generate AI plaintext' do
        expect(task).not_to receive(:generate_plaintext)
        task.process_page
      end
    end
  end

  describe '#generate_plaintext' do
    let(:raw_alto) { '<alto>...</alto>' }
    let(:diff_level) { :none }

    it 'returns the plaintext generated from the ALTO XML' do
      expect(AltoTransformer).to receive(:plaintext_from_alto_xml).with(raw_alto).and_return('Generated plaintext')
      expect(task.generate_plaintext(raw_alto, diff_level)).to eq('Generated plaintext')
    end

    context 'when the plaintext is blank' do
      let(:raw_alto) { '<alto></alto>' }

      it 'returns nil' do
        expect(AltoTransformer).to receive(:plaintext_from_alto_xml).with(raw_alto).and_return('')
        expect(task.generate_plaintext(raw_alto, diff_level)).to be_nil
      end
    end

    context 'when the diff level is not none' do
      let(:diff_level) { :word }
      let(:plaintext) { 'Original plaintext' }
      let(:normalized_plaintext) { 'Normalized plaintext' }
      let(:new_plaintext) { 'New plaintext' }

      before do
        allow(AltoTransformer).to receive(:plaintext_from_alto_xml).and_return(plaintext)
        allow(TextNormalizer).to receive(:normalize_text).with(plaintext).and_return(normalized_plaintext)
        allow(DiffTools).to receive(:diff_and_replace).with(plaintext, normalized_plaintext, '🤔').and_return(new_plaintext)
      end

      it 'normalizes the plaintext and generates the diff' do
        expect(task.generate_plaintext(raw_alto, diff_level)).to eq(new_plaintext)
      end

      it 'replaces word-level diffs with 🤔' do
        expect(new_plaintext).to receive(:gsub!).with(/\b\w+🤔\w+\b/m, '🤔')
        task.generate_plaintext(raw_alto, diff_level)
      end
    end
  end
end