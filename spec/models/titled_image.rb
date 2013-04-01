require 'spec_helper'

describe TitledImage do

  before(:each) do
    @titled_image = FactoryGirl.create(:titled_image1)
  end

  it { should belong_to(:image_set) }

  it 'should test crop_file' do
    @titled_image.crop_file.should == @titled_image.image_set.path + '/fromthepage/images/working/1/img_3556_crop.jpg'
  end
end
