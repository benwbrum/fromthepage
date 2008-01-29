class TestWorker < BackgrounDRb::Rails  
  attr_accessor :foo
  attr_accessor :job
  
  def do_work(args)
    @foo = args[:foo]
    @job = args[:job]
    @progress = 0
    while @progress < 100
      @progress += 1
    end
  end
  
  def progress
    @progress
  end      
end  
