require 'spec_helper'
require 'contentdm_translator'

RSpec.describe ContentdmTranslator do
  describe '#export_work_to_cdm' do
    let(:collection) { double('Collection') }
    let(:work) { double('Work', collection: collection, pages: [ page1, page2 ], sc_manifest: manifest) }
    let(:page1) { double('Page', sc_canvas: canvas1, title: 'Page 1', id: 1, verbatim_transcription_plaintext: 'Test content 1') }
    let(:page2) { double('Page', sc_canvas: canvas2, title: 'Page 2', id: 2, verbatim_transcription_plaintext: 'Test content 2') }
    let(:canvas1) { double('Canvas', sc_canvas_id: 'https://cdm17217.contentdm.oclc.org/iiif/supreme_court/3291/canvas/c1') }
    let(:canvas2) { double('Canvas', sc_canvas_id: 'https://cdm17217.contentdm.oclc.org/iiif/supreme_court/3292/canvas/c1') }
    let(:manifest) { double('Manifest', at_id: 'https://cdm17217.contentdm.oclc.org/iiif/info/supreme_court/7076/manifest.json') }

    before do
      allow(ContentdmTranslator).to receive(:fts_field_for_collection).and_return([ nil, 'transc' ])
      allow(ContentdmTranslator).to receive(:cdm_collection).and_return('supreme_court')
      allow(ContentdmTranslator).to receive(:cdm_record).with(canvas1.sc_canvas_id).and_return('3291')
      allow(ContentdmTranslator).to receive(:cdm_record).with(canvas2.sc_canvas_id).and_return('3292')
      allow(ContentdmTranslator).to receive(:cdm_server).and_return('server17217.contentdm.oclc.org')
      # Suppress output during tests
      allow(ContentdmTranslator).to receive(:puts)
    end

    context 'when CONTENTdm returns a locked object error' do
      it 'should skip the locked page and continue to the next page' do
        # Mock the SOAP client
        soap_client = double('SoapClient')
        allow(Savon).to receive(:client).and_return(soap_client)

        # Mock responses - first page locked, second page success
        locked_response = double('Response',
          to_hash: {
            process_conten_tdm_response: {
              return: 'Error detail: This item is currently locked - 3291.'
            }
          }
        )
        success_response = double('Response',
          to_hash: {
            process_conten_tdm_response: {
              return: 'Success'
            }
          }
        )

        allow(soap_client).to receive(:call).and_return(locked_response, success_response)

        # Expect the method to handle locked items gracefully
        expect {
          ContentdmTranslator.export_work_to_cdm(work, 'username', 'password', 'license')
        }.not_to raise_error

        # Verify that both pages were attempted
        expect(soap_client).to have_received(:call).exactly(2).times

        # Verify locked item message was logged
        expect(ContentdmTranslator).to have_received(:puts).with('Skipping locked item: Error detail: This item is currently locked - 3291.')
      end
    end

    context 'when SOAP call raises an exception' do
      it 'should skip the problematic page and continue to the next page' do
        soap_client = double('SoapClient')
        allow(Savon).to receive(:client).and_return(soap_client)

        # First page raises exception, second page succeeds
        success_response = double('Response',
          to_hash: {
            process_conten_tdm_response: {
              return: 'Success'
            }
          }
        )

        allow(soap_client).to receive(:call).and_raise(StandardError.new('Connection error')).once
        allow(soap_client).to receive(:call).and_return(success_response).once

        # Should not raise error, but handle it gracefully
        expect {
          ContentdmTranslator.export_work_to_cdm(work, 'username', 'password', 'license')
        }.not_to raise_error

        # Verify error was logged
        expect(ContentdmTranslator).to have_received(:puts).with('Error processing page Page 1 (1): StandardError: Connection error')
        expect(ContentdmTranslator).to have_received(:puts).with('Skipping to next page...')
      end
    end

    context 'when Savon client is configured properly' do
      it 'should create client with underscore conversion instead of snakecase' do
        expected_config = hash_including(
          convert_response_tags_to: kind_of(Proc),
          log: true,
          filters: [ :password ],
          wsdl: 'https://worldcat.org/webservices/contentdm/catcher?wsdl',
          follow_redirects: true
        )

        soap_client = double('SoapClient')
        allow(soap_client).to receive(:call).and_return(
          double('Response', to_hash: { process_conten_tdm_response: { return: 'Success' } })
        )

        expect(Savon).to receive(:client).with(expected_config).and_return(soap_client)

        ContentdmTranslator.export_work_to_cdm(work, 'username', 'password', 'license')
      end

      it 'should handle tag conversion properly with underscore fallback' do
        # Test the tag conversion lambda directly
        soap_client = double('SoapClient')
        allow(soap_client).to receive(:call).and_return(
          double('Response', to_hash: { process_conten_tdm_response: { return: 'Success' } })
        )

        # Capture the lambda passed to Savon
        tag_converter = nil
        allow(Savon).to receive(:client) do |config|
          tag_converter = config[:convert_response_tags_to]
          soap_client
        end

        ContentdmTranslator.export_work_to_cdm(work, 'username', 'password', 'license')

        # Test the lambda works with different inputs
        expect(tag_converter.call('TestTag')).to eq(:test_tag)
        expect(tag_converter.call('XMLResponse')).to eq(:xml_response)
        expect(tag_converter.call('simple')).to eq(:simple)
      end
    end
  end
end
