require 'spec_helper'

RSpec.describe Flag, type: :model do
  let(:normal_user) { create(:user) }
  let(:owner) { create(:user, :owner) }

  before { allow(Flagger).to receive(:check) }

  describe '.check_page' do
    let(:version) { build_stubbed(:page_version, user: normal_user, transcription: 'spam text', created_on: Time.current) }

    it 'creates a regex flag for matching normal-user content' do
      allow(Flagger).to receive(:check).with('spam text').and_return('spam')

      expect { described_class.check_page(version) }.to change(described_class, :count).by(1)
      expect(described_class.last).to have_attributes(page_version: version, author_user: normal_user, provenance: described_class::Provenance::REGEX, snippet: 'spam', content_at: version.created_on)
    end

    it 'does not create a flag without a match' do
      allow(Flagger).to receive(:check).and_return(nil)

      expect { described_class.check_page(version) }.not_to change(described_class, :count)
    end

    it 'skips owner content' do
      version = build_stubbed(:page_version, user: owner, transcription: 'spam text')

      described_class.check_page(version)

      expect(Flagger).not_to have_received(:check)
    end
  end

  describe '.check_article' do
    it 'creates a regex flag for matching article content' do
      version = build_stubbed(:article_version, user: normal_user, source_text: 'spam text', created_on: Time.current)
      allow(Flagger).to receive(:check).with('spam text').and_return('spam')

      expect { described_class.check_article(version) }.to change(described_class, :count).by(1)
      expect(described_class.last).to have_attributes(article_version: version, author_user: normal_user, provenance: described_class::Provenance::REGEX, snippet: 'spam')
    end
  end

  describe '#mark_ok!' do
    it 'marks the flag as a false positive audited by the current user' do
      auditor = create(:user)
      flag = create(:flag, author_user: normal_user)
      Current.user = auditor

      flag.mark_ok!

      expect(flag.reload).to have_attributes(auditor_user: auditor, status: described_class::Status::FALSE_POSITIVE)
    ensure
      Current.user = nil
    end
  end

  describe '#ok_user' do
    it 'marks all flags by the same author as false positives' do
      auditor = create(:user)
      flags = create_list(:flag, 2, author_user: normal_user)
      create(:flag, author_user: create(:user))
      Current.user = auditor

      flags.first.ok_user

      expect(flags.map { |flag| flag.reload.status }).to all(eq(described_class::Status::FALSE_POSITIVE))
      expect(flags.map { |flag| flag.reload.auditor_user_id }).to all(eq(auditor.id))
    ensure
      Current.user = nil
    end
  end

  describe '#revert_content!' do
    it 'expunges page-version content and confirms the flag' do
      auditor = create(:user)
      page_version = build_stubbed(:page_version)
      flag = create(:flag, page_version: page_version)
      allow(page_version).to receive(:expunge)
      Current.user = auditor

      flag.revert_content!

      expect(page_version).to have_received(:expunge)
      expect(flag.reload).to have_attributes(auditor_user: auditor, status: described_class::Status::CONFRIMED)
    ensure
      Current.user = nil
    end
  end
end
