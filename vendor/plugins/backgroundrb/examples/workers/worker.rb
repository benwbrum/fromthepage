
class Worker < BackgrounDRb::Rails

  attr_accessor :text
  
  def do_work(args)
    @progress = 0
    @text = args[:text]
      while @progress < 100
        sleep rand / 2
        a = [1,3,5,7]
        @progress += a[rand(a.length-1)]
        if @progress >= 100
          @progress = 100
          @text = @text.upcase + " : object_id:" + self.object_id.to_s
        end
      end
  end

  def progress
    @logger.debug "#{self.object_id} : #{self.class} progress: #{@progress}"
    @progress
  end
end
