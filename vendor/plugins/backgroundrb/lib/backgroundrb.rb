defaults = {'host' => 'localhost', 
            'port' => '22222'}
begin
  BACKGROUNDRB_CONFIG = defaults.merge(YAML.load(ERB.new(IO.read("#{RAILS_ROOT}/config/backgroundrb.yml")).result))
rescue
  BACKGROUNDRB_CONFIG = defaults
end

# This is the MiddleMan class that gets run on the rails side of things.
require "drb"
DRb.start_service('druby://localhost:0')
MiddleMan = DRbObject.new(nil, "druby://#{BACKGROUNDRB_CONFIG['host']}:#{BACKGROUNDRB_CONFIG['port']}")
class << MiddleMan
  # cache with named key data and time to live( defaults to 10 minutes).
  def cache_as(named_key, ttl=10*60, content=nil)
    if content
      cache(named_key, ttl, Marshal.dump(content))
      content
    elsif block_given?
      res = yield
      cache(named_key, ttl, Marshal.dump(res))
      res
    end  
  end

  def cache_get(named_key, ttl=10*60)
    if self[named_key]
      return Marshal.load(self[named_key])
    elsif block_given?
      res = yield
      cache(named_key, ttl, Marshal.dump(res))
      res
    else
      return nil    
    end     
  end
end