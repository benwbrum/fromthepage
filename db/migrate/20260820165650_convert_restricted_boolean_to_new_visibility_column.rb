class ConvertRestrictedBooleanToNewVisibilityColumn < ActiveRecord::Migration[7.2]
  def up
    Collection.where(restricted: true)
              .update_all(visibility: :private)

    # NOTE: This is implied, since default value is public.
    # Collection.where(restricted: false)
    #           .update_all(visibility: :public)
  end

  def down
    Collection.where(visibility: [:private, :read_only])
              .update_all(restricted: true)

    Collection.where(visibility: [:public])
              .update_all(restricted: false)
  end
end
