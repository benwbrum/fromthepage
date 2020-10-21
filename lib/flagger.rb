class Flagger
  @@denylist = nil

  def self.initialize_denylist
    if @@denylist.nil?
      pb = PageBlock.find_by(:controller => 'admin', :view => 'flag_denylist')
      @@denylist = PageBlock.find_by(:controller => 'admin', :view => 'flag_denylist').html.split("\n").map { |badness| badness.gsub(".", "\\.") }
    end
  end


  def self.check(content)
    initialize_denylist
    # look for suspicious strings
    @@denylist.each do |badness|
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
