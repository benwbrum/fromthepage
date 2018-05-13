class AddSourceTemplateToPages < ActiveRecord::Migration
  def change
    add_column :pages, :source_template, :text, :null => true
  end
end
