module Api::V1
  class BulkExportController < ApplicationController

    before_action :set_api_user
    skip_before_action :verify_authenticity_token

    # list your bulk exports
    def index
      if @api_user
        collection_slug = params[:collection_slug]
        if collection_slug
          collection = Collection.where(slug: collection_slug).first
          if collection.nil?
            render status: :not_found, json: "No collection exists with the slug #{collection_slug}"
            return
          end
          exports = @api_user.bulk_exports.where(collection_id: collection.id)
        else
          exports = @api_user.bulk_exports
        end
        render json: exports.to_json(except: [:updated_at, :user_id, :collection_id], include: { collection: { only: [:title, :slug] } })
      else
        render status: :unauthorized, json: 'You must use an API token to access bulk exports'
      end
    end

    def start
      if @api_user
        collection_slug = params[:collection_slug]
        if collection_slug
          collection = Collection.where(slug: collection_slug).first
          if collection.nil?
            render status: :not_found, json: "No collection exists with the slug #{collection_slug}"
            return
          end

          if collection.show_to?(@api_user)
            # try to parse the bulk_export
            bulk_export = BulkExport.new
            bulk_export.collection = collection
            bulk_export.user = @api_user
            bulk_export.status = BulkExport::Status::NEW
            bulk_export.plaintext_verbatim_page = params[:plaintext_verbatim_page].present?
            bulk_export.plaintext_verbatim_work = params[:plaintext_verbatim_work].present?
            bulk_export.plaintext_emended_page = params[:plaintext_emended_page].present?
            bulk_export.plaintext_emended_work = params[:plaintext_emended_work].present?
            bulk_export.plaintext_searchable_page = params[:plaintext_searchable_page].present?
            bulk_export.plaintext_searchable_work = params[:plaintext_searchable_work].present?
            bulk_export.tei_work = params[:tei_work].present?
            bulk_export.html_page = params[:html_page].present?
            bulk_export.html_work = params[:html_work].present?
            bulk_export.subject_csv_collection = params[:subject_csv_collection].present?
            bulk_export.subject_details_csv_collection = params[:subject_details_csv_collection].present?
            bulk_export.table_csv_collection = params[:table_csv_collection].present?
            bulk_export.table_csv_work = params[:table_csv_work].present?
            bulk_export.notes_csv = params[:notes_csv].present?
            bulk_export.save
            bulk_export.submit_export_process

            response = {
              id: bulk_export.id,
              status: bulk_export.status,
              status_uri: api_v1_bulk_export_status_url(bulk_export.id),
              download_uri: api_v1_bulk_export_download_url(bulk_export.id)
            }

            render status: :accepted, json: response.to_json

          else
            render status: :forbidden, json: "User #{@api_user} is not authorized to view #{collection.title}"
          end
        else
          render status: :unauthorized, json: 'You must use a collection slug in the URL to create a bulk export'
        end
      else
        render status: :unauthorized, json: 'You must use an API token to access bulk exports'
      end
    end

    def status
      if @api_user
        bulk_export_id = params[:bulk_export_id]
        if bulk_export_id
          bulk_export = @api_user.bulk_exports.where(id: bulk_export_id).first
          if bulk_export
            response = {
              id: bulk_export.id,
              status: bulk_export.status,
              status_uri: api_v1_bulk_export_status_url(bulk_export.id),
              download_uri: api_v1_bulk_export_download_url(bulk_export.id)
            }
            render status: :ok, json: response.to_json
          else
            render status: :forbidden, json: "User #{@api_user} has no bulk export with ID #{bulk_export_id}"
          end
        else
          render status: :unauthorized, json: 'You must use a bulk export ID in the URL'
        end
      else
        render status: :unauthorized, json: 'You must use an API token to access bulk exports'
      end
    end

    def download
      if @api_user
        bulk_export_id = params[:bulk_export_id]
        if bulk_export_id
          bulk_export = @api_user.bulk_exports.where(id: bulk_export_id).first
          if bulk_export
            if bulk_export.status == BulkExport::Status::FINISHED
              send_file(bulk_export.zip_file_name,
                filename: 'fromthepage_export.zip',
                content_type: 'application/zip')
            elsif bulk_export.status == BulkExport::Status::CLEANED
              render status: :gone, json: "Bulk export #{bulk_export_id} has been deleted.  Please start a new export."
            elsif bulk_export.status == BulkExport::Status::ERROR
              render status: :gone,
                json: "Bulk export #{bulk_export_id} failed with an error.  " \
                      'Please report this to support.  ' \
                      'Re-running an export with different requested formats might succeed.'
            else
              render status: :conflict,
                json: "Bulk export #{bulk_export_id} is not ready to download.  " \
                      'It is probably still running, but might have failed with an un-caught error.'
            end
          else
            render status: :forbidden, json: "User #{@api_user} has no bulk export with ID #{bulk_export_id}"
          end
        else
          render status: :unauthorized, json: 'You must use a bulk export ID in the URL'
        end
      else
        render status: :unauthorized, json: 'You must use an API token to access bulk exports'
      end
    end

  end
end
