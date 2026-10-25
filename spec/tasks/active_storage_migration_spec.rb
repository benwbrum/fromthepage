require 'spec_helper'
require 'rake'
require 'tmpdir'

RSpec.describe 'fromthepage:delete_migrated_page_images' do
  let(:task) { Rake::Task['fromthepage:delete_migrated_page_images'] }
  let(:files) { [] }
  let(:blobs) { [] }
  let(:page_ids) { [] }

  before(:all) do
    Rake.application.rake_require 'tasks/active_storage_migration'
    Rake::Task.define_task(:environment)
  end

  around do |example|
    run_example = proc do
      @directory = Pathname.new(Dir.mktmpdir('image-cleanup-', Rails.root.join('public')))
      example.run
    ensure
      blobs.each { |blob| blob.service.delete(blob.key) }
      FileUtils.remove_entry(@directory) if @directory&.exist?
    end
    if example.metadata[:disconnect]
      # A real disconnect rolls back transactions, so this example commits its
      # fixtures and explicitly removes only its own rows afterwards.
      begin
        run_example.call
      ensure
        ActiveStorage::Attachment.where(record_type: 'Page', record_id: page_ids).delete_all
        ActiveStorage::Blob.where(id: blobs.map(&:id)).delete_all
        Page.unscoped.where(id: page_ids).delete_all
      end
    else
      DatabaseCleaner.cleaning { run_example.call }
    end
  end

  before do
    task.reenable
    # Keep the all-pages tests independent of any preloaded fixtures.
    scope = Page.unscoped.where('pages.id > ?', Page.maximum(:id) || 0)
    allow(Page).to receive(:all).and_return(scope)
  end

  def legacy_page(attached: true, stored: true, local: true, base_image: nil, work_id: nil)
    path = @directory.join("#{page_ids.length}.jpg")
    File.write(path, 'legacy image') if local
    files << path
    id = Page.connection.insert(Page.sanitize_sql_array([
      'INSERT INTO pages (base_image, work_id) VALUES (?, ?)', base_image || path.to_s, work_id
    ]))
    page_ids << id
    page = Page.find(id)
    if attached
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('stored image'), filename: 'image.jpg', content_type: 'image/jpeg', identify: false)
      blobs << blob
      ActiveStorage::Attachment.create!(record: page, name: 'image', blob: blob)
      blob.service.delete(blob.key) unless stored
    end
    page
  end

  def run_cleanup(scope: 'all', start: '1', batch: '2', dry_run: 'false')
    task.invoke(scope, start, batch, dry_run)
  end

  it 'defaults to a dry run' do
    legacy_page
    expect { task.invoke('all') }.to output(/Would delete 1 files/).to_stdout
    expect(files.first).to exist
  end

  it 'deletes the legacy image and thumbnail while preserving the attachment and blob' do
    page = legacy_page
    thumbnail = files.first.sub('.jpg', '_thumb.jpg')
    File.write(thumbnail, 'thumbnail')

    run_cleanup

    expect(files.first).not_to exist
    expect(thumbnail).not_to exist
    expect(page.reload.image).to be_attached
    expect(blobs.first.service.exist?(blobs.first.key)).to be true
    expect(page.base_image).to eq(files.first.to_s)
    task.reenable
    expect { run_cleanup }.not_to raise_error
  end

  it 'keeps files for pages without an attachment or without an uploaded object' do
    legacy_page(attached: false)
    legacy_page(stored: false)
    run_cleanup
    expect(files).to all(exist)
  end

  it 'skips absent local files without contacting storage' do
    legacy_page(local: false)
    expect_any_instance_of(ActiveStorage::Service::DiskService).not_to receive(:exist?)
    run_cleanup
  end

  it 'cleans up a remaining thumbnail even if the original was already deleted' do
    legacy_page(local: false)
    thumbnail = files.first.sub('.jpg', '_thumb.jpg')
    File.write(thumbnail, 'thumbnail')
    run_cleanup
    expect(thumbnail).not_to exist
  end

  it 'resumes inclusively and verifies the connection before every batch query' do
    first = legacy_page
    second = legacy_page
    legacy_page
    connection = ActiveRecord::Base.connection
    expect(connection).to receive(:verify!).at_least(3).times.and_call_original

    expect { run_cleanup(start: second.id.to_s, batch: '1') }.to output(/next start_from_id=/).to_stdout

    expect(files.first).to exist
    expect(files.drop(1)).to all(satisfy { |path| !path.exist? })
    expect(first.id).to be < second.id
  end

  it 'fails closed on storage errors and reports a safe resume point' do
    legacy_page
    allow_any_instance_of(ActiveStorage::Service::DiskService).to receive(:exist?).and_raise(IOError, 'storage unavailable')
    expect { run_cleanup }.to raise_error(IOError, 'storage unavailable')
    expect(files.first).to exist
  end

  it 'reconnects after a real disconnect between batches', :disconnect do
    legacy_page
    legacy_page
    storage_checks = 0
    allow_any_instance_of(ActiveStorage::Service::DiskService).to receive(:exist?).and_wrap_original do |original, key|
      exists = original.call(key)
      storage_checks += 1
      ActiveRecord::Base.connection.disconnect! if storage_checks == 1
      exists
    end

    run_cleanup(batch: '1')

    expect(storage_checks).to eq(2)
    expect(files).to all(satisfy { |path| !path.exist? })
  end

  it 'limits a collection slug to pages in that collection' do
    owner = create(:unique_user, :owner)
    collection = create(:collection, owner_user_id: owner.id, works: [])
    work = create(:work, collection: collection, owner_user_id: owner.id)
    legacy_page(work_id: work.id)
    legacy_page

    run_cleanup(scope: collection.slug)

    expect(files.first).not_to exist
    expect(files.last).to exist
  end

  it 'limits a user slug to pages in works owned by that user' do
    owner = create(:unique_user, :owner)
    collection = create(:collection, owner_user_id: owner.id, works: [])
    work = create(:work, collection: collection, owner_user_id: owner.id)
    legacy_page(work_id: work.id)
    legacy_page

    run_cleanup(scope: owner.slug)

    expect(files.first).not_to exist
    expect(files.last).to exist
  end

  it 'refuses unknown or ambiguous slugs' do
    legacy_page
    expect { run_cleanup(scope: 'missing-cleanup-slug') }.to raise_error(SystemExit)
    task.reenable
    allow(User).to receive(:find_by).with(slug: 'ambiguous').and_return(double('user'))
    allow(Collection).to receive(:find_by).with(slug: 'ambiguous').and_return(double('collection'))
    expect { run_cleanup(scope: 'ambiguous') }.to raise_error(SystemExit)
    expect(files.first).to exist
  end

  it 'rejects a path outside public' do
    legacy_page(base_image: '../outside.jpg')
    expect { run_cleanup }.to raise_error(SystemExit)
    expect(files.first).to exist
  end

  it 'cleans images through shared directory symlinks used by Capistrano' do
    Dir.mktmpdir('outside-images-') do |outside|
      File.write(File.join(outside, 'image.jpg'), 'keep')
      File.symlink(outside, @directory.join('outside'))
      legacy_page(base_image: @directory.join('outside/image.jpg').to_s)
      run_cleanup
      expect(File.exist?(File.join(outside, 'image.jpg'))).to be false
    end
  end

  it 'unlinks a file symlink without deleting its target' do
    legacy_page(local: false)
    target = @directory.join('target.jpg')
    File.write(target, 'keep')
    File.symlink(target, files.first)
    run_cleanup
    expect(files.first).not_to be_symlink
    expect(target).to exist
  end

  it 'rejects missing scopes and invalid options before deleting files' do
    legacy_page
    [[nil], ['all', 'oops'], ['all', '1', '0'], ['all', '1', '1', 'FALSE']].each do |args|
      task.reenable
      expect { task.invoke(*args) }.to raise_error(SystemExit)
    end
    expect(files.first).to exist
  end
end
