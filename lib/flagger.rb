module Flagger
  BLACKLIST = [
    'href',
    '.info',
    '.in',
    '.net',
    '.store'
  ]



  def self.check(content)
    # look for suspicious strings
    BLACKLIST.each do |badness|
      if content && content.match(/(.{,80})(\S+)(#{badness})(.*{,80})/m)
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