require 'spec_helper'

RSpec.describe SubjectExporter do
  describe 'sections export' do

    let(:collection) { FactoryBot.build_stubbed(:collection) }
    it 'exports headers for a blank collection' do
      subjects = SubjectExporter.new(FactoryBot.build_stubbed(:collection))
      expect(subjects.export).to include('Work_Title')
      expect(subjects.export).to include('Identifier')
      expect(subjects.export).to include('Page_Title')
      expect(subjects.export).to include('Page_Position')
      expect(subjects.export).to include('Page_URL')
      expect(subjects.export).to include('Subject')
      expect(subjects.export).to include('Text')
      expect(subjects.export).to include('Category')
    end
    it 'should include work, page, link, article, and category data' do
      collection_with_works = FactoryBot.build_stubbed(:collection, :with_links)
      subjects = SubjectExporter.new(collection_with_works)
      expect(subjects.export).to include('"Work 1","work_id_1","Page 1"')
      expect(subjects.export).to include('Page 1')
      expect(subjects.export).to include('"Article 1","display_text_1"')
      expect(subjects.export).to include('"Category 1|Category 2|Category 3"')
    end
    it 'should include section title'
    it 'should include section id'
  end
end
