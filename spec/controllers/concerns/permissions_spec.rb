require 'spec_helper'

# Unit spec for the Permissions concern. Calls the private API on a bare controller
# instance (no filters run). Response shapes (303 / XHR 201 / JSON 401) are covered by
# spec/requests/transcription_field_controller_spec.rb against a real controller.
RSpec.describe Permissions do
  let(:controller_class) do
    Class.new(ApplicationController) do
      def self.name = 'PermissionsSpecController'
    end
  end
  let(:request_path) { '/permissions-spec' }
  let(:controller) do
    controller_class.new.tap do |instance|
      instance.request = ActionDispatch::TestRequest.create('PATH_INFO' => request_path)
    end
  end
  let(:user) { nil }

  before do
    Current.user = owner
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:user_signed_in?).and_return(user.present?)
    Permissions.warnings.clear
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:private_collection) { create(:collection, :private, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:stranger) { create(:unique_user) }
  let!(:admin) { create(:unique_user, :admin) }

  def require_permission(*args, **kwargs)
    controller.send(:require_permission, *args, **kwargs)
  end

  def denial_target(**kwargs)
    controller.send(:denial_target, Permissions::AccessDenied.new(permission: :collection_owner, **kwargs))
  end

  describe '#require_permission' do
    it 'raises ArgumentError for an unknown permission' do
      expect { require_permission(:colection_owner, collection) }.to raise_error(ArgumentError, /Unknown permission/)
    end

    context 'with a signed-out user' do
      it 'passes :allow and :pending, and denies everything else' do
        expect { require_permission(:allow) }.not_to raise_error
        expect { require_permission(:pending) }.not_to raise_error
        expect { require_permission(:signed_in) }.to raise_error(Permissions::AccessDenied)
        expect { require_permission(:collection_owner, collection) }.to raise_error(Permissions::AccessDenied)
      end
    end

    context 'with a non-owner' do
      let(:user) { stranger }

      it 'passes :signed_in but not :collection_owner, :admin or :disallow' do
        expect { require_permission(:signed_in) }.not_to raise_error
        expect { require_permission(:collection_owner, collection) }.to raise_error(Permissions::AccessDenied)
        expect { require_permission(:admin) }.to raise_error(Permissions::AccessDenied)
        expect { require_permission(:disallow) }.to raise_error(Permissions::AccessDenied)
      end

      it 'checks :collection_viewer against the collection' do
        expect { require_permission(:collection_viewer, collection) }.not_to raise_error
        expect { require_permission(:collection_viewer, private_collection) }.to raise_error(Permissions::AccessDenied)
      end

      it 'checks :self and :author against the record' do
        own_note = Struct.new(:user_id).new(stranger.id)
        someone_elses_note = Struct.new(:user_id).new(owner.id)

        expect { require_permission(:self, stranger) }.not_to raise_error
        expect { require_permission(:self, owner) }.to raise_error(Permissions::AccessDenied)
        expect { require_permission(:author, own_note) }.not_to raise_error
        expect { require_permission(:author, someone_elses_note) }.to raise_error(Permissions::AccessDenied)
        expect { require_permission(:author_or_collection_owner, someone_elses_note, collection_object: collection) }
          .to raise_error(Permissions::AccessDenied)
      end
    end

    context 'with the collection owner' do
      let(:user) { owner }

      it 'passes :collection_owner for the collection and its work, but not for a Page' do
        expect { require_permission(:collection_owner, collection) }.not_to raise_error
        expect { require_permission(:collection_owner, work) }.not_to raise_error
        # Matches User#like_owner?, which returns false for record types it doesn't know.
        expect { require_permission(:collection_owner, page) }.to raise_error(Permissions::AccessDenied)
      end

      it 'passes :author_or_collection_owner through the collection' do
        someone_elses_note = Struct.new(:user_id).new(stranger.id)

        expect { require_permission(:author_or_collection_owner, someone_elses_note, collection_object: collection) }
          .not_to raise_error
      end
    end

    context 'with an admin who owns nothing' do
      let(:user) { admin }

      it 'passes every permission except :disallow' do
        record_permissions = {
          collection_owner: [collection],
          collection_reviewer: [collection],
          collection_transcriber: [work],
          collection_viewer: [private_collection],
          self: [stranger],
          author: [Struct.new(:user_id).new(stranger.id)]
        }

        (Permissions::PERMISSIONS.keys - [:disallow, :author_or_collection_owner]).each do |permission|
          args = record_permissions.fetch(permission, [])
          expect { require_permission(permission, *args) }.not_to raise_error, "expected admin to pass #{permission}"
        end
        expect { require_permission(:disallow) }.to raise_error(Permissions::AccessDenied)
      end

      it 'is still denied when a record-required permission gets nil' do
        Permissions::RECORD_REQUIRED.each do |permission|
          expect { require_permission(permission, nil) }.to raise_error(Permissions::AccessDenied)
        end
      end
    end

    it 'carries the per-call redirect overrides on the exception' do
      require_permission(:signed_in, redirect_to: '/in', signed_out_redirect_to: '/out')
    rescue Permissions::AccessDenied => e
      expect([e.redirect, e.signed_out_redirect]).to eq(['/in', '/out'])
    end
  end

  describe 'warnings (warn-only)' do
    it 'logs and records :pending without raising' do
      expect { require_permission(:pending) }.not_to raise_error
      expect(Permissions.warnings.to_a.join).to include('is :pending a permission decision')
    end

    it 'warns when an action never called require_permission' do
      controller.send(:warn_if_permission_unchecked)

      expect(Permissions.warnings.to_a.join).to include('did not call require_permission')
    end

    it 'does not warn when require_permission was called' do
      require_permission(:allow)
      controller.send(:warn_if_permission_unchecked)

      expect(Permissions.warnings).to be_empty
    end

    it 'registers the warning as an after_action only for opted-in controllers' do
      filters = ->(klass) { klass._process_action_callbacks.select { |cb| cb.kind == :after }.map(&:filter) }

      expect(filters.call(controller_class)).not_to include(:warn_if_permission_unchecked)
      controller_class.enforce_permission_checks
      expect(filters.call(controller_class)).to include(:warn_if_permission_unchecked)
    end
  end

  describe 'denied redirects' do
    context 'when signed out' do
      it 'defaults to the dashboard' do
        expect(denial_target(record: collection)).to eq(Rails.application.routes.url_helpers.dashboard_path)
      end

      it 'uses the controller override, then the per-call override' do
        controller_class.define_method(:permission_signed_out_redirect) { '/controller-signed-out' }

        expect(denial_target(record: collection)).to eq('/controller-signed-out')
        expect(denial_target(record: collection, signed_out_redirect: '/call-signed-out')).to eq('/call-signed-out')
      end

      it 'ignores the signed-in overrides' do
        expect(denial_target(record: collection, redirect: '/signed-in-only')).to eq('/dashboard')
      end
    end

    context 'when signed in' do
      let(:user) { stranger }
      let(:helpers) { Rails.application.routes.url_helpers }

      it 'defaults to the public page for each record type' do
        document_set = create(:document_set, :public, owner_user_id: owner.id, collection_id: collection.id)

        expect(denial_target(record: collection)).to eq(helpers.collection_path(owner, collection))
        expect(denial_target(record: document_set)).to eq(helpers.collection_path(document_set.owner, document_set))
        expect(denial_target(record: work)).to eq(helpers.collection_read_work_path(owner, collection, work))
        expect(denial_target(record: page)).to eq(helpers.collection_display_page_path(owner, collection, work, page))
        expect(denial_target(record: stranger)).to eq(helpers.dashboard_path)
        expect(denial_target(record: nil)).to eq(helpers.dashboard_path)
      end

      it 'falls back to the dashboard for a collection the user cannot view' do
        expect(denial_target(record: private_collection)).to eq(helpers.dashboard_path)
      end

      it 'uses the controller override (with super), then the per-call override' do
        controller_class.define_method(:permission_denied_redirect) do |record|
          record.is_a?(Collection) ? '/controller-signed-in' : super(record)
        end

        expect(denial_target(record: collection)).to eq('/controller-signed-in')
        expect(denial_target(record: work)).to eq(helpers.collection_read_work_path(owner, collection, work))
        expect(denial_target(record: collection, redirect: '/call-signed-in')).to eq('/call-signed-in')
      end

      it 'ignores the signed-out override' do
        expect(denial_target(record: collection, signed_out_redirect: '/signed-out-only'))
          .to eq(helpers.collection_path(owner, collection))
      end

      context 'when the target is the path that was just denied' do
        let(:request_path) { Rails.application.routes.url_helpers.collection_path(owner, collection) }

        it 'falls back to the dashboard' do
          expect(denial_target(record: collection)).to eq(helpers.dashboard_path)
        end
      end
    end
  end
end
