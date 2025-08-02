require 'spec_helper'

describe User do
  describe '#last_deed_at' do
    let(:user) { create(:user) }

    it 'returns the created_at of the most recent deed' do
      allow_any_instance_of(Deed).to receive(:calculate_prerender)
      allow_any_instance_of(Deed).to receive(:calculate_prerender_mailer)
      older = create(:deed, user: user, deed_type: DeedType.all_types.first, created_at: 2.days.ago)
      newest = create(:deed, user: user, deed_type: DeedType.all_types.first, created_at: 1.day.ago)
      expect(user.last_deed_at.to_i).to eq(newest.created_at.to_i)
      Deed.destroy(older.id)
      Deed.destroy(newest.id)
    end
  end

  context 'es_search' do
    let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

    let!(:user_1) { create(:unique_user, :owner, real_name: identifier) }
    let!(:user_2) { create(:unique_user, :owner, about: identifier) }
    let!(:user_3) { create(:unique_user, :owner, website: "https://#{identifier}.com") }
    let!(:user_4) { create(:unique_user, :owner) }

    let(:records) do
      [
        user_1,
        user_2,
        user_3,
        user_4
      ]
    end

    before(:each) do
      stub_const('ELASTIC_ENABLED', true)

      UsersIndex.purge
      records.each(&:save!)
    end

    after(:each) do
      stub_const('ELASTIC_ENABLED', true)

      records.each(&:destroy!)
      UsersIndex.purge
    end

    describe '#self.es_search' do
      let(:query) { identifier }
      let(:user) { nil }

      let(:es_search) { described_class.es_search(query: query) }

      it 'returns correct user ids' do
        expect(es_search.pluck("_id").map(&:to_i)).to match_array(
          [
            user_1.id,
            user_2.id
          ]
        )
      end

      context 'when querying website' do
        let(:query) { "https://#{identifier}.com" }

        it 'returns correct user ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              user_3.id
            ]
          )
        end
      end
    end
  end
end
