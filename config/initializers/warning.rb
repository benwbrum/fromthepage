# Ignore all warnings in Gem dependencies
Gem.path.each do |path|
  Warning.ignore(//, path)
end

# Specifically ignore win32ole warning from oink gem
# This warning appears after Ruby 3.3.5 upgrade because win32ole will be removed from default gems in Ruby 3.5.0
# Since this application runs on Linux, win32ole is not needed
Warning.ignore(/win32ole was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3\.5\.0/)
