class RemovePercentageFromQualitySampling < ActiveRecord::Migration[5.0]
  def change
    remove_column :quality_samplings, :percent, :decimal
    add_column :quality_samplings, :pages_in_sample, :int
    add_column :quality_samplings, :sample_type, :string
  end
end
