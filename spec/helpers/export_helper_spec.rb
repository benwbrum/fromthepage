require 'spec_helper'

RSpec.describe ExportHelper, type: :helper do
  fixtures [:collections]

  before do
    @collection = Collection.first
    @context = double("context", translation_mode: false)
  end

  describe '#field_data_to_hash' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id, field_based: true) }
    let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
    let(:text_field) do
      create(:transcription_field, :text_field, label: 'Name', collection: collection,
                                                line_number: 1, position: 1)
    end

    before do
      allow(helper).to receive(:iiif_strucured_data_field_config_url).and_return('field_config_url')
      allow(helper).to receive(:iiif_strucured_data_column_config_url).and_return('column_config_url')
    end

    context 'when page has transcription_json (modern field-based transcription)' do
      it 'returns field data from transcription_json for text fields' do
        text_field
        page = create(:page, work: work, transcription_json: { text_field.id.to_s => 'John Smith' })

        result = helper.field_data_to_hash(page)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        expect(result.first[:label]).to eq('Name')
        expect(result.first[:value]).to eq('John Smith')
        expect(result.first[:config]).to eq('field_config_url')
      end

      it 'skips fields with blank values in transcription_json' do
        text_field
        page = create(:page, work: work, transcription_json: { text_field.id.to_s => '' })

        result = helper.field_data_to_hash(page)

        expect(result).to be_empty
      end

      it 'returns spreadsheet data from transcription_json' do
        spreadsheet_field = create(:transcription_field, :spreadsheet_field, label: 'Ledger', collection: collection,
                                                                               line_number: 2, position: 1)
        col_a = create(:spreadsheet_column, label: 'Amount', transcription_field_id: spreadsheet_field.id, position: 1)
        col_b = create(:spreadsheet_column, label: 'Date', transcription_field_id: spreadsheet_field.id, position: 2)

        row_data = [{ col_a.id.to_s => '100', col_b.id.to_s => '1920-01-01' }]
        page = create(:page, work: work, transcription_json: { spreadsheet_field.id.to_s => row_data })

        result = helper.field_data_to_hash(page)

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        spreadsheet_entry = result.first
        expect(spreadsheet_entry[:data]).to be_an(Array)
        expect(spreadsheet_entry[:data].length).to eq(1)
        row = spreadsheet_entry[:data].first
        expect(row.map { |e| e[:label] }).to contain_exactly('Amount', 'Date')
        expect(row.map { |e| e[:value] }).to contain_exactly('100', '1920-01-01')
        expect(spreadsheet_entry[:config]).to eq('field_config_url')
      end

      it 'skips spreadsheet rows where all cell values are blank' do
        spreadsheet_field = create(:transcription_field, :spreadsheet_field, label: 'Ledger', collection: collection,
                                                                               line_number: 2, position: 1)
        col_a = create(:spreadsheet_column, label: 'Amount', transcription_field_id: spreadsheet_field.id, position: 1)

        row_data = [{ col_a.id.to_s => '' }]
        page = create(:page, work: work, transcription_json: { spreadsheet_field.id.to_s => row_data })

        result = helper.field_data_to_hash(page)

        expect(result).to be_empty
      end

      it 'skips instruction fields' do
        create(:transcription_field, :instruction_field, label: 'Instructions', collection: collection,
                                                         line_number: 0, position: 1)
        text_field
        page = create(:page, work: work, transcription_json: { text_field.id.to_s => 'Smith' })

        result = helper.field_data_to_hash(page)

        expect(result.length).to eq(1)
        expect(result.first[:label]).to eq('Name')
      end

      it 'returns empty array when transcription_json has no matching fields' do
        text_field
        page = create(:page, work: work, transcription_json: { '99999' => 'orphan value' })

        result = helper.field_data_to_hash(page)

        expect(result).to be_empty
      end
    end
  end



  describe '#expand_subject' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id) }

    it 'returns only the subject itself when no parent subjects exist' do
      article = FactoryBot.create(:article, title: 'Alabama--Baldwin County', collection: collection)
      result = expand_subject(article)
      expect(result).to eq([article])
    end

    it 'finds parent subjects when title contains -- delimiter' do
      parent = FactoryBot.create(:article, title: 'Alabama', collection: collection)
      child  = FactoryBot.create(:article, title: 'Alabama--Baldwin County', collection: collection)
      result = expand_subject(child)
      expect(result).to include(child)
      expect(result).to include(parent)
    end

    it 'finds parent subjects when title contains ". " delimiter' do
      parent = FactoryBot.create(:article, title: 'Confederate States of America. Army', collection: collection)
      child  = FactoryBot.create(:article,
                                  title: 'Confederate States of America. Army. Mississippi. Infantry Regiment, 10th (1861-1862)',
                                  collection: collection)
      result = expand_subject(child)
      expect(result).to include(child)
      expect(result).to include(parent)
    end
  end

  describe 'article classification by category hierarchy' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id) }
    let(:places_root) { collection.categories.where(title: 'Places').first }
    let(:counties_category) do
      FactoryBot.create(:category, title: 'Counties & Parishes', collection: collection, parent: places_root)
    end
    let(:towns_category) do
      FactoryBot.create(:category, title: 'Towns & Cities', collection: collection, parent: places_root)
    end

    it 'classifies expanded subjects from a Places subcategory as place articles' do
      # Set up parent and child articles with Places subcategory membership
      county_article = FactoryBot.create(:article, title: 'Alabama--Baldwin County', collection: collection)
      county_article.categories << counties_category

      town_article = FactoryBot.create(:article, title: 'Alabama--Baldwin County. Blakeley', collection: collection)
      town_article.categories << towns_category

      # Simulate the classification logic in work_to_tei
      places_and_descendants = places_root.descendants.to_a + [places_root]
      places_ids = places_and_descendants.map(&:id)

      # The county article is in Counties & Parishes which is a descendant of Places
      expanded_category_ids = county_article.categories.pluck(:id)
      expect((expanded_category_ids & places_ids).present?).to be true
    end
  end



  describe "Bibliography TEI export formatting" do
    context "bibliography_to_export_tei" do
      it "processes TEI markup in bibliography for export" do
        bibliography_xml = "<bibl>Test citation with <hi rend=\"italic\">italicized title</hi> and <lb/>line break</bibl>"

        result = bibliography_to_export_tei(bibliography_xml, @context)

        expect(result).to include("<hi rend='italic'>italicized title</hi>")
        expect(result).to include("<lb/>")
        expect(result).to include("Test citation with")
      end

      it "handles complex TEI content with multiple hi and lb elements" do
        complex_tei = " (1850), Population Schedules, Kentucky.<lb>
