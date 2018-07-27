class TranscriptionField < ActiveRecord::Base

belongs_to :collection
acts_as_list :scope => :collection
has_many :table_cells
validates :options, presence: true, if: Proc.new {|field| field.input_type == 'select'}, on: [:create, :update]

attr_accessible :label, :collection_id, :input_type, :options, :line_number, :position, :percentage, :page_number

validates :percentage, numericality: { allow_nil: true, greater_than: 0, less_than_or_equal_to: 100 }
validates :page_number, numericality: { allow_nil: true, greater_than: 0, less_than_or_equal_to: 1000 }

INPUTS = ["text", "select", "textarea"]

end
