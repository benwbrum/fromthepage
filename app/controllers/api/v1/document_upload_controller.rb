module Api::V1
  class DocumentUploadController < ApplicationController
    before_action :set_api_user
    skip_before_action :verify_authenticity_token

    # Start a document upload
    # POST /api/v1/document_upload/:collection_slug
    def start
      unless @api_user
        render status: 401, json: 'You must use an API token to access document uploads'
        return
      end

      collection_slug = params[:collection_slug]
      collection_or_set = Collection::Lib::SetFriendlyFind.perform(id: collection_slug)

      if collection_or_set.nil?
        render status: 404, json: "No collection or document set exists with the slug #{collection_slug}"
        return
      end

      if collection_or_set.is_a?(DocumentSet)
        document_set = collection_or_set
        collection = document_set.collection
      else
        document_set = nil
        collection = collection_or_set
      end

      unless @api_user.like_owner?(collection)
        render status: 403, json: "User #{@api_user.login} is not authorized to upload to #{collection.title}"
        return
      end

      unless params[:file].present?
        render status: 400, json: 'A file parameter is required'
        return
      end

      document_upload = DocumentUpload.new
      document_upload.collection = collection
      document_upload.document_set = document_set
      document_upload.user = @api_user
      document_upload.ocr = ActiveModel::Type::Boolean.new.cast(params[:ocr])
      document_upload.preserve_titles = ActiveModel::Type::Boolean.new.cast(params[:preserve_titles])
      document_upload.generate_ai_draft = ActiveModel::Type::Boolean.new.cast(params[:generate_ai_draft])
      document_upload.attachment = params[:file]

      unless document_upload.save
        render status: 422, json: document_upload.errors.full_messages.to_json
        return
      end

      document_upload.submit_process

      response = {
        id: document_upload.id,
        status: document_upload.status,
        status_uri: api_v1_document_upload_status_url(document_upload.id)
      }

      render status: 202, json: response.to_json
    end

    # Get the status of a document upload
    # GET /api/v1/document_upload/:document_upload_id/status
    def status
      unless @api_user
        render status: 401, json: 'You must use an API token to access document uploads'
        return
      end

      document_upload_id = params[:document_upload_id]
      document_upload = @api_user.document_uploads.find_by(id: document_upload_id)

      if document_upload
        response = {
          id: document_upload.id,
          status: document_upload.status,
          status_uri: api_v1_document_upload_status_url(document_upload.id)
        }
        render status: 200, json: response.to_json
      else
        render status: 403, json: "User #{@api_user.login} has no document upload with ID #{document_upload_id}"
      end
    end
  end
end
