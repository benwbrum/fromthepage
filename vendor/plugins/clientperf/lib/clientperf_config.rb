class ClientperfConfig
  
  delegate :[], :[]=, :each, :update, :to => :data

  class << self
    def defaults
      { 'username' => nil, 'password' => nil }
    end
    
    def config_file
      File.join(RAILS_ROOT, 'config', 'clientperf.yml')
    end
    
    def create_unless_exists(rails_dir)
      file = File.join(rails_dir, 'config', 'clientperf.yml')
      return if File.exists?(file)
      
      File.open(file, 'w') { |f| f.puts defaults.to_yaml }
    end
  end
  
  def data
    @data ||= begin
      YAML.load(File.read(self.class.config_file)) rescue self.class.defaults
    end
  end
    
  
  def has_auth?
    data['username'] && data['password']
  end  
end