require 'flagger'

namespace :fromthepage do
  desc 'Check for abusive content retrospectively'
  task flag_abuse: :environment do |t|
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

  desc 'Re-examine unconfirmed flags and remove those that match the current allowlist'
  task recheck_flags_with_allowlist: :environment do |t|
    # Reset the class variables to force reload of denylist and allowlist
    Flagger.class_variable_set(:@@denylist, nil)
    Flagger.class_variable_set(:@@allowlist, nil)

    total_flags = 0
    cleared_flags = 0

    puts "Re-examining unconfirmed flags with current allowlist criteria..."

    Flag.where(status: Flag::Status::UNCONFIRMED, provenance: Flag::Provenance::REGEX).find_each do |flag|
      total_flags += 1
      content = nil

      # Get the content for this flag
      if flag.page_version
        content = flag.page_version.transcription
      elsif flag.article_version
        content = flag.article_version.source_text
      elsif flag.note
        content = flag.note.body
      end

      # Re-check the content with current criteria
      if content && Flagger.check(content).nil?
        # Content is now allowed, mark as false positive
        flag.status = Flag::Status::FALSE_POSITIVE
        flag.save!
        cleared_flags += 1
        puts "  Cleared flag ##{flag.id} - content now matches allowlist"
      end
    end

    puts "\nCompleted: #{cleared_flags} of #{total_flags} flags cleared"
  end
end
