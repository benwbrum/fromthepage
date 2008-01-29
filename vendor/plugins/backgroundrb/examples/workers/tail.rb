
class Tail < BackgrounDRb::Rails

  attr_accessor :filename

  def do_work(args)
    @filename = args[:filename]
    @count = 0
    tail
  end

  def tail(lines=10)
     @logger.debug "tail call count = #{@count += 1}"
     result = `tail -#{lines} #{@filename}`
     result
  end
end
