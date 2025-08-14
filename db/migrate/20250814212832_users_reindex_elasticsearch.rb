class UsersReindexElasticsearch < ActiveRecord::Migration[7.2]

  disable_ddl_transaction!

  def change
    UsersIndex.delete
    UsersIndex.create
    UsersIndex.import User.all
  end
end
