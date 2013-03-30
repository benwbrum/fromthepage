require 'spec_helper'

describe ImageSet do

  before(:each) do
    @image_set = FactoryGirl.create(:image_set1)
  end

  # subject { @article }
  it { should have_many(:titled_images).order(:position) }
  it { should belong_to(:owner).class_name(:User) }

end
