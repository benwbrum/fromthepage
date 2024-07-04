class LengthenScCanvasAnnotations < ActiveRecord::Migration[6.0]

  def change
    change_column(:sc_canvases, :annotations, :text, limit: 16_000_000)
  end

end
