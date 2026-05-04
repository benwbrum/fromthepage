require 'spec_helper'

describe StaticSiteExporter do
  # Create a minimal test class that includes the module
  let(:exporter) do
    Class.new do
      include StaticSiteExporter
    end.new
  end

  describe '#write_index_markdown' do
    let(:out) { double('zip_output_stream', put_next_entry: nil, write: nil) }

    context 'when collection has a nil intro_block' do
      let(:collection) { build_stubbed(:collection, intro_block: nil) }

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
      let(:collection) { build_stubbed(:collection, intro_block: "Some intro text") }

      it 'writes the YAML front matter with the intro block content' do
        exporter.write_index_markdown('export', out, collection)
        expect(out).to have_received(:write).with("---\nSome intro text")
      end
    end
  end
end
