# Set constants to deafults if they aren't defined already so
# the app doesn't blow up when it's updtaed
# You should set these in the 01fromthepage.rb initializer.

NICE_RAKE_ENABLED = false unless defined?(NICE_RAKE_ENABLED)
NICE_RAKE_LEVEL = 10 unless defined?(NICE_RAKE_LEVEL)

# The "nice" settings allow users to use the Unix program 'nice'
# to schedule the priority of some Rake tasks related to uploading 
# and importing into FTP. Nice values may be between -20 and 19.
# The nice value defaults to 0 on most systems. Only the root user
# is able to set a nice value over below 0 (higher priority).
