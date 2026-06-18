require 'spec_helper'

RSpec.describe ExportService do
  subject(:exporter) { Class.new { include ExportService }.new }

  describe '#path_from_work' do
    it 'uses the uploaded filename without extension when original filenames are requested' do
      work = instance_double(Work, uploaded_filename: '/tmp/original scan.tif', slug: 'fallback-slug')

      expect(exporter.path_from_work(work, true)).to eq('original scan')
    end

    it 'falls back to the truncated slug when original filenames are not requested' do
      work = instance_double(Work, uploaded_filename: '/tmp/original.tif', slug: 'a' * 250)

      expect(exporter.path_from_work(work, false)).to eq('a' * 200)
    end

    it 'falls back to the slug when uploaded filename is blank' do
      work = instance_double(Work, uploaded_filename: '', slug: 'work-slug')

      expect(exporter.path_from_work(work, true)).to eq('work-slug')
    end
  end

  describe 'CSV wrapper exports' do
    it 'writes the owner mailing list CSV' do
      owner = instance_double(User)
      allow(exporter).to receive(:owner_mailing_list_csv).with(owner).and_return('mailing csv')
      allow(exporter).to receive(:write_artifact)

      exporter.export_owner_mailing_list_csv(path: '/tmp/export', owner: owner)

      expect(exporter).to have_received(:write_artifact).with(
        base: '/tmp/export',
        relative: 'mailing_list.csv',
        content: 'mailing csv'
      )
    end

    it 'writes the admin searches CSV with parsed report dates' do
      allow(exporter).to receive(:admin_searches_csv).and_return('search csv')
      allow(exporter).to receive(:write_artifact)
      report_arguments = { 'start_date' => '2026-01-01', 'end_date' => '2026-01-02' }

      exporter.export_admin_searches_csv(path: '/tmp/export', report_arguments: report_arguments)

      expect(exporter).to have_received(:admin_searches_csv).with(
        DateTime.parse('2026-01-01'),
        DateTime.parse('2026-01-02')
      )
      expect(exporter).to have_received(:write_artifact).with(
        base: '/tmp/export',
        relative: 'admin_searches.csv',
        content: 'search csv'
      )
    end

    it 'writes subject index CSV content from the collection' do
      work = instance_double(Work)
      collection = instance_double(Collection, export_subject_index_as_csv: 'subject csv')
      allow(collection).to receive(:export_subject_index_as_csv).with(work).and_return('subject csv')
      allow(exporter).to receive(:write_artifact)

      exporter.export_subject_csv(path: '/tmp/export', collection: collection, work: work)

      expect(exporter).to have_received(:write_artifact).with(
        base: '/tmp/export',
        relative: 'subject_index.csv',
        content: 'subject csv'
      )
    end
  end

  describe '#export_plaintext_transcript' do
    let(:collection) { instance_double(Collection, subjects_disabled: true) }
    let(:work) do
      instance_double(
        Work,
        uploaded_filename: '',
        slug: 'work-slug',
        collection: collection,
        verbatim_transcription_plaintext: 'verbatim text',
        emended_transcription_plaintext: 'expanded text',
        searchable_plaintext: 'searchable text'
      )
    end

    before { allow(exporter).to receive(:write_artifact) }

    it 'writes by-work verbatim transcripts' do
      exporter.export_plaintext_transcript(
        work: work,
        name: 'verbatim',
        path: '/tmp/export',
        by_work: true,
        original_filenames: false
      )

      expect(exporter).to have_received(:write_artifact).with(
        base: '/tmp/export',
        relative: File.join('work-slug', 'plaintext', 'verbatim_transcript.txt'),
        content: 'verbatim text'
      )
    end

    it 'writes flattened searchable transcripts' do
      exporter.export_plaintext_transcript(
        work: work,
        name: 'searchable',
        path: '/tmp/export',
        by_work: false,
        original_filenames: false
      )

      expect(exporter).to have_received(:write_artifact).with(
        base: '/tmp/export',
        relative: File.join('plaintext_transcript_searchable', 'work-slug.txt'),
        content: 'searchable text'
      )
    end

    it 'skips expanded transcripts when subjects are enabled' do
      allow(collection).to receive(:subjects_disabled).and_return(false)

      exporter.export_plaintext_transcript(
        work: work,
        name: 'expanded',
        path: '/tmp/export',
        by_work: false,
        original_filenames: false
      )

      expect(exporter).not_to have_received(:write_artifact)
    end
  end

  describe '#write_artifact' do
    it 'creates parent directories and writes content' do
      Dir.mktmpdir do |dir|
        exporter.send(:write_artifact, base: dir, relative: 'nested/file.txt', content: 'hello')

        expect(File.read(File.join(dir, 'nested', 'file.txt'))).to eq('hello')
      end
    end
  end
end
