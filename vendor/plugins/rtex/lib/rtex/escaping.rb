module RTeX
  
  module Escaping
    
    # Escape text using +replacements+
    def escape(text)
      replacements.inject(text) do |corpus, (pattern, replacement)|
        corpus.gsub(pattern, replacement)
      end
    end
    
    # List of replacements
    def replacements
      @replacements ||= [
        [/([{}])/,    '\\\1'],
        [/\\/,        '\textbackslash{}'],
        [/\^/,        '\textasciicircum{}'],
        [/~/,         '\textasciitilde{}'],
        [/\|/,        '\textbar{}'],
        [/\</,        '\textless{}'],
        [/\>/,        '\textgreater{}'],
        [/([_$&%#])/, '\\\1']
      ]
    end
    
  end
  
end