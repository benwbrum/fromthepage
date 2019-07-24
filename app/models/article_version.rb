class ArticleVersion < ActiveRecord::Base
  belongs_to :article
  belongs_to :user
  has_many :flags

  after_create :check_content

  def check_content
    Flag.check_article(self)
  end

  def prev
    article.article_versions.where("id < ?", id).first
  end

  def next
  	article.article_versions.where("id > ?", id).last
  end

  def current_version?
  	self.id == article.article_versions.pluck(:id).max
  end

  def expunge
  	# if we are we the current version
  	if self.current_version?
	  	previous_version = self.prev
	  	if previous_version
		  	#   copy the previous version's contents into the page and save without callbacks
	    	article.update_columns(
	    		:title => previous_version.title,
	    		:source_text => previous_version.source_text,
	    		:xml_text => previous_version.xml_text
			)
	    else
	    	article.destroy! # this also deletes the article versions
    	end
  	else
  	#   renumber subsequent versions
  		this_version = self
  		while next_version = this_version.next do
  			next_version.article_version -= 1
  			next_version.save!
  			this_version = next_version
  		end
  		self.destroy!
  	end
  end
end