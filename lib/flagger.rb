class Flagger
  @@denylist = nil
  @@allowlist = nil

  def self.initialize_denylist
    if @@denylist.nil?
      pb = PageBlock.find_by(controller: 'admin', view: 'flag_denylist')
      if pb
        @@denylist = pb.html.split("\n").map { |badness| badness.gsub('.', '\\.') }
      else
        @@denylist = []
      end
    end
  end

  def self.initialize_allowlist
    if @@allowlist.nil?
      pb = PageBlock.find_by(controller: 'admin', view: 'flag_allowlist')
      if pb
        @@allowlist = pb.html.split("\n").map { |trusted| trusted.gsub('.', '\\.') }
      else
        @@allowlist = []
      end
    end
  end

  def self.check(content)
    initialize_denylist
    initialize_allowlist
    # look for suspicious strings
    @@denylist.each do |badness|
      badness.chomp!
      if content && content.match(/(.{,80})(\S*)(#{badness})(.{,80})/m)
        # Check if the matched content contains an allowed domain
        prefix = $1
        domain = $2
        fixed = $3
        suffix = $4
        matched_snippet = "#{prefix}#{domain}#{fixed}#{suffix}"
        
        # Check if any allowed domain is present in the matched snippet
        is_allowed = @@allowlist.any? do |trusted|
          trusted.chomp!
          matched_snippet.match(/#{trusted}/)
        end
        
        # Only return the snippet if it's not in the allowlist
        return matched_snippet unless is_allowed
      end
    end
    nil
  end
end
