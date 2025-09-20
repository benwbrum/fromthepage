class ConvertLabelToHash < ActiveRecord::Migration[5.0]
  def change
    FacetConfig.where.not(label: nil).each do |facet_config|
      facet_config.label = { 'en': facet_config.label }.to_json
      facet_config.save!
    end
  end
end
