# Put your code that runs your task inside the do_work method
# it will be run automatically in a thread. You have access to
# all of your rails models if you set load_rails to true in the
# config file. You also get @logger inside of this class by default.
class <%= class_name %>Worker < BackgrounDRb::Rails
  
  def do_work(args)
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
  end

end
