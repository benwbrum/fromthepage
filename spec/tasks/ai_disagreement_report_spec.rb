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

  def create_transcription(page:, model:, field_text:, text_cer: nil, transcription_json: nil)
    create(
      :ai_transcription,
      page: page,
      model: model,
      status: :finished,
      source_text: field_text,
      transcription_json: transcription_json || { field.id.to_s => field_text },
      text_cer: text_cer
    )
  end

  def run_report(*ignored_fields)
    Rake::Task['fromthepage:ai_disagreement_report'].reenable
    Dir.mktmpdir do |directory|
      Dir.chdir(directory) do
        Rake::Task['fromthepage:ai_disagreement_report'].invoke(work.slug, *ignored_fields)
        return CSV.read("ai_disagreement_#{work.slug}.csv", headers: true)
      end
    end
  end

  it 'reports each model text-only CER and identifies fields with 100% text-only disagreement' do
    misplaced_page = create(:page, work: work, status: :needs_review)
    aligned_page = create(:page, work: work)
    create_transcription(page: misplaced_page, model: 'claude-sonnet', field_text: 'alpha', text_cer: 12)
    create_transcription(page: misplaced_page, model: 'gemini-pro', field_text: 'zzzzz', text_cer: 57)
    create_transcription(page: aligned_page, model: 'claude-sonnet', field_text: 'same')
    create_transcription(page: aligned_page, model: 'gemini-pro', field_text: 'same')

    rows = run_report
    misplaced_row = rows.find { |row| row['Page ID'] == misplaced_page.id.to_s }
    aligned_row = rows.find { |row| row['Page ID'] == aligned_page.id.to_s }

    expect(rows.headers).to include('Claude Text-only CER', 'Gemini Text-only CER')
    expect(misplaced_row['Page Status']).to eq('needs_review')
    expect(rows.headers.index('Misplaced FIelds')).to eq(rows.headers.index('Character Disagreement Rate') + 1)
    expect(misplaced_row['Claude Text-only CER']).to eq('12')
    expect(misplaced_row['Gemini Text-only CER']).to eq('57')
    expect(misplaced_row['Body Text-only CDR']).to eq('100.0')
    expect(misplaced_row['Misplaced FIelds']).to eq('yes')
    expect(aligned_row['Claude Text-only CER']).to be_nil
    expect(aligned_row['Gemini Text-only CER']).to be_nil
    expect(aligned_row['Misplaced FIelds']).to eq('no')
  end

  it 'removes punctuation and whitespace when calculating per-field text-only CDR' do
    page = create(:page, work: work)
    create_transcription(page: page, model: 'claude-sonnet', field_text: 'Hello, world!')
    create_transcription(page: page, model: 'gemini-pro', field_text: "hello world")

    row = run_report.first

    expect(row['Body CDR']).not_to eq('0.0')
    expect(row['Body Text-only CDR']).to eq('0.0')
  end

  it 'keeps ignored fields in per-field columns but excludes labels and ids from overall calculations' do
    ignored_by_label = create(:transcription_field, :as_transcription, :text_field, collection: collection, label: 'Ignore Label')
    ignored_by_id = create(:transcription_field, :as_transcription, :text_field, collection: collection, label: 'Ignore ID')
    page = create(:page, work: work)
    claude_json = { field.id.to_s => 'same', ignored_by_label.id.to_s => 'alpha', ignored_by_id.id.to_s => 'one' }
    gemini_json = { field.id.to_s => 'same', ignored_by_label.id.to_s => 'zzzzz', ignored_by_id.id.to_s => 'two' }
    create_transcription(page: page, model: 'claude-sonnet', field_text: 'unused', transcription_json: claude_json)
    create_transcription(page: page, model: 'gemini-pro', field_text: 'unused', transcription_json: gemini_json)

    row = run_report('Ignore Label', ignored_by_id.id.to_s).first

    expect(row['Character Disagreement Rate']).to eq('0.0')
    expect(row['Case-insensitive CDR']).to eq('0.0')
    expect(row['Misplaced FIelds']).to eq('no')
    expect(row['Ignore Label Text-only CDR']).to eq('100.0')
    expect(row['Ignore ID CDR']).not_to be_nil
  end

  it 'includes field labels in overall case-sensitive and case-insensitive comparisons' do
    second_field = create(:transcription_field, :as_transcription, :text_field, collection: collection, label: 'Other')
    page = create(:page, work: work)
    create_transcription(
      page: page,
      model: 'claude-sonnet',
      field_text: 'same source text',
      transcription_json: { field.id.to_s => 'alpha', second_field.id.to_s => 'beta' }
    )
    create_transcription(
      page: page,
      model: 'gemini-pro',
      field_text: 'same source text',
      transcription_json: { field.id.to_s => 'beta', second_field.id.to_s => 'alpha' }
    )

    row = run_report.first

    expect(row['Character Disagreement Rate'].to_f).to be > 0
    expect(row['Case-insensitive CDR'].to_f).to be > 0
  end
end
