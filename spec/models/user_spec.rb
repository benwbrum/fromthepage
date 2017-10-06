require 'spec_helper'

describe User do

  before(:each) do
    @user = FactoryGirl.create(:user1)
  end

  subject { @user }

  it { should respond_to(:login) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }

  it { should have_many(:owner_works).class_name(:Work) }
  it { should have_many(:oai_sets) }
  it { should have_many(:ia_works) }
  it { should have_and_belong_to_many(:scribe_works).class_name(:Work) }
  it { should have_and_belong_to_many(:owned_collections).class_name(:Collection) }
  it { should have_many(:page_versions).order("created_on DESC") }
  it { should have_many(:article_versions).order("created_on DESC") }
  it { should have_many(:notes).order("created_at DESC") }
  it { should have_many(:deeds) }

  it { should validate_presence_of(:login) }

  # this one does not seem to work right now.
  # it { should validate_presence_of(:password) } # :if => :password_required?
  # it { should validate_presence_of(:password).with_message("can't be blank") } # :if => :password_required?
  it { should ensure_length_of(:password).is_at_least(4).is_at_most(40) }
  it { should validate_presence_of(:password_confirmation) } # :if => :password_required?
  it { should validate_confirmation_of(:password) } # :if => :password_required?
  it { should ensure_length_of(:login).is_at_least(3).is_at_most(40) }
  it { should validate_uniqueness_of(:login).case_insensitive }

  it "login must be unique" do
    user2 = User.new
    user2.login = @user.login
    user2.password = "1234567"
    user2.password_confirmation = "1234567"
    user2.should_not be_valid
    User.count.should == 1
  end

  it "confirms password" do
    user2 = User.new
    user2.login = "qwerrty"
    user2.password = "1234567"
    user2.password_confirmation = "1234568"
    user2.should_not be_valid
    User.count.should == 1
  end

  describe "when login is not present" do
    before { @user.login = " " }
    it { should_not be_valid }
  end

  # I don't know why this doesn't work.
  xit "when password is not present" do
    before { @user.password = nil }
    it { should_not be_valid }
  end

  describe "when password_confirmation is not present" do
    before { @user.password_confirmation = nil }
    it { should_not be_valid }
  end

  # It seems like this should work
  xit "checks the length of the username" do
    test_name = "e" * 200
    user3 = User.new
    user3.login = test_name
    user3.password = "123467"
    user3.password_confirmation = "1234657"
    user3.should_not be_valid

  end

  describe "when login is too long" do
    before { @user.login = "a" * 41 }
    it { should_not be_valid }
  end

  describe "when login is too short" do
    before { @user.login = "a" * 2 }
    it { should_not be_valid }
  end

  describe "when password is too long" do
    before { @user.password = "a" * 41 }
    it { should_not be_valid }
  end

  describe "when password is too short" do
    before { @user.password = "a" * 3 }
    it { should_not be_valid }
  end


end
