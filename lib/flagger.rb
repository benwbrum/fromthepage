class Flagger

  @@denylist = nil

  def self.initialize_denylist
    return unless @@denylist.nil?

    pb = PageBlock.find_by(controller: 'admin', view: 'flag_denylist')
    if pb
      @@denylist = pb.html.split("\n").map { |badness| badness.gsub('.', '\\.') }
    else
      @@denylist = []
    end
  end

  def self.check(content)
    initialize_denylist
    # look for suspicious strings
    @@denylist.each do |badness|
      badness.chomp!
      next unless content&.match(/(.{,80})(\S*)(#{badness})(.{,80})/m)

      # return a bad snippet if we find them
      prefix = ::Regexp.last_match(1)
      domain = ::Regexp.last_match(2)
      fixed = ::Regexp.last_match(3)
      suffix = ::Regexp.last_match(4)

      return "#{prefix}#{domain}#{fixed}#{suffix}"
    end
    nil
  end

end
