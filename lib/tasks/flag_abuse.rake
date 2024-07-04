require 'flagger'

namespace :fromthepage do
  desc 'Check for abusive content retrospectively'
  task flag_abuse: :environment do |_t|
    PageVersion.all.each do |version|
      Flag.check_page(version) if version.flags.blank?
    end
    ArticleVersion.all.each do |version|
      Flag.check_article(version) if version.flags.blank?
    end
    Note.all.each do |note|
      Flag.check_note(note) if note.flags.blank?
    end
  end
end
