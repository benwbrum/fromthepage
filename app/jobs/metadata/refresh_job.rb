class Metadata::RefreshJob < ApplicationJob
  queue_as :default

  def perform(id:, type:, user_id:)
    @refresh_logs = []
    @id = id
    @type = type
    @user = User.find_by(id: user_id)

    FileUtils.mkdir_p(Rails.root.join('public', 'metadata', 'refresh', 'log'))

    @result = Work::Metadata::Refresh.new(work_ids: all_work_ids).call

    if @result.success?
      log('Updated metadata successfully!')
    else
      log('Refresh metadata finished with errors')
    end

    @refresh_logs.concat(@result.logs)
  rescue ArgumentError => e
    log(e.message)
  ensure
    File.write(log_file, @refresh_logs.join("\n"))

    send_email
  end

  private

  def all_work_ids
    return @all_work_ids if defined?(@all_work_ids)

    case @type
    when 'collection'
      @object = Collection.find_by(id: @id)
      raise ArgumentError, "Collection with id=#{@id} does not exist." if @object.nil?

      log("Refreshing metadata for works in collection #{@id}")

      @all_work_ids = @object.works.pluck(:id)
    when 'document_set'
      @object = DocumentSet.find_by(id: @id)
      raise ArgumentError, "Document Set with id=#{@id} does not exist." if @object.nil?

      log("Refreshing metadata for works in document_set #{@id}")

      @all_work_ids = @object.works.pluck(:id)
    when 'work'
      @object = Work.find_by(id: @id)
      raise ArgumentError, "Work with id=#{@id} does not exist." if @object.nil?

      log("Refreshing metadata for work #{@id}")

      @all_work_ids = [@id]
    else
      raise ArgumentError, 'Type can only be collection, document_set, or work'
    end

    @all_work_ids
  end

  def log(text)
    @refresh_logs << text
  end

  def log_file
    @log_file ||=
      Rails.root.join(
        'public',
        'metadata',
        'refresh',
        'log',
        "#{@id}_#{Time.current.to_i}_refresh_#{@type}.log"
      )
  end

  def send_email
    return unless SMTP_ENABLED

    @user ||= @object&.owner

    return if @user.nil?

    UserMailer.metadata_refresh_finished(@user, @result, @id, @type, @refresh_logs).deliver!

    # :nocov:
  rescue StandardError => e
    log("SMTP Failed: Exception: #{e.message}")
    # :cov:
  end
end
