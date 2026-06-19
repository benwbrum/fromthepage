require 'spec_helper'

RSpec.describe ScCanvas, type: :model do
  describe '#thumbnail_url' do
    it 'uses the IIIF image API v1 native quality path' do
      canvas = described_class.new(sc_service_id: 'https://example.org/iiif/image/', sc_service_context: 'http://iiif.io/api/image/1/context.json')

      expect(canvas.thumbnail_url).to eq('https://example.org/iiif/image/full/100,/0/native.jpg')
    end

    it 'uses the default quality path for other IIIF image services' do
      canvas = described_class.new(sc_service_id: 'https://example.org/iiif/image/', sc_service_context: 'http://iiif.io/api/image/2/context.json')

      expect(canvas.thumbnail_url).to eq('https://example.org/iiif/image/full/100,/0/default.jpg')
    end

    it 'falls back to the resource id without a service id' do
      canvas = described_class.new(sc_resource_id: 'https://example.org/image.jpg')

      expect(canvas.thumbnail_url).to eq('https://example.org/image.jpg')
    end
  end

  describe '#facsimile_url' do
    it 'builds a full-size image URL from the service id' do
      canvas = described_class.new(sc_service_id: 'https://example.org/iiif/image')

      expect(canvas.facsimile_url).to eq('https://example.org/iiif/image/full/full/0/default.jpg')
    end

    it 'falls back to the resource id' do
      canvas = described_class.new(sc_resource_id: 'https://example.org/image.jpg')

      expect(canvas.facsimile_url).to eq('https://example.org/image.jpg')
    end
  end

  describe '#iiif_image_info_url' do
    it 'builds an info URL from the service id' do
      canvas = described_class.new(sc_service_id: 'https://example.org/iiif/image/')

      expect(canvas.iiif_image_info_url).to eq('https://example.org/iiif/image/info.json')
    end

    it 'treats NARA resources as plain images' do
      canvas = described_class.new(sc_resource_id: 'https://catalog.archives.gov/example.jpg')

      expect(JSON.parse(canvas.iiif_image_info_url)).to eq('type' => 'image', 'url' => 'https://catalog.archives.gov/example.jpg')
    end

    it 'derives an info URL from a conventional IIIF resource URL' do
      canvas = described_class.new(sc_resource_id: 'https://example.org/iiif/image/full/800/0/default.jpg')

      expect(canvas.iiif_image_info_url).to eq('https://example.org/iiif/image/info.json')
    end
  end

  describe '#transcript_annotations' do
    let(:plain_annotation) do
      {
        'data' => {
          '@type' => 'sc:AnnotationList',
          'resources' => [
            { 'data' => { 'resource' => { 'data' => { 'format' => 'text/plain', 'chars' => 'plain transcript' } } } }
          ]
        }
      }
    end

    let(:page_annotation) do
      {
        'data' => {
          '@type' => 'sc:AnnotationList',
          'textGranularity' => 'page',
          'resources' => [
            { 'data' => { 'resource' => { 'data' => { 'format' => 'text/html', 'chars' => 'line one<br>line two' } } } }
          ]
        }
      }
    end

    it 'prefers page-level annotation lists' do
      canvas = described_class.new(annotations: [plain_annotation, page_annotation].to_json)

      expect(canvas.transcript_annotations).to eq(page_annotation)
      expect(canvas.has_annotation?).to eq(page_annotation)
    end

    it 'uses any annotation list when no page-level annotation is present' do
      canvas = described_class.new(annotations: [plain_annotation].to_json)

      expect(canvas.transcript_annotations).to eq(plain_annotation)
    end

    it 'converts html transcript content to plain text with line breaks' do
      canvas = described_class.new(annotations: [page_annotation].to_json)

      expect(canvas.annotation_text_for_source).to eq("line one\nline two")
    end

    it 'returns plain transcript content unchanged' do
      canvas = described_class.new(annotations: [plain_annotation].to_json)

      expect(canvas.annotation_text_for_source).to eq('plain transcript')
    end
  end
end
