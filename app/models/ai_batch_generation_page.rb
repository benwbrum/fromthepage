# == Schema Information
#
# Table name: ai_batch_generation_pages
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  ai_batch_generation_id :integer          not null
#  ai_transcription_id    :bigint
#  page_id                :integer          not null
#
# Indexes
#
#  index_ai_batch_generation_pages_on_ai_batch_generation_id  (ai_batch_generation_id)
#  index_ai_batch_generation_pages_on_ai_transcription_id     (ai_transcription_id)
#  index_ai_batch_generation_pages_on_page_id                 (page_id)
#
# Foreign Keys
#
#  fk_rails_...  (ai_batch_generation_id => ai_batch_generations.id)
#  fk_rails_...  (ai_transcription_id => ai_transcriptions.id)
#  fk_rails_...  (page_id => pages.id)
#
class AiBatchGenerationPage < ApplicationRecord
  belongs_to :ai_batch_generation
  belongs_to :page
  belongs_to :ai_transcription
end
