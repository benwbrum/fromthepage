module ElasticUtil

  def self.get_client(enable_log = false)
    return Elasticsearch::Client.new(
      log: enable_log,
      cloud_id: ELASTIC_CLOUD_ID,
      api_key: ELASTIC_API_KEY
    )
  end

  def self.gen_bulk_action(index, body)
    bulk_action = {
      index: {
        _index: index,
        _id: body[:_id],
        data: body.except(:_id)
      }
    }

    return bulk_action
  end

  def self.reindex(model, index_name)
    client = self.get_client()

    # Allow simulatenous indexing requests
    pool_size= 2
    pool = WorkerPool.new(pool_size)
    pool.start

    model.find_in_batches(batch_size: 1000) do |batch|
      bulk_body = []
      batch.each do |item|
        bulk_body.push(
          ElasticUtil.gen_bulk_action(index_name, item.as_indexed_json())
        )
      end

      # Don't overload pending tasks
      while pool.pending > pool_size * 2
        sleep(1)
      end

      # Execute requests in new thread, it takes more time to prep the the next batch
      pool.schedule do
        begin
          client.bulk(body: bulk_body, refresh: false)
        rescue => e
          puts "Error with threaded bulk request"
        end
      end
    end

    # Finish remaining tasks and shutdown
    pool.shutdown()

    client.indices.refresh(index: index_name)
  end

  # Helper threading pool to execute indexing requests in parallel
  class WorkerPool
    def initialize(size)
      @size = size
      @queue = Queue.new
      @threads = []
      @shutdown = false
    end

    def start
      @size.times do
        @threads << Thread.new do
          until @shutdown && @queue.size == 0
            task = @queue.pop(true) rescue nil
            task&.call

            if @queue.size == 0
              sleep(1)
            end
          end
        end
      end
    end

    def pending
      return @queue.size
    end

    def schedule(&task)
      @queue << task
    end

    def shutdown
      @shutdown = true
      @threads.each(&:join)
    end
  end

end
