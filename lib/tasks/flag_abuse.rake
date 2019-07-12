require 'flagger'

namespace :fromthepage do

  desc "Check for abusive content retrospectively" 
  task :flag_abuse => :environment do |t|

    PageVersion.all.each do |version|
      Flag.check_page(version) unless version.flags.present?
    end
    ArticleVersion.all.each do |version|
      Flag.check_article(version) unless version.flags.present?
    end
    Note.all.each do |note|
      Flag.check_note(note) unless note.flags.present?
    end
  end
end
