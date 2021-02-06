module TranscriptionFieldHelper
  def field_order(collection)
    @fields = collection.transcription_fields.order(:line_number).order(:position).group_by(&:line_number)
  end

  def field_layout(array)
    count = array.count
    @width = 100/count unless count == nil
    ids = array.map {|a| a.id}
    @values = []
    if @page
      ids.each do |id|
        @values << @page.table_cells.find_by(transcription_field_id: id) || nil
      end
    else
      @values = Array.new(ids.count, nil)
    end
    @field_array = array.zip(@values)
  end

end
