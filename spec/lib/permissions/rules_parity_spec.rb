require 'spec_helper'

# The rules in app/lib/permissions duplicate model predicates that are marked
# `TODO: Deprecate` (User#like_owner?, #can_transcribe?, #can_review?, #collaborator?,
# Collection#show_to?, DocumentSet#show_to?). Until those are removed, both copies must
# agree. This spec fails if one changes without the other.
RSpec.describe 'Permissions rules parity with model predicates' do
  before { Current.user = owner }

  let!(:owner) { create(:unique_user, :owner) }
  let!(:co_owner) { create(:unique_user, :owner) }
  let!(:collaborator) { create(:unique_user) }
  let!(:reviewer) { create(:unique_user) }
  let!(:stranger) { create(:unique_user) }
  let!(:admin) { create(:unique_user, :admin) }

  let!(:public_collection) { create(:collection, owner_user_id: owner.id) }
  let!(:private_collection) { create(:collection, :private, owner_user_id: owner.id) }
  let!(:review_collection) { create(:collection, owner_user_id: owner.id, review_type: :restricted) }
  let!(:document_set) { create(:document_set, :private, owner_user_id: owner.id, collection_id: private_collection.id) }
  let!(:public_work) { create(:work, collection: public_collection, owner_user_id: owner.id) }
  let!(:private_work) { create(:work, collection: private_collection, owner_user_id: owner.id) }
  let!(:restricted_work) { create(:work, collection: public_collection, owner_user_id: owner.id, restrict_scribes: true) }
  let!(:review_page) { create(:page, work: create(:work, collection: review_collection, owner_user_id: owner.id)) }

  let(:users) { [owner, co_owner, collaborator, reviewer, stranger, admin] }

  before do
    [public_collection, private_collection, review_collection].each do |collection|
      collection.owners << co_owner
      collection.collaborators << collaborator
    end
    review_collection.reviewers << reviewer
    document_set.collaborators << stranger
  end

  def label(user) = user.login

  it 'owner? matches User#like_owner?' do
    records = [public_collection, private_collection, document_set, public_work, private_work, review_page]

    users.product(records).each do |user, record|
      expect(Permissions::RecordRules.owner?(user, record))
        .to eq(user.like_owner?(record)), "#{label(user)} on #{record.class.name} #{record.id}"
    end
  end

  it 'collaborator? matches User#collaborator?' do
    users.product([public_collection, private_collection, document_set]).each do |user, record|
      expect(Permissions::RecordRules.collaborator?(user, record))
        .to eq(user.collaborator?(record)), "#{label(user)} on #{record.class.name} #{record.id}"
    end
  end

  it 'viewer? matches show_to? (including signed out)' do
    (users + [nil]).product([public_collection, private_collection, document_set]).each do |user, record|
      expect(Permissions::RecordRules.viewer?(user, record))
        .to eq(!!record.show_to?(user)), "#{user&.login || 'signed out'} on #{record.class.name} #{record.id}"
    end
  end

  it 'reviewer? matches User#can_review?' do
    users.product([public_collection, review_collection, review_page]).each do |user, record|
      expect(Permissions::CollectionRules.reviewer?(user, record))
        .to eq(user.can_review?(record)), "#{label(user)} on #{record.class.name} #{record.id}"
    end
  end

  it 'transcriber? matches User#can_transcribe?' do
    cases = [
      [public_work, nil], [private_work, nil], [restricted_work, nil],
      [private_work, document_set], [public_work, public_collection]
    ]

    users.product(cases).each do |user, (work, collection)|
      expect(Permissions::WorkRules.transcriber?(user, work, collection))
        .to eq(user.can_transcribe?(work, collection)), "#{label(user)} on Work #{work.id} via #{collection&.class&.name}"
    end
  end
end
