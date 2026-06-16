require 'spec_helper'

RSpec.describe 'Collaborator actions' do
  let(:owner) { create(:unique_user, :owner) }
  let(:collaborator) { create(:unique_user) }

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end

  def create_collection(visibility = :public)
    traits = visibility == :private ? [:private] : []
    create(:collection, *traits, :docset_enabled, owner_user_id: owner.id)
  end

  def create_document_set(collection:, visibility: :public, collaborators: [])
    traits = [visibility]
    create(:document_set,
           *traits,
           collection: collection,
           owner: owner,
           owner_user_id: owner.id,
           collaborators: collaborators)
  end

  context 'when collection and docset are public' do
    let(:collection) { create_collection }
    let(:docset_collection) { create_collection }
    let(:docset) { create_document_set(collection: docset_collection) }
    let(:work) { collection.works.first }

    it 'can view public collections from user profile' do
      expected_title = collection.title

      login_as(collaborator, scope: :user)
      visit user_profile_path(owner)
      expect(page).to have_content(expected_title)
    end

    it 'can view public document sets from user profile' do
      expected_title = docset.title

      login_as(collaborator, scope: :user)
      visit user_profile_path(owner)
      expect(page).to have_content(expected_title)
    end

    it 'can view public collection page' do
      login_as(collaborator, scope: :user)
      visit collection_path(owner, collection)
      expect(page.current_path).to eq(collection_path(owner, collection))
    end

    it 'can view public works from collection page' do
      login_as(collaborator, scope: :user)
      visit collection_path(owner, collection)
      expect(page).to have_content(work.title)
    end
  end

  context 'when collection is private and docset is public' do
    let(:private_collection) { create_collection(:private) }
    let(:docset) { create_document_set(collection: private_collection) }

    it 'cannot view private collections from user profile' do
      hidden_title = private_collection.title

      login_as(collaborator, scope: :user)
      visit user_profile_path(owner)
      expect(page).not_to have_content(hidden_title)
    end

    it 'can view public docsets from user profile' do
      expected_title = docset.title

      login_as(collaborator, scope: :user)
      visit user_profile_path(owner)
      expect(page).to have_content(expected_title)
    end
  end

  context 'when collection is public and docset is private' do
    let(:collection) { create_collection }
    let(:docset) { create_document_set(collection: collection, visibility: :private) }

    it 'can view public collections from user profile' do
      expected_title = collection.title

      login_as(collaborator, scope: :user)
      visit user_profile_path(owner)
      expect(page).to have_content(expected_title)
    end

    it 'can view private docset from user profile' do
      hidden_title = docset.title

      login_as(collaborator, scope: :user)
      visit user_profile_path(owner)
      expect(page).not_to have_content(hidden_title)
    end
  end

  context 'when collection is private and docset is private' do
    let(:collection) { create_collection(:private) }
    let(:docset) { create_document_set(collection: collection, visibility: :private) }

    it 'cannot view private collections from user profile' do
      hidden_title = collection.title

      login_as(collaborator, scope: :user)
      visit user_profile_path(owner)
      expect(page).not_to have_content(hidden_title)
    end

    it 'cannot view private docset from user profile' do
      hidden_title = docset.title

      login_as(collaborator, scope: :user)
      visit user_profile_path(owner)
      expect(page).not_to have_content(hidden_title)
    end

    context 'when added as a collaborator to a private collection' do
      let(:collection) do
        create(:collection, :private, :docset_enabled,
               owner_user_id: owner.id,
               collaborators: [collaborator])
      end
      let(:docset) { create_document_set(collection: collection, visibility: :private) }

      it 'can view the private collection' do
        expected_title = collection.title

        login_as(collaborator, scope: :user)
        visit user_profile_path(owner)
        expect(page).to have_content(expected_title)
      end

      it 'can view private document sets, though not explicitly named' do
        expected_title = docset.title

        login_as(collaborator, scope: :user)
        visit user_profile_path(owner)
        expect(page).to have_content(expected_title)
      end
    end

    context 'when added as a collaborator to a private docset' do
      let(:collection) { create_collection(:private) }
      let(:docset) do
        create_document_set(collection: collection,
                            visibility: :private,
                            collaborators: [collaborator])
      end

      it 'cannot view private collections' do
        hidden_title = collection.title

        login_as(collaborator, scope: :user)
        visit user_profile_path(owner)
        expect(page).not_to have_content(hidden_title)
      end

      it 'can view private document sets' do
        expected_title = docset.title

        login_as(collaborator, scope: :user)
        visit user_profile_path(owner)
        expect(page).to have_content(expected_title)
      end
    end
  end
end
