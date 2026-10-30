require 'spec_helper'

describe SubjectHeadings::CreateSampleSet do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: [], supports_document_sets: false) }
  let(:user) { owner }
  let(:size) { 3 }

  def transcribed_work(text, status: :transcribed)
    work = create(:work, collection: collection)
    create(:page, status: status, work: work,
                  xml_text: "<?xml version='1.0' encoding='UTF-8'?><page><p>#{text}</p></page>")
    work
  end

  let(:long) { ' Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor.' * 3 }
  let!(:militia_works) { Array.new(2) { |i| transcribed_work("Militia company muster, rifles and drill #{i}.#{long}") } }
  let!(:pardon_works) { Array.new(2) { |i| transcribed_work("Pardon petition for a prisoner in the penitentiary #{i}.#{long}") } }
  let!(:railroad_works) { Array.new(2) { |i| transcribed_work("Railroad freight depot and locomotive cars #{i}.#{long}") } }
  let!(:untranscribed_work) { transcribed_work("Railroad freight depot and locomotive cars.#{long}", status: :new) }
  let!(:short_work) { transcribed_work('Too short to judge.') }

  let(:result) { described_class.new(collection: collection, user: user, size: size).call }

  it 'creates a private sample set of varied transcribed works' do
    expect(result.success?).to be_truthy

    document_set = result.document_set
    expect(document_set.title).to eq(described_class::TITLE)
    expect(document_set.collection).to eq(collection)
    expect(document_set.owner).to eq(owner)
    expect(document_set).to be_visibility_private
    expect(document_set.works.size).to eq(3)
    [militia_works, pardon_works, railroad_works].each do |group|
      expect((document_set.works & group).size).to eq(1)
    end
  end

  it 'leaves out untranscribed works and works with too little text' do
    expect(result.document_set.works).not_to include(untranscribed_work, short_work)
  end

  it 'turns on document sets for the collection' do
    result
    expect(collection.reload.supports_document_sets).to be_truthy
  end

  context 'when the collection already has a sample set' do
    before { create(:document_set, collection: collection, owner_user_id: owner.id, title: described_class::TITLE) }

    it 'fails without creating another' do
      expect { result }.not_to change(DocumentSet, :count)
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to include('already has')
    end
  end

  context 'when there are fewer transcribed works than requested' do
    let(:size) { 20 }

    it 'uses all of them' do
      expect(result.document_set.works.size).to eq(6)
    end
  end

  context 'when the user does not own the collection' do
    let(:user) { create(:unique_user) }

    it 'fails' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to include('no permission')
    end
  end
end
