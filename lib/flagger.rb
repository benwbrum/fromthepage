class Flagger
  @@blacklist = nil

  def self.initialize_blacklist
    if @@blacklist.nil?
      pb = PageBlock.find_by(:controller => 'admin', :view => 'flag_blacklist')
      @@blacklist = PageBlock.find_by(:controller => 'admin', :view => 'flag_blacklist').html.split("\n").map { |badness| badness.gsub(".", "\\.") }
    end
  end


  def self.check(content)
    initialize_blacklist
    # look for suspicious strings
    @@blacklist.each do |badness|
      if content && content.match(/(.{,80})(\S+)(#{badness})(.{,80})/m)
        # return a bad snippet if we find them
        prefix = $1
        domain = $2
        fixed = $3
        suffix = $4

        return "#{prefix}#{domain}#{fixed}#{suffix}"
      end
    end
    return nil
  end
end