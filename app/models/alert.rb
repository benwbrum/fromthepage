class Alert
  attr_accessor :title, :message
  
  def initialize(title,message)
    @title = I18n.t(title, :default => title)
    @message = I18n.t(message, :default => message)
  end
end
