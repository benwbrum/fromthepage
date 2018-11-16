# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User, type: :model do
  before :each do
    @user = create(:user)
  end

  after :each do
    @user.destroy
  end

  describe '#owner_works' do
    xit "returns all works owned by this user" do
    end
  end
end
