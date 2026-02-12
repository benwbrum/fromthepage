class Work::Create < ApplicationInteractor
  attr_accessor :work

  def initialize(work_params:, user:)
    @work_params = work_params
    @user = user

    super
  end

  def perform
    ActiveRecord::Base.transaction do
      @work = Work.new(@work_params.except(:collection_id))

      handle_collection_id_assignment
      @work.owner = @user

      @work.save!(context: :fe_create)

      record_deed
    end
  end

  private

  def handle_collection_id_assignment
    @collection = Collection::Lib::SetFriendlyFind.perform(id: @work_params[:collection_id])

    if @collection.is_a?(DocumentSet)
      @document_set = @collection
      @collection = @document_set.collection
    end

    @work.collection_id = @collection&.id
    @work.document_set_ids = [@document_set&.id]
  end

  def record_deed
    Deed.create!(
      work_id: @work.id,
      collection_id: @work.collection_id,
      deed_type: DeedType::WORK_ADDED,
      user_id: @user.id
    )
  end
end
