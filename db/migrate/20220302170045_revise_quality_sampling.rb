class ReviseQualitySampling < ActiveRecord::Migration[5.0]

  def change
    QualitySampling.delete_all
    remove_column :quality_samplings, :start_time
    remove_column :quality_samplings, :previous_start
    remove_column :quality_samplings, :pages_in_sample
    remove_column :quality_samplings, :sample_type
    rename_column :quality_samplings, :field, :sample_set
  end

end
