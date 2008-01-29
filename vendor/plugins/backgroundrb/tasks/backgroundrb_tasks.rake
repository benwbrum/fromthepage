namespace :backgroundrb do
  require 'yaml'
  desc 'Setup backgroundrb in your rails application'
  task :setup do
    scripts_dest = "#{RAILS_ROOT}/script/backgroundrb"
    scripts_src = File.dirname(__FILE__) + "/../script/backgroundrb/"
    config_dest = "#{RAILS_ROOT}/config/backgroundrb.yml" 
    workers_dest = "#{RAILS_ROOT}/lib/workers"
    
    FileUtils.chmod 0774, ["#{scripts_src}start","#{scripts_src}stop"]
    
    defaults = {'host' => 'localhost', 
                'port' => '22222',
                'acl' => { 'order' => 'deny,allow', 'deny' => 'all', 'allow' => 'localhost 127.0.0.1' },
                'environment' => 'development',
                'timer_sleep' => 60,
                'database_yml' => 'config/database.yml',
                'load_rails'  => true}
    
             
    unless File.exists?(config_dest)
        puts "Copying backgroundrb.yml config file to #{config_dest}"
        File.open(config_dest, 'w') { |f| f.write(YAML.dump(defaults)) }
    end          

    unless File.exists?(scripts_dest)
        puts "Copying backgroundrb scripts to #{scripts_dest}"
        FileUtils.cp_r(scripts_src, scripts_dest)
    end

    workers_dest = "#{RAILS_ROOT}/lib/workers"
    unless File.exists?(workers_dest)
        puts "Creating #{workers_dest}"
        FileUtils.mkdir(workers_dest)
    end
  end

  desc 'Remove backgroundrb from your rails application'
  task :remove do
    scripts_src = "#{RAILS_ROOT}/script/backgroundrb"

    if File.exists?(scripts_src)
        puts "Removing #{scripts_src} ..."
        FileUtils.rm_r(scripts_src, :force => true)
    end

    workers_dest = "#{RAILS_ROOT}/lib/workers"
    if File.exists?(workers_dest) && Dir.entries("#{workers_dest}").size == 2
        puts "#{workers_dest} is empty...deleting!"
        FileUtils.rmdir(workers_dest)
    end
  end

  desc 'Start backgroundrb server (default values)'
  task :start do
    scripts_src = "#{RAILS_ROOT}/script/backgroundrb"

    if File.exists?(scripts_src)
    `#{scripts_src}/start -d`
    else
      puts "Backgroundrb is not installed. Run 'rake backgroundrb:setup' first!"
    end
  end

  desc 'Stop backgroundrb server (default values)'
  task :stop do
    scripts_src = "#{RAILS_ROOT}/script/backgroundrb"

    if File.exists?(scripts_src)
    `#{scripts_src}/stop`
    else
      puts "Backgroundrb is not installed. Run 'rake backgroundrb:setup' first!"
    end
  end
  
  desc "Restart BackgrounDRb Server"
  task :restart => [:stop, :start] do
    puts "Restarted BackgrounDRb"
  end  
end