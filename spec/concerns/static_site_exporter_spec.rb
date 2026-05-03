require 'spec_helper'

describe StaticSiteExporter do
  # Create a minimal test class that includes the module
  let(:exporter) do
    Class.new do
      include StaticSiteExporter
    end.new
  end

  let(:user) { create(:user) }

  describe '#write_index_markdown' do
    let(:out) { instance_double('Zip::OutputStream') }

    before do
      allow(out).to receive(:put_next_entry)
      allow(out).to receive(:write)
    end

    context 'when collection has a nil intro_block' do
      let(:collection) { create(:collection, intro_block: nil) }

      it 'does not raise an error' do
        expect {
          exporter.write_index_markdown('export', out, collection)
        }.not_to raise_error
      end

      it 'writes the YAML front matter delimiter without content' do
        exporter.write_index_markdown('export', out, collection)
        expect(out).to have_received(:write).with("---\n")
      end
    end

    context 'when collection has an intro_block' do
      let(:collection) { create(:collection, intro_block: "Some intro text") }

      it 'writes the YAML front matter with the intro block content' do
        exporter.write_index_markdown('export', out, collection)
        expect(out).to have_received(:write).with("---\nSome intro text")
      end
    end
  end
end
