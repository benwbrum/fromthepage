require 'spec_helper'

RSpec.describe PageVersion, type: :model do
  let(:user) { create(:user, display_name: 'Editor') }
  let(:work) { create(:work) }
  let(:page) { create(:page, work: work, title: 'Current', source_text: 'current text', xml_text: '<p>current</p>', source_translation: 'current translation', xml_translation: '<p>current translation</p>', status: :transcribed) }

  before do
    allow(Flag).to receive(:check_page)
    allow_any_instance_of(Page).to receive(:update_work_stats)
  end

  def create_version(number, attrs = {})
    described_class.create!({
      page: page,
      user: user,
      page_version: number,
      title: "Version #{number}",
      transcription: "text #{number}",
      xml_transcription: "<p>#{number}</p>",
      source_translation: "translation #{number}",
      xml_translation: "<p>translation #{number}</p>",
      created_on: Time.zone.local(2024, 1, number + 1)
    }.merge(attrs))
  end

  describe 'navigation' do
    it 'finds adjacent versions and the current version' do
      first = create_version(0)
      middle = create_version(1)
      last = create_version(2)

      expect(middle.prev).to eq(first)
      expect(middle.next).to eq(last)
      expect(middle.current_version?).to be false
      expect(last.current_version?).to be true
    end
  end

  describe '#display' do
    it 'formats the timestamp and user name' do
      version = create_version(0, created_on: Time.zone.local(2024, 1, 2))

      expect(version.display).to eq('Jan 02, 2024 - Editor')
    end
  end

  describe '#expunge' do
    it 'restores the previous version when expunging the current version' do
      previous = create_version(0, title: 'Previous', transcription: 'previous text', xml_transcription: '<p>previous</p>', source_translation: 'previous translation', xml_translation: '<p>previous translation</p>')
      current = create_version(1)

      current.expunge

      expect(page.reload).to have_attributes(
        title: previous.title,
        source_text: previous.transcription,
        xml_text: previous.xml_transcription,
        source_translation: previous.source_translation,
        xml_translation: previous.xml_translation,
        status: 'new'
      )
    end

    it 'blanks the page when expunging the only version' do
      only = create_version(0)

      only.expunge

      expect(page.reload).to have_attributes(title: nil, source_text: nil, xml_text: nil, source_translation: nil, xml_translation: nil, status: 'new')
    end

    it 'renumbers later versions when expunging a non-current version' do
      create_version(0)
      middle = create_version(1)
      last = create_version(2)

      middle.expunge

      expect(last.reload.page_version).to eq(1)
    end
  end
end
