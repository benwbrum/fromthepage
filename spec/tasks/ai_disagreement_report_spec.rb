require 'spec_helper'
require 'rake'

describe 'fromthepage:ai_disagreement_report' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, :field_based, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection) }
  let(:field) { create(:transcription_field, :as_transcription, :text_field, collection: collection, label: 'Body') }

  def create_transcription(page:, model:, field_text:, text_cer: nil)
    create(
      :ai_transcription,
      page: page,
      model: model,
      status: :finished,
      source_text: field_text,
      transcription_json: { field.id.to_s => field_text },
      text_cer: text_cer
    )
  end

  def run_report
    Rake::Task['fromthepage:ai_disagreement_report'].reenable
    Dir.mktmpdir do |directory|
      Dir.chdir(directory) do
        Rake::Task['fromthepage:ai_disagreement_report'].invoke(work.slug)
        return CSV.read("ai_disagreement_#{work.slug}.csv", headers: true)
      end
    end
  end

  it 'reports each model text-only CER and identifies fields with 100% text-only disagreement' do
    misplaced_page = create(:page, work: work)
    aligned_page = create(:page, work: work)
    create_transcription(page: misplaced_page, model: 'claude-sonnet', field_text: 'alpha', text_cer: 12)
    create_transcription(page: misplaced_page, model: 'gemini-pro', field_text: 'zzzzz', text_cer: 57)
    create_transcription(page: aligned_page, model: 'claude-sonnet', field_text: 'same')
    create_transcription(page: aligned_page, model: 'gemini-pro', field_text: 'same')

    rows = run_report
    misplaced_row = rows.find { |row| row['Page ID'] == misplaced_page.id.to_s }
    aligned_row = rows.find { |row| row['Page ID'] == aligned_page.id.to_s }

    expect(rows.headers).to include('Claude Text-only CER', 'Gemini Text-only CER')
    expect(rows.headers.index('Misplaced FIelds')).to eq(rows.headers.index('Character Disagreement Rate') + 1)
    expect(misplaced_row['Claude Text-only CER']).to eq('12')
    expect(misplaced_row['Gemini Text-only CER']).to eq('57')
    expect(misplaced_row['Body Text-only CDR']).to eq('100.0')
    expect(misplaced_row['Misplaced FIelds']).to eq('yes')
    expect(aligned_row['Claude Text-only CER']).to be_nil
    expect(aligned_row['Gemini Text-only CER']).to be_nil
    expect(aligned_row['Misplaced FIelds']).to eq('no')
  end
end
