require 'spec_helper'

describe ImageSet do

  before(:each) do
    @image_set = FactoryGirl.create(:image_set1)
  end

  # subject { @article }
  it { should have_many(:titled_images).order(:position) }
  it { should belong_to(:owner).class_name(:User) }

  describe 'testing page_count' do

    it 'returns 0 if there are no images' do
      @image_set.page_count.should == 0
    end

    it 'returns 1 because we only have 1 image' do
      # right now there is only 1
      ti = FactoryGirl.create(:titled_image1)
      @image_set.titled_images << ti
      @image_set.page_count.should == 1
    end

    it 'returns as many as there are' do
      the_times = 4
      1.upto(the_times) do |num|
        ti = FactoryGirl.create(:titled_image1, original_file: "/path/#{num}")
        @image_set.titled_images << ti
        @image_set.page_count.should == num
      end
      @image_set.page_count.should == the_times
    end

  end

end
