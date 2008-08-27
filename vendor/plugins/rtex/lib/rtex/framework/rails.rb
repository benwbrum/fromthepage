require 'tempfile'

module RTeX
  module Framework #:nodoc:   
    module Rails #:nodoc:
      
      def self.setup
        RTeX::Document.options[:tempdir] = File.expand_path(File.join(RAILS_ROOT, 'tmp'))
        if ActionView::Base.respond_to?(:register_template_handler)
          ActionView::Base.register_template_handler(:rtex, Template)
        else
          # Rails 2.1
          ActionView::Template.register_template_handler(:rtex, Template)
        end
        ActionController::Base.send(:include, ControllerMethods)
        ActionView::Base.send(:include, HelperMethods)
      end
      
      class Template < ::ActionView::TemplateHandlers::ERB
        def initialize(*args)
          super
          @view.template_format = :pdf
        end
      end
      
      module ControllerMethods
        def self.included(base)
          base.alias_method_chain :render, :rtex
        end
        
        def render_with_rtex(options=nil, *args, &block)
          result = render_without_rtex(options, *args, &block)
          if result.is_a?(String) && @template.template_format == :pdf
            options ||= {}
            ::RTeX::Document.new(result, options.merge(:processed => true)).to_pdf do |filename|
              serve_file = Tempfile.new('rtex-pdf')
              FileUtils.mv filename, serve_file.path
              send_file serve_file.path,
                :disposition => (options[:disposition] rescue nil) || 'inline',
                :url_based_filename => true,
                :filename => (options[:filename] rescue nil),
                :type => "application/pdf",
                :length => File.size(serve_file.path)
              serve_file.close
            end
          else
            result
          end
        end
      end
      
      module HelperMethods
        def latex_escape(s)
          RTeX::Document.escape(s)
        end
        alias :l :latex_escape
      end
      
    end
  end
end