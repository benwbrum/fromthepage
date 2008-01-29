class Comment < ActiveRecord::Base
	
	# Comments are tree
	acts_as_tree

    after_save :update_parent

	
	if defined? RestfulCitations
		# Имеет набор цитат
		acts_as_restful_citable
	end
	
	# Что-то прокомментировано
	belongs_to :commentable, :polymorphic => true
	
	# Написан каким-то пользователем
	belongs_to :user
	
	def commentable_path
		'/' + self[:commentable_type].tableize + '/' + self[:commentable_id].to_s
	end
	
	def before_create
		if !self[:parent_id].to_i.zero?
			self[:depth] = parent[:depth].to_i + 1
		else
			self[:depth] = 0
		end
	end

    
    def update_parent
      if self[:comment_type] == 'review'
        if self[:depth] > 0
          parent[:comment_status] = 'answered'
          parent.save!
        end
      end
    end
	
	
	# Применяет блок кода к каждому узлу дерева из списка
	def self.for_each( comments, comment_type='annotation', &block )
		for_each_children( nil, 
		                   comments.reject { |c| c.comment_type != comment_type }, 
		                   comment_type, 
		                   &block ).to_s
	end
	
	
	def descendants
		result = []
		for comment in self.children do
			result << comment
			result += comment.descendants
		end
		result
	end
	
	def to_html
		txt = self[:body].gsub( '<', '&lt;' ).gsub( '>', '&gt;' ).gsub( '\n','<br />' )
		# BWB no RedCloth on this system
		return txt # RedCloth.new( txt ).to_html
	end
	
	private
	
	# Применяет блок кода к акждому узлу дерева из списка, являющегося ребенком узла с заданным идентификатором
	def self.for_each_children( parent_id, nodes, comment_type, &block )
		for node in nodes
			if node.parent_id.to_i == parent_id.to_i
				yield node if node.comment_type = comment_type # TODO make this perform
				for_each_children( node.id, nodes, comment_type, &block )
			end
		end
	end
	
end
puts "restful comments: COMMENT"