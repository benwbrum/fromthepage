# == Schema Information
#
# Table name: page_processing_tasks
#
#  id                     :integer          not null, primary key
#  position               :integer
#  status                 :string(255)
#  type                   :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  page_processing_job_id :integer          not null
#
# Indexes
#
#  index_page_processing_tasks_on_page_processing_job_id  (page_processing_job_id)
#
# Foreign Keys
#
#  fk_rails_...  (page_processing_job_id => page_processing_jobs.id)
#
require 'alto_transformer'
require 'openai/text_normalizer'
require 'diff_tools'

# individual task for creating AI Text for a particular page
module OpenAi
  class AiTextPageProcessingTask < PageProcessingTask
    def process_page
      # parse the diff level from the ai_job parameters
      diff_level = ai_job.parameters[self.class.name]['diff_level'].to_sym || :none
      self.status=Status::RUNNING
      self.save

      if page.has_alto?
        # if it does, read the ALTO XML and generate AI Plaintext
        raw_alto = page.alto_xml
        # TODO move to ai_result
        plaintext = generate_plaintext(raw_alto, diff_level)
        if !plaintext.blank?
          # save the plaintext
          page.ai_plaintext = generate_plaintext(raw_alto, diff_level)
        end
      end

      self.status=Status::COMPLETED
      self.save
    end

    def generate_plaintext(raw_alto, diff_level)
      # convert the alto to plaintext, using the same method as when we ingest XML files
      plaintext = AltoTransformer.plaintext_from_alto_xml(raw_alto)
      # some pages are blank, so they will have no word characters in the plaintext
      # we want to skip those pages
      return nil if !plaintext.match(/\w/m)
  
      # do any additional processing here
      if diff_level != :none
        # normalize the plaintext
        normalized_plaintext = TextNormalizer.normalize_text(plaintext)
        # generate the diff
        new_plaintext = DiffTools.diff_and_replace(plaintext, normalized_plaintext, "🤔")
        if diff_level == :word
          new_plaintext.gsub!(/\b\w+🤔\w+\b/m, '🤔')
        end
        # replace the existing AI plaintext with the new plaintext
        plaintext = new_plaintext
      end
      plaintext
    end
  end
end
