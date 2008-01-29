module BackgrounDRb

  class Rails
    include DRbUndumped
    attr_reader :job_ctrl, :thread
    attr_accessor :next_start, :interval
    # make your worker classes inherit from BackgrounDRb::Rails
    # to get access to all of your rails model classes. Doing it
    # this way also allows for very simple worker classes that
    # get threaded automatically.
    # class MyWorker < BackgrounDRb::Rails
    #   def do_work(args)
    #     # work done in here is already running inside of a
    #     # thread and gets called right away when you call
    #     # MiddleMan.new_worker from rails.
    #   end
    # end
    # doing it this way you also automatically get access to
    # the log via @logger. If you set @job_ctrl to true in your
    # worker class, you need to signal that your job is done
    # by calling terminate in your worker class.
    def initialize(key, args={})
      @logger = BACKGROUNDRB_LOGGER if defined? BACKGROUNDRB_LOGGER
      @thread = nil
      @args = args
      @_job_key = key
      @job_ctrl = false
    end

    def start_process
      return if schedule_first_run && schedule_first_run.to_i > Time.now.to_i
      @thread = Thread.new do
        Thread.current[:safe_to_kill] = ConditionVariable.new
        Thread.current[:kill] = false
        begin  
          do_work(@args)
        rescue Exception => e
          @logger.error "#{ e.message } - (#{ e.class })" << "\n" << (e.backtrace or []).join("\n")
        end
      end
      @next_start = @interval.from_now if schedule_repeat
    end

    def kill(key=@_job_key)
      ::BackgrounDRb::MiddleMan.instance.kill_worker(key)
    end  

    def spawn_worker(opts={})
      ::BackgrounDRb::MiddleMan.instance.new_worker(opts)
    end

    def check_terminate
      raise "Somehow this worker doesn't have a registered thread" if @thread.nil?
      return @thread[:kill]
    end

    def terminate?
      terminate if check_terminate
    end

    def terminate
      if check_terminate
        Thread.critical = true
        @logger.info "Terminating job #{self.class}"
        @thread[:safe_to_kill].signal
        @thread.stop
      end
      return
    end
    
    def self.repeat_every(interval)
      class_eval <<-e
        def schedule_repeat
          @interval = #{interval}
          true
        end
      e
    end
    
    def self.first_run(time)
      class_eval <<-e
        def schedule_first_run
          Time.parse("#{time}")
        end
      e
    end
    
    def schedule_first_run
      false
    end
    
    def schedule_repeat
      @interval = false
    end
  end
  
end  