namespace :fromthepage do

  desc "Check email configuration and sendability.\n\nUsage: rake fromthepage:check_email_config[target@address.com]"
  task :check_email_config, [:target] => :environment  do  |t,args|
    raise "No email address specified to rake task!\n\n" unless args.target

    unless Rails.application.config.action_mailer.default_url_options
      raise "No hostname set for this site: update config/environments/#{Rails.env}.rb and set \n\tconfig.action_mailer.default_url_options =  { host: 'fromthepagehostname.domainname.org' }\n\n"    
    end

    print "Testing configuration for #{Rails.env} environment\n"
    if Rails.env == 'development'
      print "WARNING:\tYou are testing the configuration of a development environment.\n\t\tIf you are trying to check a production server configuration, \n\t\trun this command with 'RAILS_ENV=production' added.\n"
    end
    unless Rails.application.config.action_mailer.default_options
      print "WARNING:\tNo default mailer options set.\n\t\tEdit config/environments/#{Rails.env}.rb and add:\n\t\tconfig.action_mailer.default_options\n"
    end

    target = args.target
    SystemMailer.config_test(target).deliver!
  end

  desc "Check installation configuration"
  task :check_installation_config => :environment do |t|
    print "Testing configuration for #{Rails.env} environment\n"
    if Rails.env == 'development'
      print "WARNING:\tYou are testing the configuration of a development environment.\n\t\tIf you are trying to check a production server configuration, \n\t\trun this command with 'RAILS_ENV=production' added.\n"
    end

    unless defined? RAKE
      raise "Your rake command must be defined in config/environments/#{Rails.env}.rb\nin order for background tasks like upload processing to run.\ne.g.\tRAKE=\"/usr/bin/env rake\""
    end
    unless system "#{RAKE} -T > /dev/null"
      raise "Test execution of\t#{RAKE} -T\tfailed.\nWhat happens when you try from the command line?"
    end
    
    unless defined? NEATO
      raise "Your neato command must be defined in config/environments/#{Rails.env}.rb\nin order for the subject graph to work.\ne.g.\tNEATO=\"/usr/bin/neato\""
    end
    unless system "#{NEATO} -V 2> /dev/null"
      raise "Test execution of\t#{NEATO} -V\tfailed.\nWhat happens when you try from the command line?\n(P.S. neato is part of the graphviz package.)"
    end
    unless File.writable?(File.join(Rails.root, 'public', 'images', 'working'))
      raise "Directory #{File.join(Rails.root, 'public', 'images', 'working')} is not writable\n"
    end
    unless system "pdflatex -version > /dev/null"
      raise "pdflatex is not installed, so LaTeX mark-up will not render until pdflatex and pdfcrop are installed.\n\tOn Debian and Ubuntu this can be accomplished by running:\n\tsudo apt-get install texlive-latex-base"    
    end
    unless system "pdfcrop -version > /dev/null"
      raise "pdfcrop is not installed, so LaTeX mark-up will not render until pdflatex and pdfcrop are installed.\n\tOn Debian and Ubuntu this can be accomplished by running:\n\tsudo apt-get install texlive-latex-base"
    end
    print "Configuration check completed successfully.  Consider running rake fromthepage:check_email_config next."
  end



end