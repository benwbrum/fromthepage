class TexFigure < ActiveRecord::Base
  belongs_to :page
  acts_as_list :scope => :page
  
  attr_accessible :source
  before_save :review_artifact
  

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
  
  ###################
  # LaTeX stuff
  ###################
  def create_artifact
    # make sure we have a full directory 
    FileUtils.mkdir_p(artifact_dir_name)
    
    ## actual code to run latex, etc      
  end
  

  
  
  ##############
  # Low-level
  ##############
  
  def needs_artifact?
    !File.exist? artifact_file_path    
  end


  def clear_artifact
    File.unlink(artifact_file_path)
  end

  def review_artifact
    if changed.keys.include? [:source]
      clear_artifact
    end
  end

  
  def artifact_file_path
    File.join(artifact_dir_name, artifact_file_name)
  end
  
  def artifact_dir_name
    File.join(Rails.root, 'public', 'images', 'working', 'tex', page.id)    
  end
  
  def artifact_file_only
    # consider including work and page titles for better findability    
    "figure_#{position}.png"
  end
end
