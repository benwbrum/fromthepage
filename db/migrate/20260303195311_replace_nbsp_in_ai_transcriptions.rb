class ReplaceNbspInAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    AiTranscription.where.not(source_text: nil).find_each do |transcription|
      transcription.replace_nbsp
      transcription.save!
    end
  end
end
