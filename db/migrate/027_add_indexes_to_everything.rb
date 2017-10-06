class AddIndexesToEverything < ActiveRecord::Migration
  def self.up
    #| article_article_links       |
    add_index :article_article_links, :source_article_id
    add_index :article_article_links, :target_article_id

    #| article_versions            |
    add_index :article_versions,  :article_id
    add_index :article_versions,  :user_id

    #| articles                    |
    add_index :articles, :collection_id

    #| articles_categories         |
    # implicit to join table, I hope

    #| categories                  |
    add_index :categories, :collection_id
    add_index :categories, :parent_id

    #| collections                 |
    add_index :collections, :owner_user_id

    #| comments                    |
    # will be replaced

    #| image_sets                  |
#    add_index :image_sets, :owner_user_id

    #| page_article_links          |
    add_index :page_article_links, :page_id
    add_index :page_article_links, :article_id

    #| page_versions               |
    add_index :page_versions, :page_id
    add_index :page_versions, :user_id

    #| pages                       |
    add_index :pages, :work_id

    #| plugin_schema_info          |
    #| schema_info                 |
    #| sessions                    |

    #| titled_images               |
#    add_index :titled_images, :image_set_id

    #| transcribe_authorizations   |
    # implicit, I hope

    #| users                       |
    add_index :users, :login

    #| works                       |
    add_index :works, :owner_user_id
    add_index :works, :collection_id

  end

  def self.down
    #| article_article_links       |
    remove_index :article_article_links, :source_article_id
    remove_index :article_article_links, :target_article_id

    #| article_versions            |
    remove_index :article_versions,  :article_id
    remove_index :article_versions,  :user_id

    #| articles                    |
    remove_index :articles, :collection_id

    #| articles_categories         |
    # implicit to join table, I hope

    #| categories                  |
    remove_index :categories, :collection_id
    remove_index :categories, :parent_id

    #| collections                 |
    remove_index :collections, :owner_user_id

    #| comments                    |
    # will be replaced

    #| image_sets                  |
#    remove_index :image_sets, :owner_user_id

    #| page_article_links          |
    remove_index :page_article_links, :page_id
    remove_index :page_article_links, :article_id

    #| page_versions               |
    remove_index :page_versions, :page_id
    remove_index :page_versions, :user_id

    #| pages                       |
    remove_index :pages, :work_id

    #| plugin_schema_info          |
    #| schema_info                 |
    #| sessions                    |

    #| titled_images               |
#    remove_index :titled_images, :image_set_id

    #| transcribe_authorizations   |
    # implicit, I hope

    #| users                       |
    remove_index :users, :login

    #| works                       |
    remove_index :works, :owner_user_id
    remove_index :works, :collection_id
  end
end
