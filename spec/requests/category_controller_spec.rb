require 'spec_helper'

# SEC-03: every CategoryController action requires the collection owner (or an admin).
# Every request carries collection_id and categories are looked up through @collection, so
# ids from another collection can't be used. Delete and the field toggles no longer go over GET.
describe CategoryController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  # A work makes the collection viewable (Collection#show_to? requires works), so denied
  # signed-in users land on the collection page and authorize_collection lets anonymous
  # requests reach the controller.
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:category) { create(:category, collection_id: collection.id, title: 'Original') }
  let!(:child_category) { create(:category, collection_id: collection.id, parent: category) }

  let!(:co_owner) { create(:unique_user, :owner).tap { |user| collection.owners << user } }
  let!(:stranger) { create(:unique_user) }
  let!(:admin) { create(:unique_user, :admin) }

  # A second collection owned by someone else, for the cross-collection (IDOR) cases.
  let!(:other_owner) { create(:unique_user, :owner) }
  let!(:other_collection) { create(:collection, owner_user_id: other_owner.id) }
  let!(:other_work) { create(:work, collection: other_collection, owner_user_id: other_owner.id) }
  let!(:other_category) { create(:category, collection_id: other_collection.id, title: 'Other') }

  # The test DB isn't reset between examples, so created categories need unique titles.
  let(:new_title) { "New category #{SecureRandom.hex(6)}" }

  # A category id from another collection raises RecordNotFound in the scoped lookup, which
  # ApplicationController#bad_record_id turns into a redirect (it's a 404 only without @collection).
  def expect_bad_record_redirect
    expect(response).to have_http_status(:found)
    expect(response.location).not_to include('/category/')
  end

  def expect_denied_signed_out
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(dashboard_path)
  end

  def expect_denied_signed_in
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(collection_path(owner, collection))
    expect(flash[:error]).to eq(I18n.t('permission_denied'))
  end

  def subjects_path_for(selected)
    collection_subjects_path(owner, collection, selected_category_id: selected)
  end

  describe 'GET edit' do
    let(:params) { { collection_id: collection.slug, category_id: category.id } }

    it 'denies a signed-out user' do
      get category_edit_path, params: params

      expect_denied_signed_out
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      get category_edit_path, params: params

      expect_denied_signed_in
    end

    it 'renders the form for the owner' do
      login_as owner
      get category_edit_path, params: params

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit)
    end

    it 'redirects away for a category from another collection' do
      login_as owner
      get category_edit_path, params: { collection_id: collection.slug, category_id: other_category.id }

      expect_bad_record_redirect
    end
  end

  describe 'GET add_new' do
    it 'denies a signed-out user' do
      get category_add_new_path, params: { collection_id: collection.slug }

      expect_denied_signed_out
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      get category_add_new_path, params: { collection_id: collection.slug }

      expect_denied_signed_in
    end

    it 'builds a root category for the owner' do
      login_as owner
      get category_add_new_path, params: { collection_id: collection.slug }

      expect(response).to render_template(:add_new)
      expect(assigns(:new_category)).to be_a_new(Category)
      expect(assigns(:new_category).collection_id).to eq(collection.id)
      expect(assigns(:new_category).parent).to be_nil
    end

    it "builds a child category that inherits the parent's flags" do
      category.update!(gis_enabled: true, bio_fields_enabled: true)
      login_as owner
      get category_add_new_path, params: { collection_id: collection.slug, category_id: category.id }

      new_category = assigns(:new_category)
      expect(new_category.parent).to eq(category)
      expect(new_category.gis_enabled).to be(true)
      expect(new_category.bio_fields_enabled).to be(true)
    end

    it 'redirects away for a parent from another collection' do
      login_as owner
      get category_add_new_path, params: { collection_id: collection.slug, category_id: other_category.id }

      expect_bad_record_redirect
    end
  end

  describe 'PATCH update' do
    let(:params) { { collection_id: collection.slug, category_id: category.id, category: { title: 'Renamed' } } }

    it 'denies a signed-out user and keeps the title' do
      patch category_update_path, params: params

      expect_denied_signed_out
      expect(category.reload.title).to eq('Original')
    end

    it 'denies a signed-in non-owner and keeps the title' do
      login_as stranger
      patch category_update_path, params: params

      expect_denied_signed_in
      expect(category.reload.title).to eq('Original')
    end

    it 'denies a request with no collection_id' do
      login_as other_owner
      patch category_update_path, params: { category_id: category.id, category: { title: 'Renamed' } }

      expect(response).to have_http_status(:see_other)
      expect(category.reload.title).to eq('Original')
    end

    it 'answers legacy XHR with 201 + Location, like ajax_redirect_to' do
      login_as stranger
      patch category_update_path, params: params, xhr: true

      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to end_with(collection_path(owner, collection))
      expect(category.reload.title).to eq('Original')
    end

    it 'answers JSON with a bare 401 / 403' do
      patch category_update_path, params: params, as: :json
      expect(response).to have_http_status(:unauthorized)

      login_as stranger
      patch category_update_path, params: params, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(category.reload.title).to eq('Original')
    end

    it 'lets the owner rename the category' do
      login_as owner
      patch category_update_path, params: params

      expect(category.reload.title).to eq('Renamed')
      expect(flash[:notice]).to eq(I18n.t('category.update.category_updated'))
      expect(response).to redirect_to(subjects_path_for(category.id))
    end

    it 'lets a co-owner and an admin rename the category' do
      login_as co_owner
      patch category_update_path, params: params
      expect(category.reload.title).to eq('Renamed')

      login_as admin
      patch category_update_path, params: params.deep_merge(category: { title: 'By admin' })
      expect(category.reload.title).to eq('By admin')
    end

    it 'ignores collection_id and parent_id in the category params' do
      login_as owner
      patch category_update_path, params: params.deep_merge(
        category: { collection_id: other_collection.id, parent_id: other_category.id }
      )

      category.reload
      expect(category.title).to eq('Renamed')
      expect(category.collection_id).to eq(collection.id)
      expect(category.parent_id).to be_nil
    end

    it 'renders the form again when the title is blank' do
      login_as owner
      patch category_update_path, params: params.deep_merge(category: { title: '' })

      expect(response).to render_template(:edit)
      expect(category.reload.title).to eq('Original')
    end

    it 'redirects away for a category from another collection' do
      login_as owner
      patch category_update_path,
            params: { collection_id: collection.slug, category_id: other_category.id, category: { title: 'Renamed' } }

      expect_bad_record_redirect
      expect(other_category.reload.title).to eq('Other')
    end

    it "redirects away when another collection's owner sends their own collection_id" do
      login_as other_owner
      patch category_update_path,
            params: { collection_id: other_collection.slug, category_id: category.id, category: { title: 'Renamed' } }

      expect_bad_record_redirect
      expect(category.reload.title).to eq('Original')
    end
  end

  describe 'POST create' do
    let(:params) { { collection_id: collection.slug, category: { title: new_title } } }

    it 'denies a signed-out user and creates nothing' do
      expect { post category_create_path, params: params }.not_to change(Category, :count)

      expect_denied_signed_out
    end

    it 'denies a signed-in non-owner and creates nothing' do
      login_as stranger

      expect { post category_create_path, params: params }.not_to change(Category, :count)
      expect_denied_signed_in
    end

    it 'denies a non-owner who only names the collection in category[collection_id]' do
      login_as stranger

      expect do
        post category_create_path, params: { category: { title: new_title, collection_id: collection.id } }
      end.not_to change(Category, :count)
      expect(response).to have_http_status(:see_other)
    end

    it 'lets the owner create a root category' do
      login_as owner

      expect { post category_create_path, params: params }.to change(collection.categories, :count).by(1)
      new_category = Category.find_by!(title: new_title)
      expect(new_category.parent).to be_nil
      expect(flash[:notice]).to eq(I18n.t('category.create.category_created'))
      expect(response).to redirect_to(subjects_path_for(new_category.id))
    end

    it 'lets the owner create a child category' do
      login_as owner
      post category_create_path, params: params.deep_merge(category: { parent_id: category.id })

      expect(Category.find_by!(title: new_title).parent).to eq(category)
    end

    it 'creates the category in @collection, whatever category[collection_id] says' do
      login_as owner
      post category_create_path, params: params.deep_merge(category: { collection_id: other_collection.id })

      expect(Category.find_by!(title: new_title).collection_id).to eq(collection.id)
    end

    it 'redirects away for a parent from another collection' do
      login_as owner

      expect do
        post category_create_path, params: params.deep_merge(category: { parent_id: other_category.id })
      end.not_to change(Category, :count)
      expect_bad_record_redirect
    end

    it 'renders the form again when the title is blank' do
      login_as owner

      expect do
        post category_create_path, params: { collection_id: collection.slug, category: { title: '' } }
      end.not_to change(Category, :count)
      expect(response).to render_template(:add_new)
    end
  end

  describe 'DELETE delete' do
    let(:params) { { collection_id: collection.slug, category_id: category.id } }

    it 'denies a signed-out user and keeps the category' do
      delete category_delete_path, params: params

      expect_denied_signed_out
      expect(Category.exists?(category.id)).to be(true)
    end

    it 'denies a signed-in non-owner and keeps the category' do
      login_as stranger
      delete category_delete_path, params: params

      expect_denied_signed_in
      expect(Category.exists?(category.id)).to be(true)
    end

    it 'denies a request with no collection_id' do
      login_as stranger
      delete category_delete_path, params: { category_id: category.id }

      expect(response).to have_http_status(:see_other)
      expect(Category.exists?(category.id)).to be(true)
    end

    it 'lets the owner delete the category and its children' do
      login_as owner
      delete category_delete_path, params: params

      expect(Category.exists?(category.id)).to be(false)
      expect(Category.exists?(child_category.id)).to be(false)
      expect(flash[:notice]).to eq(I18n.t('category.delete.category_deleted'))
      expect(response).to redirect_to(collection_subjects_path(owner, collection))
    end

    it 'redirects to the parent after deleting a child' do
      login_as co_owner
      delete category_delete_path, params: { collection_id: collection.slug, category_id: child_category.id }

      expect(Category.exists?(child_category.id)).to be(false)
      expect(response).to redirect_to(subjects_path_for(category.id))
    end

    it 'lets an admin who does not own the collection delete the category' do
      login_as admin
      delete category_delete_path, params: params

      expect(Category.exists?(category.id)).to be(false)
    end

    it 'redirects away for a category from another collection' do
      login_as owner
      delete category_delete_path, params: { collection_id: collection.slug, category_id: other_category.id }

      expect_bad_record_redirect
      expect(Category.exists?(other_category.id)).to be(true)
    end

    # The old GET URL no longer routes to category#delete, so it can't be triggered from
    # an <img src> or a link.
    it 'cannot be triggered over GET' do
      login_as owner
      get '/category/delete', params: params

      expect(Category.exists?(category.id)).to be(true)
    end
  end

  describe 'field toggles' do
    [:gis, :bio_fields, :org_fields].each do |field|
      attribute = :"#{field}_enabled"

      [true, false].each do |enable|
        action = :"#{enable ? 'enable' : 'disable'}_#{field}"

        describe "PATCH #{action}" do
          let(:path) { public_send(:"category_#{action}_path") }
          let(:params) { { collection_id: collection.slug, category_id: category.id } }

          before do
            [category, child_category].each { |c| c.update_column(attribute, !enable) }
          end

          it 'denies a signed-out user and leaves the flag' do
            patch path, params: params

            expect_denied_signed_out
            expect(category.reload.public_send(attribute)).to be(!enable)
          end

          it 'denies a signed-in non-owner and leaves the flag' do
            login_as stranger
            patch path, params: params

            expect_denied_signed_in
            expect(category.reload.public_send(attribute)).to be(!enable)
          end

          it 'lets the owner set the flag on the category and its descendants' do
            login_as owner
            patch path, params: params

            expect(category.reload.public_send(attribute)).to be(enable)
            expect(child_category.reload.public_send(attribute)).to be(enable)
            expect(flash[:notice]).to start_with(
              I18n.t("category.#{action}.fields_#{enable ? 'enabled' : 'disabled'}_for", title: category.title)
            )
            expect(response).to redirect_to(subjects_path_for(category.id))
          end

          it 'redirects away for a category from another collection' do
            other_category.update_column(attribute, !enable)
            login_as owner
            patch path, params: { collection_id: collection.slug, category_id: other_category.id }

            expect_bad_record_redirect
            expect(other_category.reload.public_send(attribute)).to be(!enable)
          end

          it 'cannot be triggered over GET' do
            login_as owner
            get "/category/#{action}", params: params

            expect(category.reload.public_send(attribute)).to be(!enable)
          end
        end
      end
    end
  end

  # collection_id may be a document set slug. DocumentSet delegates #categories to its
  # collection, and its owners are the collection's owners.
  describe 'from a document set' do
    let!(:docset_collection) { create(:collection, :docset_enabled, owner_user_id: owner.id) }
    let!(:document_set) do
      create(:document_set, :public, collection_id: docset_collection.id, owner_user_id: owner.id)
    end
    let!(:docset_category) { create(:category, collection_id: docset_collection.id, title: 'In set') }

    it "lets the collection's owner create a category in the set's collection" do
      login_as owner
      post category_create_path, params: { collection_id: document_set.slug, category: { title: new_title } }

      new_category = Category.find_by!(title: new_title)
      expect(new_category.collection_id).to eq(docset_collection.id)
      expect(response).to redirect_to(
        collection_subjects_path(document_set.owner, document_set, selected_category_id: new_category.id)
      )
    end

    it "lets the collection's owner rename a category" do
      login_as owner
      patch category_update_path,
            params: { collection_id: document_set.slug, category_id: docset_category.id, category: { title: 'Renamed' } }

      expect(docset_category.reload.title).to eq('Renamed')
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      delete category_delete_path, params: { collection_id: document_set.slug, category_id: docset_category.id }

      expect(response).to have_http_status(:see_other)
      expect(Category.exists?(docset_category.id)).to be(true)
    end

    it "redirects away for a category outside the set's collection" do
      login_as owner
      delete category_delete_path, params: { collection_id: document_set.slug, category_id: category.id }

      expect_bad_record_redirect
      expect(Category.exists?(category.id)).to be(true)
    end
  end
end
