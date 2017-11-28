class TranscriptionField < ActiveRecord::Base

belongs_to :collection
acts_as_list :scope => :collection

attr_accessible :label, :collection_id, :input_types, :options, :line_number, :position

INPUTS = ["text", "select", "textarea"]

end
