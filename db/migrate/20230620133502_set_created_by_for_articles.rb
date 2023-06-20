class SetCreatedByForArticles < ActiveRecord::Migration[6.0]
  def change
    Article.all.each do |article|
      if article.collection_id.present?
        collection = Collection.find(article.collection_id)
        article.update(created_by: collection.owner)
      end
    end
  end
end
