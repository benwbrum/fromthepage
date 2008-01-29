require 'pstore'
require 'RMagick'

module SimpleCaptcha #:nodoc
  
  module ImageHandlers #:nodoc
    
    include ConfigTasks
    
    IMAGE_STYLES = [
                    "embosed_silver",
                    "simply_red",
                    "simply_green",
                    "simply_blue",
                    "distorted_black",
                    "all_black",
                    "charcoal_grey",
                    "almost_invisible"
                   ]
    
    DISTORTIONS = {
      :low => [0, 100],
      :medium => [3, 50],
      :high => [5, 30]
    }
    
    private
    
    def image_details #:nodoc
      string = ""
      6.times{string << (65 + rand(25)).chr}
      name = create_code
      data = PStore.new(CAPTCHA_DATA_PATH + "data")
      data.transaction{data[name] = string}
      return string, name << ".jpg"
    end
    
    def add_text(options) #:nodoc
      options[:color] = "darkblue" unless options.has_key?(:color)
      text = Magick::Draw.new
      text.annotate(options[:image], 0, 0, 0, 5, options[:string]) do
        self.font_family = 'arial'
        self.pointsize = 22
        self.fill = options[:color]
        self.gravity = Magick::NorthGravity 
      end
      return options[:image]
    end
    
    def add_text_and_effects(options={}) #:nodoc
      image = Magick::Image.new(110, 30){self.background_color = 'white'}
      options[:image] = image
      distortion = DISTORTIONS[options[:distortion].to_sym] || DISTORTIONS[:medium]
      amp, freq = distortion[0], distortion[1]
      case options[:image_style]
      when "embosed_silver"
        image = add_text(options)
        image = image.wave(amp, freq).shade(true, 20, 60)
      when "simply_red"
        options[:color] = "darkred"
        image = add_text(options)
        image = image.wave(amp, freq)
      when "simply_green"
        options[:color] = "darkgreen"
        image = add_text(options)
        image = image.wave(amp, freq)
      when "simply_blue"
        image = add_text(options)
        image = image.wave(amp, freq)
      when "distorted_black"
        image = add_text(options)
        image = image.wave(amp, freq).edge(10)
      when "all_black"
        image = add_text(options)
        image = image.wave(amp, freq).edge(2)
      when "charcoal_grey"
        image = add_text(options)
        image = image.wave(amp, freq).charcoal
      when "almost_invisible"
        options[:color] = "red"
        image = add_text(options)
        image = image.wave(amp, freq).solarize
      else
        image = add_text(options)
        image = image.wave(amp, freq)
      end
      return image
    end
    
    def create_image(options) #:nodoc
      image_style, distortion = options[:image_style] || "simply_blue", options[:distortion] || "medium"
      image_style = IMAGE_STYLES[rand(IMAGE_STYLES.length)] if image_style=="random"
      string, name = image_details
      options = {
        :image_style => image_style,
        :distortion => distortion,
        :string => string
      }
      image = add_text_and_effects(options)
      image.implode(0.2).write(CAPTCHA_IMAGE_PATH + name)
      remove_simple_captcha_files
      return name
    end
    
  end
  
end
