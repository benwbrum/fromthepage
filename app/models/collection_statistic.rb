module CollectionStatistic
  def work_count
    self.works.count
  end
  
  def page_count
    Collection.count_by_sql("SELECT COUNT(*) FROM pages p INNER JOIN works w ON p.work_id = w.id WHERE w.collection_id = #{self.id}")
  end
  def subject_count
    self.articles.count
  end
  def mention_count
    Collection.count_by_sql("SELECT COUNT(*) FROM page_article_links pal INNER JOIN articles a ON pal.article_id = a.id WHERE a.collection_id = #{self.id}")
  end
  def contributor_count
    Collection.count_by_sql("SELECT COUNT(DISTINCT user_id) FROM deeds WHERE collection_id = #{self.id}")
  end
  def comment_count
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::NOTE_ADDED}\"")
  end
end
