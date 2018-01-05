class ResponseWS
  # FIXME add i18n to default message  
  attr_accessor :status, :message, :data
  
  def initialize(status,message,data)
    @status = status
    @message = message
    @data = data
  end
  
  def self.ok(message,data)
    ResponseWS.new("OK",message,data)
  end

  def self.simple_ok(message)
    ResponseWS.new("OK",message,nil)
  end
  
  def self.default_ok(data)
    ResponseWS.new("OK","La operación se realizó exitosamente",data)
  end
  
  def self.error(message,data)
    ResponseWS.new("ERROR",message,data)
  end
  
  def self.simple_error(message)
    ResponseWS.new("ERROR",message,nil)
  end
  
  def self.default_error
    ResponseWS.new("ERROR","Error del servidor, contáctese con el administrador",nil)
  end
  
end
