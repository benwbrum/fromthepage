module Flagger
  def self.check(content)
    # look for suspicious strings
    if content && content.match(/(.{,80})(\S+)(\.com)(.*{,80})/m)
      # return a bad snippet if we find them
      prefix = $1
      domain = $2
      fixed = $3
      suffix = $4

      "#{prefix}#{domain}#{fixed}#{suffix}"
    else
      # return nil if we don't
      nil
    end
  end
end