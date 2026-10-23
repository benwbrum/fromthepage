require 'spec_helper'

RSpec.describe 'Page ALTO XML route' do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:page) { create(:page, :with_image, work: work) }
  let(:alto_source) do
    <<~XML
      <alto>
        <Layout>
          <Page>
            <PrintSpace>
              <TextBlock>
                <TextLine>
                  <String CONTENT="ALTO text for this page"/>
                </TextLine>
              </TextBlock>
            </PrintSpace>
          </Page>
        </Layout>
      </alto>
    XML
  end

  before do
    create(:ai_transcription, page: page, model: AiTranscription::ALTO_MODEL, prompt: alto_source)
  end

  it 'returns valid ALTO XML for the page' do
    get collection_alto_xml_path(owner, collection, work, page)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include('text/xml')

    xml = Nokogiri::XML(response.body)

    expect(xml.errors).to be_empty
    expect(xml.at_xpath('//String')['CONTENT']).to eq('ALTO text for this page')
    expect(xml.at_xpath('//String')['ID']).to eq('string_0')
  end
end
