require 'spec_helper'
require 'rake'

describe 'Flag abuse rake tasks' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before(:each) do
    # Reset class variables
    Flagger.class_variable_set(:@@denylist, nil)
    Flagger.class_variable_set(:@@allowlist, nil)

    # Set up denylist
    denylist_block = PageBlock.find_or_create_by(controller: 'admin', view: 'flag_denylist') do |pb|
      pb.html = "href\n.com\n.net"
    end
    denylist_block.html = "href\n.com\n.net"
    denylist_block.save!

    # Set up allowlist
    allowlist_block = PageBlock.find_or_create_by(controller: 'admin', view: 'flag_allowlist') do |pb|
      pb.html = "wikipedia.org\nancestry.com"
    end
    allowlist_block.html = "wikipedia.org\nancestry.com"
    allowlist_block.save!
  end

  describe 'fromthepage:recheck_flags_with_allowlist' do
    let(:user) { create(:user) }
    let(:work) { create(:work) }
    let(:page) { create(:page, work: work) }

    it 'removes flags that now match the allowlist' do
      # Create a page version with wikipedia.org URL
      page_version = PageVersion.create!(
        page: page,
        user: user,
        transcription: "See https://en.wikipedia.org/wiki/Example for more info",
        created_on: Time.now
      )

      # Create a flag for this content (simulating old behavior before allowlist)
      flag = Flag.create!(
        page_version: page_version,
        author_user: user,
        provenance: Flag::Provenance::REGEX,
        snippet: "See https://en.wikipedia.org/wiki/Example for more info",
        status: Flag::Status::UNCONFIRMED,
        content_at: Time.now
      )

      flag_id = flag.id
      expect(flag.status).to eq(Flag::Status::UNCONFIRMED)

      # Run the rake task
      Rake::Task['fromthepage:recheck_flags_with_allowlist'].reenable
      capture_stdout { Rake::Task['fromthepage:recheck_flags_with_allowlist'].invoke }

      # Verify the flag was removed
      expect(Flag.find_by(id: flag_id)).to be_nil
    end

    it 'does not clear flags for content that should still be flagged' do
      # Create a page version with a spam URL
      page_version = PageVersion.create!(
        page: page,
        user: user,
        transcription: "Visit http://spam-site.com for deals!",
        created_on: Time.now
      )

      # Create a flag for this content
      flag = Flag.create!(
        page_version: page_version,
        author_user: user,
        provenance: Flag::Provenance::REGEX,
        snippet: "Visit http://spam-site.com for deals!",
        status: Flag::Status::UNCONFIRMED,
        content_at: Time.now
      )

      expect(flag.status).to eq(Flag::Status::UNCONFIRMED)

      # Run the rake task
      Rake::Task['fromthepage:recheck_flags_with_allowlist'].reenable
      capture_stdout { Rake::Task['fromthepage:recheck_flags_with_allowlist'].invoke }

      # Verify the flag was not cleared
      flag.reload
      expect(flag.status).to eq(Flag::Status::UNCONFIRMED)
    end

    it 'only processes unconfirmed regex-based flags' do
      # Create a confirmed flag
      page_version = PageVersion.create!(
        page: page,
        user: user,
        transcription: "See https://en.wikipedia.org/wiki/Example",
        created_on: Time.now
      )

      confirmed_flag = Flag.create!(
        page_version: page_version,
        author_user: user,
        provenance: Flag::Provenance::REGEX,
        snippet: "See https://en.wikipedia.org/wiki/Example",
        status: Flag::Status::CONFRIMED,
        content_at: Time.now
      )

      # Run the rake task
      Rake::Task['fromthepage:recheck_flags_with_allowlist'].reenable
      capture_stdout { Rake::Task['fromthepage:recheck_flags_with_allowlist'].invoke }

      # Verify confirmed flag was not touched
      confirmed_flag.reload
      expect(confirmed_flag.status).to eq(Flag::Status::CONFRIMED)
    end
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    block.call
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
