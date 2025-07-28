require 'spec_helper'

describe CategoryController do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:category) { create(:category, collection_id: collection.id) }
  let!(:child_category) { create(:category, collection_id: collection.id, parent: category) }

  describe "GET #edit" do
    it "renders the edit template" do
      get category_edit_path(collection_id: collection.slug, category_id: category.id)
      expect(response).to render_template(:edit)
    end
  end

  describe "GET #manage" do
    it "renders the manage template" do
      get category_manage_path(collection_id: collection.slug)
      expect(response).to render_template(:manage)
    end
    
    it "assigns categories to @categories" do
      get category_manage_path(collection_id: collection.slug)
      expect(assigns(:categories)).to eq(collection.categories)
    end
  end

  describe "PATCH #update" do
    context "with valid category params" do
      it "updates the category and redirects to collection subjects path" do
        new_title= "Updated Category Title #{category.id}"
        patch category_update_path(category_id: category.id, category: { title: new_title })
        expect(category.reload.title).to eq(new_title)
        expect(flash[:notice]).to eq(I18n.t('.category.update.category_updated'))
        expect(response).to redirect_to(collection_subjects_path(collection.owner, collection))
      end
    end

    context "with invalid category params" do
      it "renders the edit template" do
        patch category_update_path(category_id: category.id, category: { title: "" })
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "GET #add_new" do
    it "assigns a new category and renders the add_new template" do
      get category_add_new_path(collection_id: collection.slug)
      expect(assigns(:new_category)).to be_a_new(Category)
      expect(response).to render_template(:add_new)
    end
  end

  describe "POST #create" do
    context "with valid category params" do
      it "creates a new category and redirects to collection subjects path" do
        new_title = "New Category Title #{rand(1000000)}"
        post(category_create_path(collection_id: collection.id, category: { collection_id: collection.id, title: new_title }))
        new_category = Category.last
        expect(new_category.title).to eq(new_title)
        expect(flash[:notice]).to eq(I18n.t('.category.create.category_created'))
        expect(response).to redirect_to(collection_subjects_path(owner, collection))
      end
    end
  end


  describe "#enable_bio_fields" do
    it "enables bio fields for the category and its descendants" do
      get category_enable_bio_fields_path(collection_id: collection.id, category_id: category.id)
      expect(category.reload.bio_fields_enabled).to be_truthy
      category.descendants.each do |descendant|
        expect(descendant.bio_fields_enabled).to be_truthy
      end
      expect(response).to redirect_to(collection_subjects_path(collection.owner, collection, anchor: "category-#{category.id}"))
    end
  end

  describe "#disable_bio_fields" do
    it "disables bio fields for the category and its descendants" do
      get category_disable_bio_fields_path(collection_id: collection.id, category_id: category.id)
      expect(category.reload.bio_fields_enabled).to be_falsey
      category.descendants.each do |descendant|
        expect(descendant.bio_fields_enabled).to be_falsey
      end
      expect(response).to redirect_to(collection_subjects_path(collection.owner, collection, anchor: "category-#{category.id}"))
    end
  end


  describe "#enable_org_fields" do
    it "enables org fields for the category and its descendants" do
      get category_enable_org_fields_path(collection_id: collection.id, category_id: category.id)
      expect(category.reload.org_fields_enabled).to be_truthy
      category.descendants.each do |descendant|
        expect(descendant.org_fields_enabled).to be_truthy
      end
      expect(response).to redirect_to(collection_subjects_path(collection.owner, collection, anchor: "category-#{category.id}"))
    end
  end

  describe "#disable_org_fields" do
    it "disables org fields for the category and its descendants" do
      get category_disable_org_fields_path(collection_id: collection.id, category_id: category.id)
      expect(category.reload.org_fields_enabled).to be_falsey
      category.descendants.each do |descendant|
        expect(descendant.org_fields_enabled).to be_falsey
      end
      expect(response).to redirect_to(collection_subjects_path(collection.owner, collection, anchor: "category-#{category.id}"))
    end
  end



  private
end