require 'rails_helper'

RSpec.describe "sc_manifests/edit", :type => :view do
  before(:each) do
    @sc_manifest = assign(:sc_manifest, ScManifest.create!(
      :work => nil,
      :sc_collection => nil,
      :sc_id => "MyString",
      :label => "MyString",
      :metadata => "MyText",
      :first_sequence_id => "MyString",
      :first_sequence_label => "MyString"
    ))
  end

  it "renders the edit sc_manifest form" do
    render

    assert_select "form[action=?][method=?]", sc_manifest_path(@sc_manifest), "post" do

      assert_select "input#sc_manifest_work_id[name=?]", "sc_manifest[work_id]"

      assert_select "input#sc_manifest_sc_collection_id[name=?]", "sc_manifest[sc_collection_id]"

      assert_select "input#sc_manifest_sc_id[name=?]", "sc_manifest[sc_id]"

      assert_select "input#sc_manifest_label[name=?]", "sc_manifest[label]"

      assert_select "textarea#sc_manifest_metadata[name=?]", "sc_manifest[metadata]"

      assert_select "input#sc_manifest_first_sequence_id[name=?]", "sc_manifest[first_sequence_id]"

      assert_select "input#sc_manifest_first_sequence_label[name=?]", "sc_manifest[first_sequence_label]"
    end
  end
end
