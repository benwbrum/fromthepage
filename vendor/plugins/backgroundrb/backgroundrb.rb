require 'drb'
require 'digest/md5'
require 'thread'
require 'logger'
require 'singleton'
require File.dirname(__FILE__) + '/backgroundrb_rails'
# Set up BACKGROUNDRB_LOGGER to be the default logger for your worker
# objects. Use like: BACKGROUNDRB_LOGGER.warn("you've been warned")
# or BACKGROUNDRB_LOGGER.debug("debug info")
BACKGROUNDRB_LOGGER = Logger.new("#{RAILS_ROOT}/log/backgroundrb.log") if defined? RAILS_ROOT

class BackgrounDRbDuplicateKeyError < Exception 
end

module BackgrounDRb

  class MiddleMan
    include DRbUndumped
    include Singleton
    #attr_accessor :sleep
    # initialize @jobs as a Hash that holds a pool of all 
    # the running workers { job_key => running_worker_instance }
    # or can be used as a application wide cache with named keys
    # instead of randomly generated ones. @timestamps holds a 
    # hash of timestamps { job_key => timestamp }. So we can do 
    # timestamps and corelate them to workers for garbage 
    # collection when needed.
    def initialize#(sleep=60)
      @jobs = Hash.new
      @mutex = Mutex.new
      @timestamps = Hash.new
      @sleep = 60
      @running = true
      start_timer
    end 

    # takes an opts hash with symbol keys. :class refers to 
    # the under_score version of the worker class you want to
    # instantiate. :job_key can be set to use a named key, if
    # no :job_key is given we generate one. :args can hold 
    # any kind of info you want to give to your worker class
    # when it gets initialized. You can also specify a time to live
    # param via :ttl. If you don't set this your worker class will
    # be 'immortal' and won't be killed until the drb server is 
    # stopped or you call delete_worker on it directly.since we 
    # use the []= method that we have defined, timestamps are 
    # handled transparently.   
    def new_worker(opts={})
      @mutex.synchronize {
        job_key = opts[:job_key] || gen_key
        unless self[job_key]
          if opts[:singleton] == true
            worker = get_worker_by_class(opts[:class])
            return worker if worker
          end
          self[job_key] = instantiate_worker(opts[:class]).new(job_key, opts[:args])
          self[job_key].start_process
          @timestamps[job_key][:expire_type] = opts[:expire_type] || :created
          @timestamps[job_key][:ttl] = opts[:ttl] || :immortal
          return job_key
        else
          raise ::BackgrounDRbDuplicateKeyError
        end
      }
    end
    
    # delete a worker from the pool, also deletes the corresponding
    # entry in the @timestamps hash. If your worker needs to cleanup
    # after itslef before it gets deleted, then you need to set 
    # @job_ctrl = true in your worker class. Then have your worker
    # call terminate to signal its ok to be reaped.
    def delete_worker(key)
      @mutex.synchronize {
        if @jobs[key]
          if @jobs[key].respond_to?(:thread) && @jobs[key].thread.alive?
            if @jobs[key].job_ctrl
              @jobs[key].thread[:kill] = true
              @jobs[key].thread[:safe_to_kill].wait(@mutex)
            end  
            @jobs[key].thread.kill
          end
          @jobs.delete(key)
        end
        @timestamps.delete(key) if @timestamps.has_key?(key)
      }
    end
    
    alias :delete_cache :delete_worker
    
    def kill_worker(key)
      @mutex.synchronize {
        @jobs.delete(key) if @jobs.has_key?(key)
        @timestamps.delete(key) if @timestamps.has_key?(key)
      }
    end  

    # *IMPORTANT*
    # This method will override the :ttl parameter!
    #
    # garbage collection method for cleaning out jobs
    # older then a certain amount of time. You can have a
    # cron job run and call gc! with a Time object.
    # This will clean out all jobs older them that time. Call it
    # like this: MiddleMan.gc!(Time.now - 60*30). that will
    # clear out all jobs older then 30 minutes.
    def gc!(age)
      @timestamps.each do |job_key, timestamp|
        if timestamp[timestamp[:expire_type]] < age
          delete_worker(job_key)
        end
      end  
      GC.start
    end  
    
    def start_timer
      Thread.new do
        while @running
          @timestamps.each do |job_key, timestamp|
            unless @timestamps[job_key][:is_cache]
              if @jobs[job_key].schedule_repeat && (@jobs[job_key].next_start.to_i <= Time.now.to_i)
                @jobs[job_key].start_process
              end
            end  
            next if (timestamp[:ttl] == :immortal) || timestamp[:ttl].nil?
            if timestamp[timestamp[:expire_type]] + timestamp[:ttl] <= Time.now
              delete_worker(job_key)
            end  
          end  
          sleep @sleep
        end  
      end  
    end  
    
    # retrieve handle on worker object with key. Can be called
    # with a MiddleMan[:job_key] syntax or with MiddleMan.get_worker(:job_key)
    def [](key)
      @timestamps[key][:accessed] = Time.now if @jobs[key]
      @jobs[key]
    end
    alias :get_worker :[]
     
    def []=(key, val)
      @jobs[key] = val
      now = Time.now
      @timestamps[key] = {
          :created  => now,
          :accessed => now
      }
    end  
    
    def jobs
      @jobs
    end  
    
    def timestamps
      @timestamps
    end
    
    def set_sleep(num)
      @sleep = num  
    end
      
    # This method is used for caching arbitrary objects. Any object
    # that can be marshalled can be cached. Don't use this directly
    # use cache_as in the client side MiddleMan instead.
    def cache(named_key, ttl, object)
      @mutex.synchronize {
        self[named_key] = object
        @timestamps[named_key][:ttl] = ttl
        @timestamps[named_key][:expire_type] = :created
        @timestamps[named_key][:is_cache] = true
      }  
    end  
    
    private
    
    def get_worker_by_class(klass)
      klass = klass.to_s.split('_').inject('') { |total,part| total  << part.capitalize }
      @jobs.each do |job|
        if job[1].class.name == klass
          return job[0]
        end
      end
    
      return nil
    end
      
    def instantiate_worker(klass)
      Object.const_get(klass.to_s.split('_').inject('') { |total,part| total << part.capitalize })
    end
    
    def gen_key
      begin
        key = Digest::MD5.hexdigest("#{inspect}#{Time.now}#{rand}")
      end until self[key].nil?
      key
    end
  end  

end