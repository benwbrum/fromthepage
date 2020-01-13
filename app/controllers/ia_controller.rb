class IaController < ApplicationController
  require 'open-uri'
  include ActiveModel::Validations

  before_action :load_ia_work_from_params

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:ia_book_form, :confirm_import]

  def load_ia_work_from_params
    unless params[:ia_work_id].blank?
      @ia_work = IaWork.find(params[:ia_work_id])
    end
  end

  def manage
    @ia_leaves = @ia_work.ia_leaves.paginate(page: params[:page], per_page: 5)
  end

  def convert
    if params[:use_ocr]
      @ia_work.use_ocr = true
      @ia_work.save!
    end

    work = @ia_work.convert_to_work
    flash[:notice] = "#{@ia_work.title} has been converted into a FromThePage work"

    unless params[:collection_id].blank?
      work.collection = @collection
      work.save!
    else
      #collection is required, but if something goes wrong due to browser version, create a collection
      collection = Collection.new
      collection.owner = current_user
      collection.title = @ia_work.title.truncate(255, separator: ' ', omission: '')
      collection.save!
      work.collection = collection
      work.save!
    end

    redirect_to :controller => 'work', :action => 'edit', :work_id => work.id
  end


  def mark_beginning
    beginning_leaf = IaLeaf.find(params[:ia_leaf_id])

    # delete all leaves preceding this leaf
    target_leaves = []
    accumulation_mode=true
    @ia_work.ia_leaves.each do |leaf|
      if leaf == beginning_leaf
        accumulation_mode = false
      end
      if accumulation_mode
        target_leaves << leaf
      end
    end

    target_leaves.each { |leaf| leaf.destroy }

    flash[:notice] = "Pages preceding the beginning of the text have been concealed"
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

  def mark_end
    end_leaf = IaLeaf.find(params[:ia_leaf_id])

    # delete all leaves preceding this leaf
    target_leaves = []
    accumulation_mode=false
    @ia_work.ia_leaves.each do |leaf|
      if accumulation_mode
        target_leaves << leaf
      end
      if leaf == end_leaf
        accumulation_mode = true
      end
    end

    target_leaves.each { |leaf| leaf.destroy }

    flash[:notice] = "Pages following the end of the text have been concealed"
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

  def title_from_ocr_top
    @ia_work.title_from_ocr(:top)

    flash[:notice] = "Pages have been renamed with the top line of OCR text"
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

  def title_from_ocr_bottom
    @ia_work.title_from_ocr(:bottom)

    flash[:notice] = "Pages have been renamed with the bottom line of OCR text"
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

  def confirm_import
    @detail_url = params[:detail_url]
    #id = detail_url.split('/').last

    if @detail_url =~ /https?:\/\/(www\.)?archive\.org\/.+/
      @matches = IaWork.where(:detail_url => @detail_url)
      if @matches.size() == 0
        # nothing to do here
        ajax_redirect_to :action => 'import_work', :detail_url => @detail_url
        return
      end
    else
      errors.add(:base, "Please enter a valid Archive.org book URL to import")
      render :action => 'ia_book_form'
    end
  end

  def import_work
    detail_url = params[:detail_url]
    id = detail_url.split('/').last

    # pull relevant info about the work from here
    @ia_work = IaWork.new
    @ia_work.user = current_user
    @ia_work.detail_url = detail_url
    @ia_work.ingest_work(id)

    flash[:notice] = "#{@ia_work.title} has been imported into your staging area"
    ajax_redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

end
