require 'spec_helper'
require 'rake'

describe 'fromthepage:migrate_ai_accuracy_stats' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id, text_language: 'eng') }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:page) do
    page = create(:page, work: work)
    page.update!(
      source_text: 'cat dog fox',
      xml_text: "<?xml version='1.0' encoding='UTF-8'?><page>cat dog fox</page>"
    )
    page
  end
  let!(:ai_transcription) do
    create(
      :ai_transcription,
      page: page,
      status: :finished,
      source_text: 'cat dog owl',
      verbatim_cer: 36,
      verbatim_wer: 33,
      text_cer: 27,
      text_wer: 33,
      verbatim_non_stopword_accuracy: 67
    )
  end

  it 'recalculates cached rounded percentages from source text' do
    task = Rake::Task['fromthepage:migrate_ai_accuracy_stats']
    task.reenable
    task.invoke(nil, page.id.to_s)

    expect(ai_transcription.reload).to have_attributes(
      verbatim_cer: BigDecimal('35.71'),
      verbatim_wer: BigDecimal('33.33'),
      text_cer: BigDecimal('27.27'),
      text_wer: BigDecimal('33.33'),
      verbatim_non_stopword_accuracy: BigDecimal('66.67')
    )
  end
end
