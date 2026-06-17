# frozen_string_literal: true

module Textract
  # Converts Amazon Textract DetectDocumentText response blocks into
  # a valid ALTO-XML string that is compatible with the existing
  # AltoTransformer, page_controller#alto_xml, and the OSD overlay.
  #
  # Textract block hierarchy (relevant types):
  #   PAGE  -> LINE  -> WORD
  #
  # ALTO element hierarchy:
  #   Page -> PrintSpace -> TextBlock -> TextLine -> String
  #
  # Because Textract does not produce paragraph-level groupings, all
  # TextLine elements are placed inside a single TextBlock that spans
  # the full page. This is sufficient for the OSD overlay and for
  # AltoTransformer.plaintext_from_alto_xml.
  #
  # Bounding-box geometry in Textract is expressed as fractions (0-1)
  # of the page dimensions. ALTO expects integer pixel values, so we
  # multiply by the supplied image width / height.
  class AltoBuilder
    ALTO_NS = 'http://www.loc.gov/standards/alto/ns-v2#'

    # @param blocks [Array<Hash>] The "Blocks" array from a Textract response.
    #   Each block is a plain Ruby Hash (already parsed from JSON / the AWS SDK
    #   struct converted via #to_h).
    # @param image_width [Integer] Pixel width of the source image.
    # @param image_height [Integer] Pixel height of the source image.
    def initialize(blocks, image_width:, image_height:)
      @blocks = blocks
      @image_width = image_width.to_i
      @image_height = image_height.to_i

      raise ArgumentError, 'image_width is required' if @image_width <= 0
      raise ArgumentError, 'image_height is required' if @image_height <= 0
    end

    # Builds and returns the ALTO-XML string.
    # @return [String]
    def build
      line_blocks = @blocks.select { |b| (b[:block_type] || b['block_type']) == 'LINE' }
      word_blocks = @blocks.select { |b| (b[:block_type] || b['block_type']) == 'WORD' }
      word_map = word_blocks.index_by { |b| b[:id] || b['id'] }

      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.alto(xmlns: ALTO_NS) do
          xml.Description do
            xml.MeasurementUnit 'pixel'
            xml.sourceImageInformation do
              xml.fileName ''
            end
            xml.OCRProcessing(ID: 'OCR_0') do
              xml.ocrProcessingStep do
                xml.processingSoftware do
                  xml.softwareName 'Amazon Textract'
                end
              end
            end
          end

          xml.Layout do
            xml.Page(
              ID: 'page_0',
              WIDTH: @image_width,
              HEIGHT: @image_height,
              PHYSICAL_IMG_NR: '0'
            ) do
              xml.PrintSpace(
                HPOS: 0,
                VPOS: 0,
                WIDTH: @image_width,
                HEIGHT: @image_height
              ) do
                xml.TextBlock(
                  ID: 'block_0',
                  HPOS: 0,
                  VPOS: 0,
                  WIDTH: @image_width,
                  HEIGHT: @image_height
                ) do
                  line_blocks.each_with_index do |line, line_index|
                    line_bbox = bbox_to_pixels(line[:geometry] || line['geometry'])

                    xml.TextLine(
                      ID: "line_#{line_index}",
                      HPOS: line_bbox[:hpos],
                      VPOS: line_bbox[:vpos],
                      WIDTH: line_bbox[:width],
                      HEIGHT: line_bbox[:height]
                    ) do
                      word_ids_for_block(line).each_with_index do |word_id, word_index|
                        word = word_map[word_id]
                        next unless word

                        word_bbox = bbox_to_pixels(word[:geometry] || word['geometry'])
                        word_content = word[:text] || word['text'] || ''
                        confidence = (word[:confidence] || word['confidence'])&.round(1)

                        attrs = {
                          ID: "word_#{line_index}_#{word_index}",
                          CONTENT: word_content,
                          HPOS: word_bbox[:hpos],
                          VPOS: word_bbox[:vpos],
                          WIDTH: word_bbox[:width],
                          HEIGHT: word_bbox[:height]
                        }
                        attrs[:WC] = (confidence / 100.0).round(4) if confidence

                        xml.String(**attrs)
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      builder.to_xml
    end

    private

    def word_ids_for_block(line_block)
      relationships = line_block[:relationships] || line_block['relationships'] || []
      child_rel = relationships.find { |r| (r[:type] || r['type']) == 'CHILD' }
      child_rel ? (child_rel[:ids] || child_rel['ids'] || []) : []
    end

    def bbox_to_pixels(geometry)
      return { hpos: 0, vpos: 0, width: 0, height: 0 } unless geometry

      bb = geometry[:bounding_box] || geometry['bounding_box'] || {}

      left = (bb[:left] || bb['left'] || 0).to_f
      top = (bb[:top] || bb['top'] || 0).to_f
      width = (bb[:width] || bb['width'] || 0).to_f
      height = (bb[:height] || bb['height'] || 0).to_f

      {
        hpos: (left * @image_width).round,
        vpos: (top * @image_height).round,
        width: (width * @image_width).round,
        height: (height * @image_height).round
      }
    end
  end
end
