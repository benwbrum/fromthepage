class AddFlagAllowlistPageblock < ActiveRecord::Migration[7.0]
  ALLOWLIST = [
    'merriam-webster.com',
    'ancestry.com',
    'findagrave.com',
    'wikipedia.org',
    'books.google.com',
    'thefreedictionary.com',
    'newspapers.com'
  ]

  def change
    pb = PageBlock.new
    pb.view = 'flag_allowlist'
    pb.controller = 'admin'
    pb.html = ALLOWLIST.join("\n")

    pb.save!
  end
end
