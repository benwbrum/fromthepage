class Note < ActiveRecord::Base
  # Notes are comments on pages.  In the future they may 
  # be comments on works, comments on image fragments, 
  # comments on articles, or questions and answers 

  # automated stuff  
  acts_as_tree
  
  # associations
  belongs_to :user
  belongs_to :page
  belongs_to :work
  belongs_to :collection
  has_one :deed

  #########################
  # from restful_comments
  #########################
  def before_create
    # handle depth
    if !self[:parent_id].to_i.zero?
      self[:depth] = parent[:depth].to_i + 1
    else
      self[:depth] = 0
    end
  end

  def descendants
    result = []
    for note in self.children do
      result << note
      result += note.descendants
    end
    result
  end
   
  def self.for_each( comments, &block )
    for_each_children( nil, comments, &block ).to_s
  end

  def to_html
    txt = self[:body].gsub( '<', '&lt;' ).gsub( '>', '&gt;' ).gsub( '\n','<br />' )
    return txt 
    # TODO add whitelist, possibly RedCloth
  end

private
  def self.for_each_children( parent_id, nodes, &block )
    for node in nodes
      if node.parent_id.to_i == parent_id.to_i
        yield node 
        for_each_children( node.id, nodes, &block )
      end
    end
  end

	
end
