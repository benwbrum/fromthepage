class Publication < ActiveRecord::Base
  acts_as_tree
  acts_as_votable cacheable_strategy: :update_columns
  attr_accessible :text,:voted, :cached_weighted_score,:user
	# SI MISMO, USUARIO

  belongs_to :user
  belongs_to :foro

  @voted = false

  def assign_vote(vote)
    @voted = vote
  end

  def show_vote
    @voted
  end

  def getDTO
    PublicationDTO.new(self)
  end

  class PublicationDTO
    attr_accessor :voted,:cached_weighted_score,:text,:user_id,:foro_id,:user
    def initialize(publication)
      @id = publication.id
      if !publication.parent.nil?
        @parent_id = publication.parent.id
      end

      @voted = publication.show_vote
      @created_at = publication.created_at
      @updated_at = publication.updated_at
      @text = publication.text
      @cached_weighted_score = publication.cached_weighted_score
      @user_id = publication.user.id
      @user = publication.user
      @foro_id = publication.foro.id
    end
  end
end
