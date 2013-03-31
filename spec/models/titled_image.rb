require 'spec_helper'

describe TitledImage do

  before(:each) do
    @titled_image = FactoryGirl.create(:titled_image1)
  end

  it { should belong_to(:image_set) }
end
