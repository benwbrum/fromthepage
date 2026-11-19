namespace :fromthepage do
  namespace :passwords do
    # SEC-06: replaces every plain legacy SHA-1 password hash with bcrypt(SHA-1 digest), so none stays at
    # rest. Needs no passwords, and users notice nothing: they upgrade to plain bcrypt on their next login
    # (see LegacyPasswordHash). Only touches 40-hex hashes, so it's safe to re-run or resume.
    #
    # Run it only after the release that reads wrapped hashes has proven stable: older code can't read them.
    #
    #   bin/rake fromthepage:passwords:wrap_legacy
    #   BATCH_SIZE=500 bin/rake fromthepage:passwords:wrap_legacy
    desc 'Wrap legacy SHA-1 password hashes in bcrypt (safe to re-run)'
    task wrap_legacy: :environment do
      batch_size = ENV.fetch('BATCH_SIZE', 1000).to_i
      # The REGEXP narrows the scan; LegacyPasswordHash#legacy_sha1_hash? makes the exact check.
      scope = User.where('encrypted_password REGEXP ?', '^[0-9a-fA-F]{40}$')
      total = scope.count
      wrapped = 0
      skipped = 0

      puts "Wrapping #{total} legacy password hashes (bcrypt cost #{User.stretches})"
      started = Time.current

      scope.find_each(batch_size: batch_size) do |user|
        if user.wrap_legacy_password_hash!
          wrapped += 1
        else
          # Upgraded or changed since the batch was loaded
          skipped += 1
        end

        done = wrapped + skipped
        next unless (done % batch_size).zero?

        elapsed = Time.current - started
        puts "#{done}/#{total} (#{(elapsed / done * (total - done) / 60).round} min left)"
      end

      puts "Done: #{wrapped} wrapped, #{skipped} skipped, #{(Time.current - started).round}s"
    end
  end
end
