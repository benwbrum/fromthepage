require 'spec_helper'

RSpec.describe 'Subject access', type: :request do
  let(:owner) { create(:unique_user, :owner) }
  let(:visitor) { create(:unique_user) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection_id: collection.id, owner_user_id: owner.id) }
  let(:page) { create(:page, work: work) }
  let(:article) do
    create(:article, collection: collection, pages: [page], source_text: 'Subject access description')
  end

  before do
    Current.user = owner
    article
  end

  after { Warden.test_reset! }

  def subject_path(context: collection, route_owner: context.owner, article_id: article.id)
    case endpoint
    when :show
      collection_article_show_path(route_owner, context, article_id)
    when :tooltip
      article_tooltip_path(article_id: article_id, collection_id: context.slug, user_slug: route_owner.slug)
    when :versions
      collection_article_version_path(route_owner, context, article_id)
    when :relationship_graph
      collection_article_relationship_graph_path(route_owner, context, article_id)
    end
  end

  def expect_subject_not_found
    expect(response).to have_http_status(:not_found)
    expect(response.headers['Location']).to be_nil
    expect(response.body).not_to include(article.title, article.source_text)
  end

  shared_examples 'an authorized subject endpoint' do
    it 'allows anonymous access to a public subject' do
      get subject_path

      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 for anonymous access to a private subject' do
      collection.update!(visibility: :private)

      get subject_path

      expect_subject_not_found
    end

    it 'returns 404 for signed-in users without private collection access' do
      collection.update!(visibility: :private)
      login_as visitor

      get subject_path

      expect_subject_not_found
    end

    it 'returns 404 for a user blocked from a public collection' do
      collection.blocked_users << visitor
      login_as visitor

      get subject_path

      expect_subject_not_found
    end

    it 'allows the private collection owner' do
      collection.update!(visibility: :private)
      login_as owner

      get subject_path

      expect(response).to have_http_status(:ok)
    end

    it 'allows a private collection collaborator' do
      collection.update!(visibility: :private)
      collection.collaborators << visitor
      login_as visitor

      get subject_path

      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 for subjects requested under an unrelated public collection' do
      unrelated = create(:collection, owner_user_id: owner.id)

      get subject_path(context: unrelated)

      expect_subject_not_found
    end

    it 'returns 404 for private subjects requested under an unrelated public collection' do
      collection.update!(visibility: :private)
      unrelated = create(:collection, owner_user_id: owner.id)

      get subject_path(context: unrelated)

      expect_subject_not_found
    end

    it 'returns 404 for an incorrect owner prefix' do
      get subject_path(route_owner: visitor)

      expect_subject_not_found
    end

    it 'returns 404 for an unknown owner prefix' do
      get subject_path.sub(owner.slug, 'missing-subject-owner')

      expect_subject_not_found
    end

    it 'returns 404 for unknown subject IDs' do
      get subject_path(article_id: Article.maximum(:id) + 1)

      expect_subject_not_found
    end

    it 'returns 404 for an unknown collection context' do
      get subject_path.sub(collection.slug, 'missing-subject-context')

      expect_subject_not_found
    end

    it 'returns 404 for another document set in the same collection' do
      set = create(:document_set, :public, collection_id: collection.id, owner_user_id: owner.id)

      get subject_path(context: set)

      expect_subject_not_found
    end

    it 'returns 404 for an inaccessible document set containing the subject' do
      set = create(:document_set, :private, collection_id: collection.id, owner_user_id: owner.id, works: [work])

      get subject_path(context: set)

      expect_subject_not_found
    end
  end

  [:show, :tooltip, :versions, :relationship_graph].each do |action|
    context "for #{action}" do
      let(:endpoint) { action }

      include_examples 'an authorized subject endpoint'

      # Graph generation within document sets is tracked separately in #5989.
      unless action == :relationship_graph
        it 'allows a subject through a public set whose parent collection is private' do
          collection.update!(visibility: :private, supports_document_sets: true)
          set = create(:document_set, :public, collection_id: collection.id, owner_user_id: owner.id, works: [work])

          get subject_path(context: set)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(article.title)
        end

        it 'allows a private document set collaborator' do
          collection.update!(visibility: :private, supports_document_sets: true)
          set = create(:document_set, :private, collection_id: collection.id, owner_user_id: owner.id, works: [work])
          set.collaborators << visitor
          login_as visitor

          get subject_path(context: set)

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  it 'returns 404 for private subject lists without requiring a subject ID' do
    collection.update!(visibility: :private)

    get collection_subjects_path(owner, collection)

    expect_subject_not_found
  end

  it 'returns 404 for private subject tooltips without collection parameters' do
    collection.update!(visibility: :private)

    get article_tooltip_path(article_id: article.id)

    expect_subject_not_found
  end

  it 'ignores unrelated session context instead of granting access to a private subject' do
    collection.update!(visibility: :private)
    unrelated = create(:collection, owner_user_id: owner.id)
    public_subject = create(:article, collection: unrelated)
    get collection_article_show_path(owner, unrelated, public_subject)
    expect(response).to have_http_status(:ok)

    get article_tooltip_path(article_id: article.id)

    expect_subject_not_found
  end

  it 'preserves valid document set context for legacy subject links' do
    collection.update!(visibility: :private, supports_document_sets: true)
    set = create(:document_set, :public, collection_id: collection.id, owner_user_id: owner.id, works: [work])
    get collection_article_show_path(owner, set, article)
    expect(response).to have_http_status(:ok)

    get article_tooltip_path(article_id: article.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(collection_article_show_path(owner, set, article))
  end

  it 'ignores a session document set after access is revoked' do
    collection.update!(visibility: :private, supports_document_sets: true)
    set = create(:document_set, :public, collection_id: collection.id, owner_user_id: owner.id, works: [work])
    get collection_article_show_path(owner, set, article)
    expect(response).to have_http_status(:ok)
    set.update!(visibility: :private)

    get article_tooltip_path(article_id: article.id)

    expect_subject_not_found
  end

  it 'does not allow a work parameter to repair an unrelated collection URL' do
    unrelated = create(:collection, owner_user_id: owner.id)

    get collection_article_show_path(owner, unrelated, article), params: { work_id: work.slug }

    expect_subject_not_found
  end

  it 'returns 404 for mismatched article and version parameters' do
    other_article = create(:article, collection: collection)

    get collection_article_version_path(owner, collection, article),
        params: { article_version_id: other_article.article_versions.first.id }

    expect_subject_not_found
  end

  it 'validates an explicitly selected version against the requested collection' do
    unrelated = create(:collection, owner_user_id: owner.id)

    get article_version_list_path,
        params: { article_version_id: article.article_versions.first.id, collection_id: unrelated.slug }

    expect_subject_not_found
  end

  it 'returns 404 for an unknown selected version' do
    get article_version_show_path(article_version_id: ArticleVersion.maximum(:id) + 1)

    expect_subject_not_found
  end

  it 'allows an explicit public document set parameter for a subject in a private collection' do
    collection.update!(visibility: :private, supports_document_sets: true)
    set = create(:document_set, :public, collection_id: collection.id, owner_user_id: owner.id, works: [work])

    get article_tooltip_path(article_id: article.id, document_set_id: set.id)

    expect(response).to have_http_status(:ok)
  end

  it 'rejects an inaccessible document set parameter even when the collection is public' do
    set = create(:document_set, :private, collection_id: collection.id, owner_user_id: owner.id, works: [work])

    get article_tooltip_path(article_id: article.id, collection_id: collection.slug, document_set_id: set.id)

    expect_subject_not_found
  end

  it 'returns 404 for private subject exports through a public collection' do
    collection.update!(visibility: :private)
    unrelated = create(:collection, owner_user_id: owner.id)
    login_as owner

    get collection_subject_distribution_path(owner, unrelated, article)

    expect_subject_not_found
  end

  it 'returns 404 when filtering pages by a subject outside their collection' do
    unrelated = create(:collection, owner_user_id: owner.id)

    get display_read_all_works_path(article_id: article.id, collection_id: unrelated.slug)

    expect_subject_not_found
  end

  it 'does not mutate subjects through an unrelated collection URL' do
    unrelated = create(:collection, owner_user_id: owner.id)
    login_as owner

    patch collection_article_update_path(owner, unrelated, article),
          params: { save: true, article: { title: 'Incorrect context update' } }

    expect_subject_not_found
    expect(article.reload.title).not_to eq('Incorrect context update')
  end

  it 'does not allow signed-in users to mutate private subjects without access' do
    collection.update!(visibility: :private)
    login_as visitor

    patch collection_article_update_path(owner, collection, article),
          params: { save: true, article: { title: 'Unauthorized update' } }

    expect_subject_not_found
    expect(article.reload.title).not_to eq('Unauthorized update')
  end
end
