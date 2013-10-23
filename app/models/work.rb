class Work < ActiveRecord::Base
  has_many :pages, :order => :position
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  belongs_to :collection
  has_many :deeds, :order => 'created_at DESC'
  has_one :ia_work
  has_one :omeka_item
  has_one :work_statistic
  
  has_and_belongs_to_many :scribes, :class_name => 'User', :join_table => :transcribe_authorizations

  after_save :update_statistic

  def articles
    my_articles = []
    for page in self.pages
      for article in page.articles
        my_articles << article
      end
    end
    my_articles.uniq!
    logger.debug("DEBUG: articles=#{my_articles}")
    return my_articles
  end

  # TODO make not awful
  def reviews
    my_reviews = []
    for page in self.pages
      for comment in page.comments
        my_reviews << comment if comment.comment_type == 'review'
      end
    end
    return my_reviews
  end

  # TODO make not awful (denormalize work_id, collection_id; use legitimate finds)
  def recent_annotations
    my_annotations = []
    for page in self.pages
      for comment in page.comments
        my_annotations << comment if comment.comment_type == 'annotation'
      end
    end
    my_annotations.sort! { |a,b| b.created_at <=> a.created_at }
    return my_annotations[0..9]
  end

  def update_statistic
    unless self.work_statistic     
        self.work_statistic = WorkStatistic.new
    end
    self.work_statistic.recalculate
    
  end

  



end
