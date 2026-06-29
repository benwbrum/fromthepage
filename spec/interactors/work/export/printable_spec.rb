require 'spec_helper'

describe Work::Export::Printable do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, title: 'Special-Tags-Collection') }
  let!(:work) { create(:work, title: 'Special-Tags-Work', collection: collection, owner_user_id: owner.id) }

  let(:source_text) do
    File.read(Rails.root.join('test_data', 'transcripts', 'special_tags.txt'))
  end

  let(:tex_text) do
    File.read(Rails.root.join('test_data', 'transcripts', 'special_tags.tex.erb'))
  end

  let!(:page) do
    page = create(:page, title: 'Special Tags Page', work: work, search_text: 'Search text', status: :transcribed)
    page.update!(source_text: source_text)

    page
  end
  let!(:deed) { create(:deed, deed_type: DeedType::WORK_ADDED, work: work, collection: collection, user: owner) }

  let(:format) { 'pdf' }
  let(:time) { Time.now.utc }

  let!(:expected_tex_string) do
    renderer = ERB.new(tex_text)
    renderer.result_with_hash(
      made_on: time,
      created_on: work.created_on.to_s,
      identifier: Work::Export::Lib::Utils.latex_escape(
        work.merge_metadata.select { |hash| hash["label"] == "Identifier" }.first["value"]
      ),
      owner_display_name: Work::Export::Lib::Utils.latex_escape(owner.real_name || owner.display_name),
      last_article_id: page.articles.last.id
    )
  end

  let(:result) do
    described_class.new(
      work: work,
      format: format,
      edition: 'text',
      include_metadata: true,
      include_contributors: true,
      include_notes: true,
      preserve_lb: false,
      time: time
    ).call
  end

  context 'when pdf' do
    it 'creates base tex' do
      expect(result.success?).to be_truthy
      expect(result.tex_string.rstrip).to eq(expected_tex_string.rstrip)
      expect(File.exist?(result.file)).to be_truthy
    end
  end

  context 'when doc' do
    let(:format) { 'doc' }
    it 'creates base tex' do
      expect(result.success?).to be_truthy
      expect(result.tex_string.rstrip).to eq(expected_tex_string.rstrip)
      expect(File.exist?(result.file)).to be_truthy
    end
  end

  context 'when html' do
    let(:format) { 'html' }
    it 'creates base tex' do
      expect(result.success?).to be_truthy
      expect(result.tex_string.rstrip).to eq(expected_tex_string.rstrip)
      expect(File.exist?(result.file)).to be_truthy
    end
  end

  describe 'output file validation' do
    subject(:exporter) do
      described_class.new(
        work: work,
        format: 'pdf',
        edition: 'text',
        include_metadata: true,
        include_contributors: true,
        include_notes: true,
        preserve_lb: false,
        time: time
      )
    end

    context 'when pandoc exits 0 but produces no output file' do
      before do
        # Stub system() so pandoc "succeeds" without running, leaving no output file
        allow(exporter).to receive(:system).and_return(true)
      end

      it 'returns failure' do
        result = exporter.call

        expect(result.success?).to be_falsey
      end

      it 'sets an error indicating no output was produced' do
        result = exporter.call

        expect(result.full_errors).not_to be_nil
        expect(result.full_errors.message).to include('no output')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/empty or missing output file/)
        exporter.call
      end
    end

    context 'when pandoc exits 0 but produces an empty output file' do
      before do
        allow(exporter).to receive(:system) do
          # Simulate pandoc creating an empty output file
          FileUtils.touch(exporter.file)
          true
        end
      end

      it 'returns failure' do
        result = exporter.call

        expect(result.success?).to be_falsey
      end

      it 'sets an error indicating no output was produced' do
        result = exporter.call

        expect(result.full_errors).not_to be_nil
        expect(result.full_errors.message).to include('no output')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/empty or missing output file/)
        exporter.call
      end
    end
  end

  describe '#tex_string_for_conversion' do
    subject(:exporter) do
      described_class.new(
        work: work,
        format: format,
        edition: 'text',
        include_metadata: true,
        include_contributors: true,
        include_notes: true,
        preserve_lb: false,
        time: time
      )
    end

    context 'when format is not pdf' do
      let(:format) { 'doc' }

      it 'returns the original tex string' do
        expect(exporter.tex_string_for_conversion).to eq(exporter.tex_string)
      end
    end

    context 'when format is pdf' do
      let(:format) { 'pdf' }
      let(:tex_without_metadata) { "\\documentclass{article}\n\\begin{document}\n" }

      it 'removes the document metadata wrapper before conversion' do
        sanitized_tex = exporter.tex_string_for_conversion

        expect(sanitized_tex).not_to include("\\ifdefined\\DocumentMetadata")
        expect(sanitized_tex).not_to include("\\DocumentMetadata{")
        expect(sanitized_tex).to include("\\documentclass{article}")
      end

      it 'returns the original tex when no metadata wrapper exists' do
        allow(exporter).to receive(:tex_string).and_return(tex_without_metadata)

        expect(exporter.tex_string_for_conversion).to eq(tex_without_metadata)
      end

      it 'removes metadata wrapper with varying whitespace and multiline content' do
        allow(exporter).to receive(:tex_string).and_return(<<~TEX)
            \\ifdefined\\DocumentMetadata
            \\DocumentMetadata{
              lang=en,
              pdftitle={A title with {nested} braces}
            }
            \\fi
          \\documentclass{article}
          \\begin{document}
        TEX

        expect(exporter.tex_string_for_conversion).to eq(<<~TEX)
          \\documentclass{article}
          \\begin{document}
        TEX
      end
    end
  end
end
