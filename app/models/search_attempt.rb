# == Schema Information
#
# Table name: search_attempts
#
#  id              :integer          not null, primary key
#  clicks          :integer          default(0)
#  contributions   :integer          default(0)
#  hits            :integer          default(0)
#  owner           :boolean          default(FALSE)
#  query           :string(255)
#  search_type     :string(255)
#  slug            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  collection_id   :integer
#  document_set_id :bigint
#  user_id         :integer
#  visit_id        :integer
#  work_id         :integer
#
# Indexes
#
#  index_search_attempts_on_collection_id    (collection_id)
#  index_search_attempts_on_document_set_id  (document_set_id)
#  index_search_attempts_on_slug             (slug) UNIQUE
#  index_search_attempts_on_user_id          (user_id)
#  index_search_attempts_on_visit_id         (visit_id)
#  index_search_attempts_on_work_id          (work_id)
#
class SearchAttempt < ApplicationRecord
    belongs_to :user, optional: true
    belongs_to :collection, optional: true
    belongs_to :work, optional: true
    belongs_to :document_set, optional: true
    visitable class_name: "Visit" # ahoy integration

    after_create :update_slug

    def to_param
        "#{query.parameterize}-#{id}"
    end

    def update_slug
        update_attribute(:slug, to_param)
    end

    def results_link
        paths = Rails.application.routes.url_helpers
        case search_type
        when "work"
            paths.paged_search_path(self)
        when "collection"
            paths.paged_search_path(self)
        when "collection-title"
            if collection.present?
                paths.collection_path(collection.owner, collection, search_attempt_id: id)
            else # document_set
                paths.collection_path(document_set.owner, document_set, search_attempt_id: id)
            end
        when "findaproject"
            paths.search_attempt_show_path(self)
        end
    end

    def results
        query = sanitize_and_format_search_string(self.query)

        case search_type
        when "work"
            if work.present? && query.present?
                query = precise_search_string(query)
                results = Page.order('work_id, position')
                    .joins(:work)
                    .where(work_id: work.id)
                    .where("MATCH(search_text) AGAINST(? IN BOOLEAN MODE)", query)
            else
                results = Page.none
            end

        when "collection"
            collection_or_document_set = collection || document_set
            if collection_or_document_set.present? && query.present?
                query = precise_search_string(query)
                results = Page.order('work_id, position')
                    .joins(:work)
                    .where(work_id: collection_or_document_set.works.ids)
                    .where("MATCH(search_text) AGAINST(? IN BOOLEAN MODE)", query)
            else 
                results = Page.none
            end
        
        when "collection-title"
            collection_or_document_set = collection || document_set
            results = collection_or_document_set.search_works(query).includes(:work_statistic)

        when "findaproject"
            results = Collection.search(query).unrestricted + DocumentSet.search(query).unrestricted
        end

        update_attribute(:hits, results&.count || 0)
        return results
    end

    private

    def sanitize_and_format_search_string(search_string)
        return '' unless search_string.present?
        string = CGI::escapeHTML(search_string)
    end

    def precise_search_string(search_string)
        # convert 'natural' search strings unless they're precise
        return search_string if search_string.match(/["+-]/)

        search_string.gsub!(/\s+/, ' ')
        "+\"#{search_string}\""
    end
end
