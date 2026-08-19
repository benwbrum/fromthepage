require 'open-uri'
require 'contentdm_translator'
require 'shellwords'

class ScCollectionsController < ApplicationController
  before_action :set_sc_collection, only: %i[show edit update destroy explore_manifest import_manifest]
  before_action :require_authenticated_user, only: %i[import_collection convert_manifest cdm_bulk_import_new cdm_bulk_import_create]

  respond_to :html

  def index
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
    respond_with(@sc_collections)
  end

  def cdm_bulk_import_new; end

  def cdm_bulk_import_create
    import = CdmBulkImport.new
    import.collection_param = params[:collection_id]
    import.ocr_correction = params[:ocr_correction]
    import.generate_ai_draft = params[:generate_ai_draft]
    import.user = current_user
    clean_urls = params[:cdm_urls].gsub(/\s+/m, "\n")
    import.cdm_urls = clean_urls
    import.save!

    import.submit_background_task

    flash[:info] = t('.import_started', email: current_user.email)
    redirect_to dashboard_owner_path
  end

  def import_cdm
    cdm_url = params[:cdm_url]

    if cdm_url.blank?
      flash[:error] = t('.please_enter_url')
      redirect_back fallback_location: { action: 'import' }
      return
    end

    begin
      at_id = ContentdmTranslator.cdm_url_to_iiif(cdm_url)
      flash[:notice] = t('.using_manifest_for', url: cdm_url)
      if @collection
        redirect_to action: :import, at_id: at_id, source: 'contentdm', source_url: cdm_url,
                    collection_id: @collection.slug
      else
        redirect_to action: :import, at_id: at_id, source: 'contentdm', source_url: cdm_url
      end
    rescue StandardError => e
      logger.error t('.bad_contentdm_url', url: cdm_url, message: e.message)
      flash[:error] = e.message
      redirect_back fallback_location: { action: 'import' }
    end
  end

  def import
    at_id = params[:at_id].strip

    begin
      version = detect_version(at_id)
      if version == 2
        service = find_service(at_id)

        if service['@type'] == 'sc:Collection'
          @sc_collection = ScCollection.collection_for_at_id(at_id)
          @collection = set_collection

          render 'explore_collection', at_id: at_id
        elsif service['@type'] == 'sc:Manifest'
          @sc_manifest = ScManifest.manifest_for_at_id(at_id)
          find_parent = @sc_manifest.service['within']
          if find_parent.nil? || !find_parent.is_a?(Hash)
            @sc_collection = nil
          else
            parent_at_id = @sc_manifest.service['within']['@id']
            @sc_collection = (ScCollection.collection_for_at_id(parent_at_id) unless parent_at_id.nil?)
          end
          # this allows jquery to recover if there is no parent collection
          if @sc_collection
            @label = @sc_collection.label
            @col = @sc_collection.collection
          else
            @label = nil
            @col = nil
          end
          render 'explore_manifest', at_id: at_id
        end
      elsif version == 3
        manifest = JSON.parse(fetch_manifest(at_id))
        if manifest['type'] == 'Collection'
          @sc_collection = ScCollection.collection_for_v3_hash(manifest)
          @collection = set_collection
          render 'explore_collection', at_id: at_id
        elsif manifest['type'] == 'Manifest'
          @sc_manifest = ScManifest.manifest_for_v3_hash(manifest)
          @sc_collection = nil # TODO: figure out within partOf
          @label = nil # TODO
          @col = nil # TODO
          render 'explore_manifest', at_id: at_id
        end

      end
    rescue StandardError => e
      logger.error(e.message + "\n\n" + e.backtrace.join("\n"))
      flash[:error] = case params[:source]
      when 'contentdm'
                        t('.no_manifest_exist', url: params[:source_url])
      else
                        t('.please_enter_valid_url')
      end
      redirect_back fallback_location: { action: 'import' }
    end
  end

  def explore_manifest
    at_id = params[:at_id]
    version = detect_version(at_id)

    begin
      @sc_manifest = if version == 3
                       ScManifest.manifest_for_v3_hash(fetch_manifest(at_id))
      else
        ScManifest.manifest_for_at_id(at_id)
      end
    rescue ArgumentError
      redirect_to action: 'explore_collection', at_id: at_id
      return
    end
    @collection = set_collection
    if @sc_collection
      @label = @sc_collection.label
      @col = @sc_collection.collection
    else
      @label = nil
      @col = nil
    end
  end

  def explore_collection
    at_id = params[:at_id]
    version = detect_version(at_id)

    if version == 3
      manifest = JSON.parse(fetch_manifest(at_id))
      @sc_collection = ScCollection.collection_for_v3_hash(manifest)
    else
      @sc_collection = ScCollection.collection_for_at_id(at_id)
    end
    @collection = set_collection
  end

  def import_collection
    sc_collection = ScCollection.find_by(id: params[:sc_collection_id])
    collection_id = params[:collection_id]
    cdm_ocr = !params[:contentdm_ocr].blank?
    annotation_ocr = !params[:annotation_ocr].blank?
    generate_ai_draft = !params[:generate_ai_draft].blank?
    import_ocr = cdm_ocr || annotation_ocr

    # if collection id is set to sc_collection or no collection is set,
    # create a new collection with sc_collection label
    if collection_id == 'sc_collection'
      collection = create_collection(sc_collection, current_user)
      collection_id = collection.id
    end

    if collection_id.is_a?(String) && (md = collection_id.match(/D(\d+)/))
      document_set = DocumentSet.find_by(id: md[1])
      collection = document_set.collection
    else
      collection = Collection.find_by(id: collection_id)
    end

    unless collection && current_user.like_owner?(collection)
      redirect_to dashboard_path
      return
    end

    # make sure import folder exists
    Dir.mkdir("#{Rails.root}/public/imports") unless Dir.exist?("#{Rails.root}/public/imports")
    # create logfile for collection
    log_file = "#{Rails.root}/public/imports/#{collection_id}_iiif.log"

    # map an array of at_ids for the selected manifests
    manifest_array = params.require(:manifest_id).keys.map(&:to_s)
    # get a list of the manifests to pass to the rake task
    manifest_ids = manifest_array.join(' ')
    # kick off the rake task here, then redirect to the collection
    task = "fromthepage:import_iiif_collection[#{sc_collection.id},#{manifest_ids},#{collection_id},#{current_user.id},#{import_ocr},#{generate_ai_draft}]"
    command = Shellwords.split(RAKE) + [task, '--trace']
    command = ['nice', '-n', NICE_RAKE_LEVEL.to_s] + command if NICE_RAKE_ENABLED

    logger.info command.shelljoin
    pid = Process.spawn(*command, out: [log_file, 'a'], err: [:child, :out])
    Process.detach(pid)
    # flash notice about the rake task
    flash[:notice] = t('.import_is_processing')

    ajax_redirect_to collection_path(collection.owner, collection)
  end

  def create_collection(sc_collection, current_user)
    collection = Collection.new
    collection.owner = current_user
    collection.title = sc_collection.label.truncate(255, separator: ' ', omission: '')
    collection.save!
    sc_collection.update_column(:collection_id, collection.id)
    collection
  end

  def convert_manifest
    at_id = params[:at_id]
    annotation_ocr = !params[:annotation_ocr].blank?
    generate_ai_draft = !params[:generate_ai_draft].blank?
    version = detect_version(at_id)
    @sc_manifest = if version == 3
                     ScManifest.manifest_for_v3_hash(fetch_manifest(at_id))
    else
      ScManifest.manifest_for_at_id(at_id)
    end
    work = nil
    if params[:sc_manifest][:collection_id] == 'sc_collection'
      set_sc_collection
      work = @sc_manifest.convert_with_sc_collection(current_user, @sc_collection, annotation_ocr)
    else
      collection_id = params[:sc_manifest][:collection_id]
      if collection_id.blank?
        work = @sc_manifest.convert_with_no_collection(current_user, annotation_ocr)
      else
        document_set = nil
        if md = collection_id.match(/D(\d+)/)
          document_set = DocumentSet.find_by(id: md[1])
          @collection = document_set.collection
        else
          @collection = Collection.find_by(id: collection_id)
        end
        work = @sc_manifest.convert_with_collection(current_user, @collection, document_set, annotation_ocr)
      end
    end
    if ContentdmTranslator.iiif_manifest_is_cdm? at_id
      ocr = !params[:contentdm_ocr].blank?
      # make sure import folder exists
      Dir.mkdir("#{Rails.root}/public/imports") unless Dir.exist?("#{Rails.root}/public/imports")

      log_file = "#{Rails.root}/public/imports/work_#{work.id}_cdm.log"
      rake_call = "#{RAKE} fromthepage:cdm_work_update[#{work.id},#{ocr}] --trace >> #{log_file} 2>&1 &"
      logger.info rake_call
      system(rake_call)
      # flash notice about the rake task
      ocr_text = ocr ? 'and OCR text ' : ''
      flash[:notice] = t('.metadata_is_being_imported', ocr_text: ocr_text)
    end

    # Trigger AI Draft generation if requested
    if generate_ai_draft
      # make sure import folder exists
      Dir.mkdir("#{Rails.root}/public/imports") unless Dir.exist?("#{Rails.root}/public/imports")

      log_file = "#{Rails.root}/public/imports/work_#{work.id}_ai_draft.log"
      rake_call = "#{RAKE} fromthepage:gemini:transcribe_work[#{work.id}] --trace >> #{log_file} 2>&1 &"
      logger.info rake_call
      system(rake_call)
      flash[:notice] = (flash[:notice] || '') + ' AI Draft text generation has been started.'
    end

    if @collection.text_entry?
      redirect_to collection_read_work_path(@collection.owner, @collection, work)
    else
      redirect_to describe_collection_work_path(@collection.owner, @collection, work)
    end
  end

  def show
    respond_with(@sc_collection)
  end

  def new
    @sc_collection = ScCollection.new
    respond_with(@sc_collection)
  end

  def edit; end

  def create
    @sc_collection = ScCollection.new(sc_collection_params)
    @sc_collection.save
    respond_with(@sc_collection)
  end

  def update
    @sc_collection.update(sc_collection_params)
    respond_with(@sc_collection)
  end

  def destroy
    @sc_collection.destroy
    respond_with(@sc_collection)
  end

  private

  def require_authenticated_user
    redirect_to dashboard_path unless user_signed_in?
  end

  def set_sc_collection
    id = params[:sc_collection_id] || params[:id]
    #      @sc_collection = ScCollection.find(id)
    @sc_collection = ScCollection.find_by id: id
  end

  def sc_collection_params
    params.require(:sc_collection).permit(:collection_id, :context)
  end

  def set_collection
    # used to add new collections to select box on import
    if session[:iiif_collection]
      @collection = Collection.find_by(id: session[:iiif_collection])
      session[:iiif_collection] = nil
      @collection
    else
      @collection
    end
  end

  def find_service(at_id)
    manifest_json = fetch_manifest(at_id)
    IIIF::Service.parse(manifest_json)
  end

  V3_CONTEXT = 'http://iiif.io/api/presentation/3/context.json'
  V2_CONTEXT = 'http://iiif.io/api/presentation/2/context.json'
  def detect_version(at_id)
    manifest = JSON.parse(fetch_manifest(at_id))
    context = manifest['@context']

    return 3 if context.nil?

    if context.is_a? Array
      if context.include? V2_CONTEXT
        2
      elsif context.include? V3_CONTEXT
        3
      end
    elsif context == V2_CONTEXT
      2
    elsif context == V3_CONTEXT
      3
    end
  end

  def fetch_manifest(at_id)
    if @raw_manifest.nil?
      # Set OpenSSL flag to ignore unexpected EOF (for OpenSSL 3.0 compatibility)
      if OpenSSL::SSL.const_defined?(:OP_IGNORE_UNEXPECTED_EOF)
        OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_IGNORE_UNEXPECTED_EOF
      end

      # Custom headers to avoid SSL/compression issues with OpenSSL 3.0
      options = {
        'Accept-Encoding' => 'identity', # Disable compression to avoid inflater path
        'User-Agent' => 'FromThePage-IIIF/1.0',
        'Connection' => 'close',
        open_timeout: 10,
        read_timeout: 20,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER
      }

      # Retry logic for SSL/EOF errors common with OpenSSL 3.0
      attempts = 0
      begin
        uri = URI.parse(at_id)
        raise ArgumentError, 'manifest URL must use HTTP or HTTPS' unless uri.is_a?(URI::HTTP)

        @raw_manifest = uri.open(options).read
      rescue OpenSSL::SSL::SSLError, EOFError => e
        attempts += 1
        retry if attempts < 2
        raise e
      end
    end
    @raw_manifest
  end
end
