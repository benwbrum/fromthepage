class IaController < ApplicationController
  require 'open-uri'
  include ActiveModel::Validations

  before_action :load_ia_work_from_params

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
    flash[:notice] = t('.converted_to_work', title: @ia_work.title)

    unless params[:collection_id].blank?
      work.collection = @collection
      work.save!
    else
      # collection is required, but if something goes wrong due to browser version, create a collection
      collection = Collection.new
      collection.owner = current_user
      collection.title = @ia_work.title.truncate(255, separator: ' ', omission: '')
      collection.save!
      work.collection = collection
      work.save!
    end

    redirect_to controller: 'work', action: 'edit', work_id: work.id
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

    flash[:notice] = t('.preceding_the_beginning')
    redirect_to action: 'manage', ia_work_id: @ia_work.id
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

    flash[:notice] = t('.pages_following_the_end')
    redirect_to action: 'manage', ia_work_id: @ia_work.id
  end

  def title_from_ocr_top
    @ia_work.title_from_ocr(:top)

    flash[:notice] = t('.pages_has_been_renamed')
    redirect_to action: 'manage', ia_work_id: @ia_work.id
  end

  def title_from_ocr_bottom
    @ia_work.title_from_ocr(:bottom)

    flash[:notice] = t('.pages_has_been_renamed')
    redirect_to action: 'manage', ia_work_id: @ia_work.id
  end

  def confirm_import
    @detail_url = params[:detail_url]
    # id = detail_url.split('/').last

    if @detail_url =~ /https?:\/\/(www\.)?archive\.org\/.+/
      @detail_url.sub!(/\/mode\/.*/, '')
      @matches = IaWork.where(detail_url: @detail_url)
      if @matches.size() == 0
        # nothing to do here
        ajax_redirect_to action: 'import_work', detail_url: @detail_url
        nil
      end
    else
      errors.add(:base, t('.please_enter_valid_url'))
      render action: 'ia_book_form'
    end
  end

  def import_work
    detail_url = params[:detail_url]
    id = detail_url.sub(/.*archive.org\/details\//, '').sub(/\/.*/, '')

    # pull relevant info about the work from here
    @ia_work = IaWork.new
    @ia_work.user = current_user
    @ia_work.detail_url = detail_url
    @ia_work.ingest_work(id)

    flash[:notice] = t('.imported_into_staging', title: @ia_work.title)
    ajax_redirect_to action: 'manage', ia_work_id: @ia_work.id
  end
end