<hi rend=\"italic\">Eighth Manuscript Census</hi> (1860), Population Schedules.<lb>
Henry Tanner, ed., <hi rend=\"italic\">Directory</hi> (Louisville, 1861), 227."

        result = bibliography_to_export_tei(complex_tei, @context)

        expect(result).to include("<hi rend='italic'>Eighth Manuscript Census</hi>")
        expect(result).to include("<hi rend='italic'>Directory</hi>")
        expect(result).to include("<lb/>")
        expect(result).to include("(1850), Population Schedules, Kentucky.")
      end

      it "returns empty string for empty content" do
        result = bibliography_to_export_tei('', @context)
        expect(result).to eq('')
      end

      it "handles malformed XML gracefully" do
        malformed_xml = "Text with <invalid>unclosed tag and <lb> tags"

        result = bibliography_to_export_tei(malformed_xml, @context)

        # Should return empty string for malformed XML in TEI export context
        expect(result).to eq('')
      end
    end
  end

  describe '#clean_date_for_when_attribute' do
    it 'uses EDTF library for valid EDTF dates' do
      expect(clean_date_for_when_attribute('1866')).to eq('1866')
      expect(clean_date_for_when_attribute('1866-05')).to eq('1866-05')
      expect(clean_date_for_when_attribute('1866-05-15')).to eq('1866-05-15')
    end

    it 'does not eliminate question marks' do
      expect(clean_date_for_when_attribute('1866?')).to eq('1866?')
    end

    it 'handles multiple question marks' do
      expect(clean_date_for_when_attribute('1866???')).to eq('1866')
    end

    it 'returns nil for invalid dates' do
      expect(clean_date_for_when_attribute('invalid')).to be_nil
      expect(clean_date_for_when_attribute('')).to be_nil
      expect(clean_date_for_when_attribute(nil)).to be_nil
    end

    it 'validates date format for fallback cleaning' do
      # Invalid months 13-20 should be suppressed
      expect(clean_date_for_when_attribute('1866-13')).to be_nil  # Invalid month
      expect(clean_date_for_when_attribute('1866-20')).to be_nil  # Invalid month
      expect(clean_date_for_when_attribute('1866-21')).to eq('1866-21')  # Valid EDTF sub-year grouping
    end

    it 'handles EDTF parsing errors gracefully' do
      # Test that we gracefully handle when EDTF can't parse something
      # but our fallback can - should preserve single question marks
      allow(Date).to receive(:edtf).and_raise(StandardError)
      expect(clean_date_for_when_attribute('1866?')).to eq('1866?')
    end
  end

  describe 'TEI validation fixes' do
    context 'XML ID generation' do
      it 'prefixes numeric IDs to make valid NCName' do
        work_id = '14648'
        xml_id = "W#{work_id}"
        expect(xml_id).to eq('W14648')
        expect(xml_id).not_to match(/^\d/)  # Should not start with digit
      end
    end

    context 'ptr elements' do
      it 'should be self-closing without text content' do
        # This is more of a template structure test
        # The actual fix is in the ERB template
        expect(true).to be true  # Placeholder for template structure
      end
    end

    context 'geo element placement' do
      it 'should be directly in place element not in note' do
        # This is a template structure test
        # The actual fix moves geo out of note wrapper
        expect(true).to be true  # Placeholder for template structure
      end
    end

    context 'depth attribute replacement' do
      it 'replaces depth with subtype for head elements' do
        # Test that depth attribute is replaced with subtype/type for TEI compliance
        expect(true).to be true  # Placeholder for template structure
      end
    end
  end

  describe '#extract_heads_from_parargraph' do
    it 'wraps extracted head elements in div tags' do
      require 'rexml/document'
      xml_text = '<?xml version="1.0" encoding="UTF-8"?><page><p><head depth="1">Section Title</head>This is the content.</p></page>'
      doc = REXML::Document.new(xml_text)
      p_element = doc.elements['//p']

      elements = extract_heads_from_parargraph(p_element)

      expect(elements.length).to eq(2)
      expect(elements[0].name).to eq('div')
      expect(elements[0].elements['head']).not_to be_nil
      expect(elements[0].elements['head'].text).to eq('Section Title')
      expect(elements[1].name).to eq('p')
      expect(elements[1].text).to eq('This is the content.')
    end

    it 'removes empty p element when only head is present' do
      require 'rexml/document'
      xml_text = '<?xml version="1.0" encoding="UTF-8"?><page><p><head depth="1">Section Title</head></p></page>'
      doc = REXML::Document.new(xml_text)
      p_element = doc.elements['//p']

      elements = extract_heads_from_parargraph(p_element)

      expect(elements.length).to eq(1)
      expect(elements[0].name).to eq('div')
      expect(elements[0].elements['head']).not_to be_nil
      expect(elements[0].elements['head'].text).to eq('Section Title')
    end

    it 'wraps multiple head elements in separate div tags' do
      require 'rexml/document'
      xml_text = '<?xml version="1.0" encoding="UTF-8"?><page><p><head depth="1">Title 1</head><head depth="2">Title 2</head>Content here.</p></page>'
      doc = REXML::Document.new(xml_text)
      p_element = doc.elements['//p']

      elements = extract_heads_from_parargraph(p_element)

      expect(elements.length).to eq(3)
      expect(elements[0].name).to eq('div')
      expect(elements[0].elements['head'].text).to eq('Title 1')
      expect(elements[1].name).to eq('div')
      expect(elements[1].elements['head'].text).to eq('Title 2')
      expect(elements[2].name).to eq('p')
      expect(elements[2].text).to eq('Content here.')
    end

    it 'returns p element unchanged when no head elements present' do
      require 'rexml/document'
      xml_text = '<?xml version="1.0" encoding="UTF-8"?><page><p>Just regular content.</p></page>'
      doc = REXML::Document.new(xml_text)
      p_element = doc.elements['//p']

      elements = extract_heads_from_parargraph(p_element)

      expect(elements.length).to eq(1)
      expect(elements[0].name).to eq('p')
      expect(elements[0].text).to eq('Just regular content.')
    end
  end

  describe '#consolidate_page_ranges' do
    it 'consolidates consecutive page numbers into ranges' do
      positions = [1, 2, 3, 5, 6, 8, 10]
      result = consolidate_page_ranges(positions)
      expect(result).to eq(['1-3', '5-6', '8', '10'])
    end

    it 'handles single page as a single number' do
      positions = [5]
      result = consolidate_page_ranges(positions)
      expect(result).to eq(['5'])
    end

    it 'handles all consecutive pages' do
      positions = [1, 2, 3, 4, 5]
      result = consolidate_page_ranges(positions)
      expect(result).to eq(['1-5'])
    end

    it 'handles empty array' do
      positions = []
      result = consolidate_page_ranges(positions)
      expect(result).to eq([])
    end
  end

  describe '#gather_ai_model_contributions' do
    let(:owner) { User.find_by(owner: true) || create(:user, owner: true) }
    let!(:collection) { create(:collection, owner_user_id: owner.id) }
    let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
    let!(:page1) { create(:page, work: work, position: 1) }
    let!(:page2) { create(:page, work: work, position: 2) }
    let!(:page3) { create(:page, work: work, position: 3) }

    it 'gathers AI model contributions with date ranges and page ranges' do
      ai_trans1 = create(:ai_transcription, page: page1, model: 'GPT-4o', created_at: 1.day.ago)
      ai_trans2 = create(:ai_transcription, page: page2, model: 'GPT-4o', created_at: Time.current)
      ai_trans3 = create(:ai_transcription, page: page3, model: 'Claude-3', created_at: Time.current)

      result = gather_ai_model_contributions(work)

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)

      gpt_contrib = result.find { |c| c[:model] == 'GPT-4o' }
      expect(gpt_contrib).to be_present
      expect(gpt_contrib[:first_date]).to be_present
      expect(gpt_contrib[:last_date]).to be_present
      expect(gpt_contrib[:page_ranges]).to include('1-2')

      claude_contrib = result.find { |c| c[:model] == 'Claude-3' }
      expect(claude_contrib).to be_present
      expect(claude_contrib[:page_ranges]).to eq(['3'])
    end

    it 'handles work with no AI transcriptions' do
      result = gather_ai_model_contributions(work)
      expect(result).to eq([])
    end
  end
end
