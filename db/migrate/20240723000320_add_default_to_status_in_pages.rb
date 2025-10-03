class AddDefaultToStatusInPages < ActiveRecord::Migration[6.1]
  def up
    Page.where(status: [nil, '']).in_batches.update_all(status: Page.statuses[:new])
    Page.where(translation_status: [nil, '']).in_batches.update_all(
      translation_status: Page.translation_statuses[:new]
    )

    change_column_default :pages, :status, Page.statuses[:new]
    change_column_default :pages, :translation_status, Page.translation_statuses[:new]
    change_column_null :pages, :status, false
    change_column_null :pages, :translation_status, false
  end

  def down
    change_column_null :pages, :status, true
    change_column_null :pages, :translation_status, true
    change_column_default :pages, :status, nil
    change_column_default :pages, :translation_status, nil

    Page.where(status: Page.statuses[:new]).in_batches.update_all(status: nil)
    Page.where(translation_status: Page.translation_statuses[:new]).in_batches.update_all(
      translation_status: nil
    )
  end
end
