class ResponseWS
  attr_accessor :status, :message, :data
  
  def initialize(status,message,data,alert)
    @status = status
    @message = I18n.t(message, :default => message)
    @data = data
    @alert = alert
  end
  
  def self.ok(message,data,alert = nil)
    ResponseWS.new("OK",message,data,alert)
  end

  def self.simple_ok(message,alert = nil)
    ResponseWS.ok(message,nil,alert)
  end
  
  def self.default_ok(data,alert = nil)
    ResponseWS.ok('api.default.ok',data,alert)
  end
  
  def self.error(message,data,alert = nil)
    ResponseWS.new("ERROR",message,data,alert)
  end
  
  def self.simple_error(message,alert = nil)
    ResponseWS.error(message,nil,alert)
  end
  
  def self.default_error(alert = nil)
    ResponseWS.error('api.default.error',nil,alert)
  end
  
end
