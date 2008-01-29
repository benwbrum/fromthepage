require 'action_view'

module SimpleCaptcha #:nodoc
  
  module ViewHelpers #:nodoc
    
    include ImageHandlers
    
    # Simple Captcha is a very simplified captcha.
    #
    # It can be used as a *Model* or a *Controller* based Captcha depending on what options
    # we are passing to the method show_simple_captcha.
    #
    # *show_simple_captcha* method will return the image, the label and the text box.
    # This method should be called from the view within your form as...
    #
    # <%= show_simple_captcha %>
    #
    # The available options to pass to this method are
    # * label
    # * image_syle
    # * object
    #
    # <b>Label:</b>
    #
    # default label is "type the text from the image", it can be modified by passing :label as
    #
    # <%= show_simple_captcha(:label => "new captcha label") %>.
    #
    # <b>Image Style:</b>
    #
    # There are eight different styles of images available as...
    # * embosed_silver
    # * simply_red
    # * simply_green
    # * simply_blue
    # * distorted_black
    # * all_black
    # * charcoal_grey
    # * almost_invisible
    #
    # The default image is simply_blue and can be modified by passing any of the above style as...
    #
    # <%= show_simple_captcha(:image_style => "simply_red") %>
    #
    # The images can also be selected randomly by using *random* in the image_style as
    # 
    # <%= show_simple_captcha(:image_style => "random") %>
    #
    # *Object*
    #
    # This option is needed to create a model based captcha.
    # If this option is not provided, the captcha will be controller based and
    # should be checked in controller's action just by calling the method simple_captcha_valid?
    #
    # To make a model based captcha give this option as...
    #
    # <%= show_simple_captcha(:object => "user") %>
    # and also call the method apply_simple_captcha in the model
    # this will consider "user" as the object of the model class.
    #
    # *Examples*
    # * controller based
    # <%= show_simple_captcha(:image_style => "embosed_silver", :label => "Human Authentication: type the text from image above") %>
    # * model based
    # <%= show_simple_captcha(:object => "person", :image_style => "simply_blue", :label => "Human Authentication: type the text from image above") %>
    #
    # Find more detailed examples with sample images here on my blog http://EXPRESSICA.com
    #
    # All Feedbacks/CommentS/Issues/Queries are welcome.
    def show_simple_captcha(options={})
      name = create_image(options)
      if options[:object]
        captcha_code = create_code
        field = text_field(options[:object], :captcha, :value => "")
        field << hidden_field(options[:object], :captcha_code, {:value => captcha_code})
      else
        field = text_field_tag(:captcha)
      end
      label = (!options[:label] or options[:label].empty?) ? "type the text from the image" : options[:label]
      ret =<<-EOS
           <div id='simple_captcha'>
           #{image_tag 'simple_captcha/' + name, :style => 'border:1px solid #999'}
           <p style='font-size:13px'>#{label}</p>
           <p>#{field}</p>
           </div>
           EOS
      GC.start
      return ret
    end
    
  end
  
end

ActionView::Base.module_eval do
  include SimpleCaptcha::ViewHelpers
end
