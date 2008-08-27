require 'erb'
require 'ostruct'
require 'tmpdir'

require 'escaping'
require 'tempdir'


module RTeX
  
  class Document
    
    extend Escaping
        
    class FilterError < ::StandardError; end
    class GenerationError < ::StandardError; end
    class ExecutableNotFoundError < ::StandardError; end
    
    # Default options
    # [+:preprocess+] Are we preprocessing? Default is +false+
    # [+:preprocessor+] Executable to use during preprocessing (generating TOCs, etc). Default is +latex+
    # [+:shell_redirect+] Option redirection for shell output (eg, +"> /dev/null 2>&1"+ ). Default is +nil+.
    # [+:tmpdir+] Location of temporary directory (default: +Dir.tmpdir+)
    def self.options
      @options ||= {
        :preprocessor => 'latex',
        :preprocess => false,
        :processor => 'pdflatex',
        # 
        :shell_redirect => nil,
        # Temporary Directory
        :tempdir => Dir.tmpdir
      }
    end
        
    def initialize(content, options={})
      @options = self.class.options.merge(options)
      if @options[:processed]
        @source = content
      else
        @erb = ERB.new(content)
      end
    end
    
    # Get the source for the entire 
    def source(binding=nil) #:nodoc:
      @source ||= wrap_in_layout do
        filter @erb.result(binding)
      end
    end
    
    # Process through defined filter
    def filter(text) #:nodoc:
      return text unless @options[:filter]
      if (process = RTeX.filters[@options[:filter]])
        process[text]
      else
        raise FilterError, "No `#{@options[:filter]}' filter"
      end
    end
    
    # Wrap content in optional layout
    def wrap_in_layout #:nodoc:
      if @options[:layout]
        ERB.new(@options[:layout]).result(binding)
      else
        yield
      end
    end
    
    # Generate PDF from 
    # call-seq:
    #   to_pdf # => PDF in a String
    #   to_pdf { |filename| ... }
    def to_pdf(binding=nil, &file_handler)
      process_pdf_from(source(binding), &file_handler)
    end
    
    def processor #:nodoc:
      @processor ||= check_path_for @options[:processor]
    end
    
    def preprocessor #:nodoc:
      @preprocessor ||= check_path_for @options[:preprocessor]
    end
    
    def system_path #:nodoc:
      ENV['PATH']
    end
        
    #######
    private
    #######
    
    # Verify existence of executable in search path
    def check_path_for(command)
      unless FileTest.executable?(command) || system_path.split(":").any?{ |path| FileTest.executable?(File.join(path, command))}
        raise ExecutableNotFoundError, command
      end
      command
    end
    
    # Basic processing
    def process_pdf_from(input, &file_handler)
      Tempdir.open(@options[:tempdir]) do |tempdir|
        prepare input
        if generating?
          preprocess! if preprocessing?
          process!
          verify!
        end
        if file_handler
          yield full_path_in(tempdir.path)
        else
          result_as_string
        end
      end
    end
    
    def process!
      unless `#{processor} --interaction=nonstopmode '#{source_file}' #{@options[:shell_redirect]}`
        raise GenerationError, "Could not generate PDF using #{processor}"      
      end
    end
    
    def preprocess!
      unless `#{preprocessor} --interaction=nonstopmode '#{source_file}' #{@options[:shell_redirect]}`
        raise GenerationError, "Could not preprocess using #{preprocessor}"      
      end
    end
    
    def preprocessing?
      @options[:preprocess]
    end
        
    def source_file
      @source_file ||= file(:tex)
    end
    
    def log_file
      @log_file ||= file(:log)
    end
    
    def result_file
      @result_file ||= file(@options[:tex] ? :tex : :pdf)
    end
    
    def file(extension)
      "document.#{extension}"
    end
    
    def generating?
      !@options[:tex]
    end
    
    def verify!
      unless File.exists?(result_file)
        raise GenerationError, "Could not find result PDF #{result_file} after generation.\nCheck #{File.expand_path(log_file)}"
      end
    end
    
    def prepare(input)
      File.open(source_file, 'wb') { |f| f.puts input }
    end
    
    def result_as_string
      File.open(result_file, 'rb') { |f| f.read }
    end
    
    def full_path_in(directory)
      File.expand_path(File.join(directory, result_file))
    end
    
  end

end
