# == Schema Information
#
# Table name: ai_batch_generations
#
#  id            :integer          not null, primary key
#  batch_key     :string(255)
#  status        :string(255)      default("new"), not null
#  collection_id :bigint
#  work_id       :bigint
#
# Indexes
#
#  index_ai_batch_generations_on_batch_key      (batch_key)
#  index_ai_batch_generations_on_collection_id  (collection_id)
#  index_ai_batch_generations_on_work_id        (work_id)
#
class AiBatchGeneration < ApplicationRecord
  belongs_to :collection, optional: true
  belongs_to :work, optional: true

  has_many :ai_batch_generation_pages
  has_many :pages, through: :ai_batch_generation_pages
  has_many :ai_transcriptions, through: :ai_batch_generation_pages

  enum :status, {
    new: 'new',
    processing: 'processing',
    finished: 'finished',
    error: 'error'
  }, prefix: :status
end
