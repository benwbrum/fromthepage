class CronWorker <BackgrounDRb::Rails  
  repeat_every 0.5
  first_run Time.now
  def do_work(args)
    @progress ||= 0
    @progress += 1
  end
  
  def progress
    @progress
  end      
end