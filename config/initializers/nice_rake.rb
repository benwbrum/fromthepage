# Set constants to deafults if they aren't defined already so
# the app doesn't blow up when it's updtaed
# You should set these in the 01fromthepage.rb initializer.

NICE_RAKE_ENABLED = false unless defined?(NICE_RAKE_ENABLED)
NICE_RAKE_LEVEL = 10 unless defined?(NICE_RAKE_LEVEL)