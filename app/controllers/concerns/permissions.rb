# Explicit, per-action permission checks.
#
# Every action in a controller that opts in with `enforce_permission_checks` should call
# `require_permission` before reading or changing anything sensitive:
#
#   def destroy
#     require_permission(:collection_owner, @collection)
#     ...
#   end
#
# The rule: load the record (through its parent), then call `require_permission`, then
# change things. Only record loading may happen before the check.
#
# Permissions are a fixed vocabulary (PERMISSIONS below), with no DB-backed roles. The
# logic behind each one lives in app/lib/permissions/*_rules.rb.
#   :allow   - intentionally public
#   :pending - permission not decided yet; passes, but logs a warning
#
# Admins pass every permission except :disallow (see #admin_bypass?).
#
# Where a denied user is sent, most specific first:
#
#   Signed in:
#     1. per call:        require_permission(..., redirect_to: some_path)
#     2. per controller:  override #permission_denied_redirect(record)
#     3. default:         the record's public page (Page / Work / DocumentSet / Collection)
#                         if the user can view it, otherwise the dashboard
#
#   Signed out (keeps whatever each controller does today):
#     1. per call:        require_permission(..., signed_out_redirect_to: new_user_session_path)
#     2. per controller:  override #permission_signed_out_redirect
#     3. default:         the dashboard (what most existing checks do)
module Permissions
  extend ActiveSupport::Concern

  # Carries everything the handler needs, so nothing is kept in instance variables.
  class AccessDenied < StandardError
    attr_reader :permission, :record, :redirect, :signed_out_redirect

    def initialize(permission:, record: nil, redirect: nil, signed_out_redirect: nil)
      @permission = permission
      @record = record
      @redirect = redirect
      @signed_out_redirect = signed_out_redirect
      super("Permission #{permission.inspect} denied")
    end
  end

  # (user, record, **context) -> true / false
  PERMISSIONS = {
    allow: ->(_user, _record, **) { true },
    pending: ->(_user, _record, **) { true },
    disallow: ->(_user, _record, **) { false },
    signed_in: ->(user, _record, **) { UserRules.signed_in?(user) },
    admin: ->(user, _record, **) { UserRules.admin?(user) },
    owner_account: ->(user, _record, **) { UserRules.owner_account?(user) },
    collection_owner: ->(user, record, **) { RecordRules.owner?(user, record) },
    collection_reviewer: ->(user, record, **) { CollectionRules.reviewer?(user, record) },
    collection_transcriber: ->(user, record, collection: nil, **) { WorkRules.transcriber?(user, record, collection) },
    collection_viewer: ->(user, record, **) { RecordRules.viewer?(user, record) },
    self: ->(user, record, **) { UserRules.same_user?(user, record) },
    author_or_collection_owner: lambda { |user, record, collection_object:, **|
      UserRules.author?(user, record) || RecordRules.owner?(user, collection_object)
    },
    author: ->(user, record, **) { UserRules.author?(user, record) }
  }.freeze

  # Permissions that need a record. Called with nil, they deny the request (and log an error)
  # rather than quietly allow it. This applies to admins too.
  RECORD_REQUIRED = [
    :collection_owner,
    :collection_reviewer,
    :collection_transcriber,
    :collection_viewer,
    :self,
    :author_or_collection_owner,
    :author
  ].freeze

  # Permissions admins don't bypass.
  ADMIN_BYPASS_EXCLUDED = [:disallow].freeze

  # Spec-suite summary of :pending and missing checks (spec/support/permissions.rb).
  # Only collected in the test environment.
  def self.warnings
    @warnings ||= Set.new
  end

  def self.report(message)
    warnings << message if Rails.env.test?
  end

  included do
    rescue_from Permissions::AccessDenied, with: :access_denied
  end

  class_methods do
    # Opts this controller in to the "did every action call require_permission?" check.
    # Warn-only: it logs, it never raises and never fails a spec.
    def enforce_permission_checks(**filter_options)
      after_action :warn_if_permission_unchecked, **filter_options
    end
  end

  private

  # redirect_to:            optional per-call override for a denied *signed-in* user
  # signed_out_redirect_to: optional per-call override for a denied *signed-out* user
  # Both accept anything `redirect_to` accepts (path, URL, hash, record).
  def require_permission(permission, record = nil, redirect_to: nil, signed_out_redirect_to: nil, **context)
    check = PERMISSIONS.fetch(permission) do
      raise ArgumentError, "Unknown permission #{permission.inspect}. See Permissions::PERMISSIONS"
    end
    @permission_checked = permission

    log_permission_warning('is :pending a permission decision') if permission == :pending

    deny = lambda do
      raise AccessDenied.new(permission:, record:, redirect: redirect_to, signed_out_redirect: signed_out_redirect_to)
    end

    # Order matters:
    #   1. a nil record is a loading bug, so deny everyone, admins included
    #   2. admins pass everything except ADMIN_BYPASS_EXCLUDED
    #   3. everyone else goes through the rule
    if RECORD_REQUIRED.include?(permission) && record.nil?
      Rails.logger.error("[permissions] #{endpoint_name} required #{permission.inspect} with a nil record; denying")
      deny.call
    end

    return if admin_bypass?(permission)

    deny.call unless check.call(current_user, record, **context)
  end

  # While an admin masquerades, current_user is the masqueraded user, so the bypass doesn't
  # apply. The admin sees exactly what that user would see.
  def admin_bypass?(permission)
    UserRules.admin?(current_user) && !ADMIN_BYPASS_EXCLUDED.include?(permission)
  end

  def warn_if_permission_unchecked
    return if @permission_checked

    log_permission_warning('did not call require_permission')
  end

  def log_permission_warning(message)
    text = "[permissions] #{endpoint_name} #{message}"
    Rails.logger.warn(text)
    Permissions.report(text)
  end

  def endpoint_name
    "#{self.class.name}##{action_name}"
  end

  # All request types resolve the same target (#denial_target). Only the response differs:
  #
  #   legacy XHR (jQuery $.ajax / jquery_ujs) -> ajax_redirect_to target: `201 Created` + `Location`,
  #                                              no flash, same as today's hand-written checks
  #   HTML / Turbo                            -> 303 redirect to target (Turbo follows a 303 after
  #                                              POST/PATCH/DELETE), with a flash when signed in
  #   anything else (JSON, ...)               -> plain 401 / 403
  def access_denied(denial)
    target = denial_target(denial)

    return ajax_redirect_to(target) if legacy_xhr_request?

    respond_to do |format|
      format.any(:html, :turbo_stream) do
        flash[:error] = t('permission_denied') if user_signed_in?
        redirect_to target, status: :see_other
      end
      format.any { head denied_status }
    end
  end

  def denial_target(denial)
    # Signed out: keep today's behaviour. No flash and no stored return-to, since the
    # existing hand-written checks set neither.
    return denial.signed_out_redirect || permission_signed_out_redirect unless user_signed_in?

    target = denial.redirect || permission_denied_redirect(denial.record)
    redirect_loop?(target) ? dashboard_path : target
  end

  # Controller-level override for signed-in denials. Override it to change the target for
  # every action in a controller, and call `super` to fall back to the default.
  #
  #   def permission_denied_redirect(record)
  #     record.is_a?(Collection) ? edit_collection_path(record.owner, record) : super
  #   end
  def permission_denied_redirect(record)
    default_denied_redirect(record)
  end

  # Controller-level override for signed-out denials. The default matches most existing
  # checks. Controllers that send signed-out users to sign-in today (TranscribeController,
  # QualitySamplingsController) override this when they're migrated:
  #
  #   def permission_signed_out_redirect
  #     new_user_session_path
  #   end
  def permission_signed_out_redirect
    dashboard_path
  end

  # The default is chosen by the record's type. The user goes to the record's public page
  # only if they can view it, otherwise to the dashboard. That avoids a second bounce
  # through `authorize_collection` for private collections.
  def default_denied_redirect(record)
    collection = denial_collection_for(record)
    return dashboard_path unless collection && RecordRules.viewer?(current_user, collection)

    case record
    when Page then collection_display_page_path(collection.owner, collection, record.work, record)
    when Work then collection_read_work_path(collection.owner, collection, record)
    when DocumentSet, Collection then collection_path(record.owner, record)
    else dashboard_path
    end
  end

  # The Collection or DocumentSet whose visibility decides the default redirect.
  def denial_collection_for(record)
    case record
    when Page then record.work&.collection
    when Work then record.collection
    when DocumentSet, Collection then record
    end
  end

  # Never redirect back to the URL that was just denied (e.g. a denied GET on the
  # collection page itself). The caller falls back to the dashboard instead.
  def redirect_loop?(target)
    target.is_a?(String) && URI.parse(target).path == request.path
  rescue URI::InvalidURIError
    false
  end

  # Only for non-HTML, non-XHR formats (JSON etc.).
  def denied_status
    user_signed_in? ? :forbidden : :unauthorized
  end

  # jQuery $.ajax / jquery_ujs requests. Turbo's fetch doesn't send X-Requested-With, so this
  # only matches the legacy calls.
  # TODO: Remove this, and the ajax_redirect_to branch in #access_denied, once the field
  # editor no longer uses XHR.
  def legacy_xhr_request?
    request.xhr?
  end
end
