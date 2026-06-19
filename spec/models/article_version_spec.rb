require 'spec_helper'

RSpec.describe ArticleVersion, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, title: 'Current', source_text: 'current text', xml_text: '<p>current</p>') }

  before { allow(Flag).to receive(:check_article) }

  def create_version(number, attrs = {})
    described_class.create!({
      article: article,
      user: user,
      version: number,
      title: "Version #{number}",
      source_text: "text #{number}",
      xml_text: "<p>#{number}</p>",
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

  describe '#expunge' do
    it 'restores the previous version when expunging the current version' do
      previous = create_version(0, title: 'Previous', source_text: 'previous text', xml_text: '<p>previous</p>')
      current = create_version(1)

      current.expunge

      expect(article.reload).to have_attributes(title: previous.title, source_text: previous.source_text, xml_text: previous.xml_text)
    end

    it 'destroys the article when expunging the only version' do
      only = create_version(0)

      only.expunge

      expect(Article.exists?(article.id)).to be false
    end

    it 'renumbers later versions when expunging a non-current version' do
      create_version(0)
      middle = create_version(1)
      last = create_version(2)

      middle.expunge

      expect(last.reload.version).to eq(1)
    end
  end
end
