class TexFigure < ActiveRecord::Base
  belongs_to :page
  acts_as_list :scope => :page
  
  attr_accessible :source
  before_save :review_artifact
  
  # TODO: add config test code to check for pdflatex
  # TODO: check readme for other packages needed and test for those

  # the records will be saved when the page saves, but the artifacts may only be processed by a rake script launched offline at that time

  # page X is saved; everything is new
  # page processor creates new records, 1,2,3 here
  # rake task is launched to create artifacts for page X
  # task knows about page, can fetch the records -- how does it know if the artifact needs creation?
  # save knows whether it's dirty.  Save can blank the artifact
  # when the rake task runs, the only records with existing files will be clean
  
  def self.process_artifacts(page)
    puts "TexFigure.process_artifacts(page_id = #{page.id})"
    puts "PATH="
    puts ENV['PATH']
    puts "Modifying path"
    ENV['PATH'] = ENV["PATH"].split(":").push(TEX_PATH).join(":")

    page.tex_figures.each do |figure|
      puts "TexFigure.process_artifacts considering figure #{figure.id} source #{figure.source}"
      if figure.needs_artifact?
	puts "figure needs artifact.  creating"
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
    puts "TexFigure.create_artifact conditionally creating directory"
    # make sure we have a full directory 
    FileUtils.mkdir_p(TexFigure.artifact_dir_name(self.page_id))
    
    puts "TexFigure.create_artifact conditionally creating directory"
    ## actual code to run latex, etc
    write_source_file

    puts "TexFigure.create_artifact preprocessing latex"
    # latex
    preprocess_latex

    puts "TexFigure.create_artifact running latex"
    if run_latex
    puts "TexFigure.create_artifact postprocessing latex"
      postprocess_latex
    else
      puts "TexFigure.create_artifact processing errors"
      postprocess_errors
    end
  end
  

  def preprocess_latex
    File.unlink(artifact_file_path) if File.exist?(artifact_file_path) 
    File.unlink(raw_pdf_file_path) if File.exist?(raw_pdf_file_path) 
    File.unlink(cropped_pdf_file_path) if File.exist?(cropped_pdf_file_path) 
  end

#  XELATEX='/usr/local/texlive/2017/bin/x86_64-linux/xelatex'
  XELATEX='xelatex'
  PDFCROP='pdfcrop'
  PDF2SVG='pdf2svg'

  def run_latex
    latex_command = "#{XELATEX} -interaction batchmode -output-directory #{TexFigure.artifact_dir_name(self.page_id)} #{source_file_path}"
    logger.info(latex_command)    
    puts latex_command
    puts `#{latex_command} 2>&1`
    $? # return the error code from running the command, not the return from puts
  end
  
  def postprocess_latex
    crop_command = "#{PDFCROP} --clip #{raw_pdf_file_path} #{cropped_pdf_file_path}"
    logger.info(crop_command)
    puts crop_command
    puts `#{crop_command}  2>&1`

    #convert_command = "convert -density 300 #{cropped_pdf_file_path} #{artifact_file_path}"
    convert_command = "#{PDF2SVG} #{cropped_pdf_file_path} #{artifact_file_path}"
    logger.info(convert_command)
    puts convert_command
    puts `#{convert_command} 2>&1`
  end

  LATEX_ERROR = /^!(.*?\n(\w*.(\S*)).*?\n.*?\n)/m
  def postprocess_errors
    error_lines = []
    
    File.open(tex_log_file_path).read.scan(LATEX_ERROR).each do |text, line_id, line_no|
      new_number = line_no.to_i - 6
      error_lines << text.sub(line_id, new_number.to_s)     
    end
    
      error_line_string = ""
      y = 45
      error_lines.each do |error|
        error_line_string << "<tspan x=\"10\" y=\"#{y}\"> #{error} </tspan>"
        y=y+10
      end
      svg_string= <<EOF
<?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="200" height="90" viewBox="0 0 293 10" version="1.1">
      <text x="10" y="20" style="fill:red;">LaTex Processing Error:
        #{error_line_string}
      </text>
      </svg>
EOF
    File.open(artifact_file_path, 'w') { |file| file.write(svg_string) }  
  end

  def write_source_file
    File.open(source_file_path, 'w') { |file| file.write(tex_source) }    
  end
  
  def tex_source
    %Q(
      \\documentclass{article}
      \\usepackage{amsmath}
      \\usepackage{amsfonts}
      \\IfFileExists{epeirce.sty}{
        \\usepackage{egpeirce}
      }
      \\IfFileExists{xymtex.sty}{
        \\usepackage{xymtex}
      }
      \\IfFileExists{chemfig.sty}{
        \\usepackage{chemfig}
      }
      \\begin{document}
      \\thispagestyle{empty}
      #{self.source}
      \\end{document}
    )
  end
  
  ##############
  # Low-level
  ##############
  ARTIFACT_EXTENSION = "svg"
  
  def text_to_png(infile,outfile)
    puts "TexFiture.text_to_png(#{infile},#{outfile})"
    command = "convert -size 1000x2000 xc:white -pointsize 12 -fill red -annotate +15+15 \"@#{infile}\" -trim -bordercolor \"#FFF\" -border 10 +repage #{outfile}"
    puts command
    puts `#{command}`
  end
  
  def needs_artifact?
    !File.exist? artifact_file_path    
  end


  def clear_artifact
    logger.debug("Removing #{artifact_file_path}")
    File.unlink(artifact_file_path) if File.exist?(artifact_file_path)
  end

  def review_artifact
    if changed.include? "source"
      clear_artifact
    end
  end

  def tex_log_file_path
    artifact_file_path.sub(ARTIFACT_EXTENSION, "log")    
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
