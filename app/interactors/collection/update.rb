class Collection::Update < ApplicationInteractor
  attr_accessor :collection

  def initialize(collection:, collection_params:, user:)
    @collection        = collection
    @collection_params = collection_params
    @user              = user

    super
  end

  def perform
    ActiveRecord::Base.transaction do
      set_subjects_enabled
      set_data_entry_type
      set_slug
      set_messageboards
      toggle_active
      toggle_fields
      set_tags

      @collection.attributes = @collection_params
      @collection.save!
    end
  end

  private

  def set_subjects_enabled
    return unless @collection_params[:subjects_enabled].present?

    subjects_enabled = ActiveRecord::Type::Boolean.new.cast(@collection_params[:subjects_enabled])
    @collection_params[:subjects_disabled] = !subjects_enabled
    @collection_params.delete(:subjects_enabled)
  end

  def set_data_entry_type
    return unless @collection_params[:data_entry_type].present?

    @collection_params[:data_entry_type] = if ActiveRecord::Type::Boolean.new.cast(@collection_params[:data_entry_type])
                                             Collection::DataEntryType::TEXT_AND_METADATA
                                           else
                                             Collection::DataEntryType::TEXT_ONLY
                                           end
  end

  def set_slug
    return if @collection_params[:slug].present?

    @collection_params[:slug] = @collection.title.parameterize
  end

  def set_messageboards
    return unless @collection_params[:messageboards_enabled].present?

    messageboards_enabled = ActiveRecord::Type::Boolean.new.cast(@collection_params[:messageboards_enabled])

    return if !messageboards_enabled ||
              messageboards_enabled == @collection.messageboards_enabled ||
              @collection.messageboard_group.present?

    @collection.messageboard_group = Thredded::MessageboardGroup.find_or_create_by!(name: @collection.title)

    Thredded::Messageboard.find_or_create_by!(name: 'General', description: 'General discussion',
                                              messageboard_group_id: @collection.messageboard_group.id)
    Thredded::Messageboard.find_or_create_by!(name: 'Help', messageboard_group_id: @collection.messageboard_group.id)
  end

  def toggle_active
    return unless @collection_params[:is_active].present?

    is_active = ActiveRecord::Type::Boolean.new.cast(@collection_params[:is_active])

    return if is_active == @collection.is_active

    Deed.create!(
      collection_id: @collection.id,
      user_id: @user.id,
      deed_type: is_active ? DeedType::COLLECTION_ACTIVE : DeedType::COLLECTION_INACTIVE
    )
  end

  def toggle_fields
    is_field_based = ActiveRecord::Type::Boolean.new.cast(@collection_params[:field_based])

    return unless is_field_based && !@collection.field_based

    @collection_params[:field_based] = true
    @collection_params[:voice_recognition] = false
    @collection_params[:language] = nil
  end

  def set_tags
    return unless @collection_params[:tags].present?

    tag_ids = @collection_params.delete(:tags)

    tags = Tag.where(id: tag_ids)
    @collection.tags = tags
  end
end
