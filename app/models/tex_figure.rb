class TexFigure < ActiveRecord::Base
  belongs_to :page
  acts_as_list :scope => :page
  
  attr_accessible :source
  before_save :review_artifact
  
  # TODO: handle errors
  # TODO: add code to make sure articles still save
  # TODO: add config test code to check for pdflatex

  # the records will be saved when the page saves, but the artifacts may only be processed by a rake script launched offline at that time

  # page X is saved; everything is new
  # page processor creates new records, 1,2,3 here
  # rake task is launched to create artifacts for page X
  # task knows about page, can fetch the records -- how does it know if the artifact needs creation?
  # save knows whether it's dirty.  Save can blank the artifact
  # when the rake task runs, the only records with existing files will be clean
  
  
  def self.process_artifacts(page)
    page.tex_figures.each do |figure|
      if figure.needs_artifact?
        figure.create_artifact
      end
    end
  end

  def self.submit_background_process(page_id)
    rake_call = "#{RAKE} fromthepage:process_tex_figures[#{page_id}]  --trace 2>&1 >> #{log_file(page_id)} &"
    logger.info rake_call
    system(rake_call)    
  end
  
  def self.log_file(page_id)
    FileUtils.mkdir_p(TexFigure.artifact_dir_name(page_id))
    File.join(TexFigure.artifact_dir_name(page_id), "process.log")
  end



  ###################
  # LaTeX stuff
  ###################
  def create_artifact
    # make sure we have a full directory 
    FileUtils.mkdir_p(TexFigure.artifact_dir_name(self.page_id))
    
    ## actual code to run latex, etc
    write_source_file

    # latex
    run_latex
    postprocess_latex
  end
  

  def run_latex
    latex_command = "pdflatex -output-directory #{TexFigure.artifact_dir_name(self.page_id)} #{source_file_path}"
    p latex_command
    system(latex_command)
  end
  
  def postprocess_latex
    # TODO: handle potential failures here
    crop_command = "pdfcrop --clip #{raw_pdf_file_path} #{cropped_pdf_file_path}"
    p crop_command
    system(crop_command)
    convert_command = "convert -density 300 #{cropped_pdf_file_path} #{artifact_file_path}"
    p convert_command
    system(convert_command)
  end

  def write_source_file
    File.open(source_file_path, 'w') { |file| file.write(tex_source) }    
  end
  
  def tex_source
    %Q(
      \\documentclass{article}
      \\usepackage{amsmath}
      \\usepackage{amsfonts}
      \\begin{document}
      \\thispagestyle{empty}
      #{self.source}!
      \\end{document}
    )
  end
  
  ##############
  # Low-level
  ##############
  ARTIFACT_EXTENSION = "png"
  
  def text_to_png(infile,outfile)
    command = "convert -size 1000x2000 xc:white -pointsize 12 -fill black -annotate +15+15 \"@#{infile}\" -trim -bordercolor \"#FFF\" -border 10 +repage #{outfile}"
    system(command)
  end
  
  
  def needs_artifact?
    !File.exist? artifact_file_path    
  end


  def clear_artifact
    logger.debug("Removing #{artifact_file_path}")
    File.unlink(artifact_file_path)
  end

  def review_artifact
    if changed.include? "source"
      clear_artifact
    end
  end

  def raw_pdf_file_path
    artifact_file_path.sub(ARTIFACT_EXTENSION, "pdf")    
  end

  def cropped_pdf_file_path
    artifact_file_path.sub(ARTIFACT_EXTENSION, "crop.pdf")    
  end

  def source_file_path
    artifact_file_path.sub(ARTIFACT_EXTENSION, "tex")
  end
  
  def text_file_path
    artifact_file_path.sub(ARTIFACT_EXTENSION, "txt")
  end
  
  def artifact_file_path
    TexFigure.artifact_file_path(self.page.id, self.position)
  end
  
  def self.artifact_file_path(page_id, position)
    File.join(TexFigure.artifact_dir_name(page_id), TexFigure.artifact_file_only(position))    
  end
  
  def self.artifact_dir_name(page_id)
    File.join(Rails.root, 'public', 'images', 'working', 'tex', page_id.to_s)    
  end
  
  
  def artifact_file_only
    artifact_file_only(self.position)
  end
  
  def self.artifact_file_only(position)
    # consider including work and page titles for better findability    
    "figure_#{position}.#{ARTIFACT_EXTENSION}"
  end
end
