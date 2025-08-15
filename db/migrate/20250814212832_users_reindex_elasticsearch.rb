class UsersReindexElasticsearch < ActiveRecord::Migration[7.2]

  disable_ddl_transaction!

  def change
    if ELASTIC_ENABLED
      UsersIndex.delete
      UsersIndex.create
      UsersIndex.import User.all
    end
  end
end
