class ConvertLatexPngsToSvgs < ActiveRecord::Migration[5.0]

  def change
    TexFigure.all.each do |tex_figure|
      tex_figure.clear_artifact
      tex_figure.create_artifact
    end
  end

end
