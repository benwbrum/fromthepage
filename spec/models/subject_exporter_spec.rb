require 'spec_helper'

RSpec.describe SubjectExporter do
  describe 'sections export' do
    
    let(:categories) { FactoryBot.build_stubbed_list(:category, 3, title: 'Category') }

    let(:article_a)  { FactoryBot.build_stubbed(:article, title: 'Article A', categories: categories) }
    let(:article_b)  { FactoryBot.build_stubbed(:article, title: 'Article B', categories: categories) }

    let(:links_a)    { FactoryBot.build_stubbed_list(:page_article_link, 2, display_text: 'display_text_a', article: article_a) }
    let(:links_b)    { FactoryBot.build_stubbed_list(:page_article_link, 2, display_text: 'display_text_b', article: article_b) }

    let(:page_1)     { FactoryBot.build_stubbed(:page, title: 'Page 1', position: '1', page_article_links: links_a) }
    let(:page_2)     { FactoryBot.build_stubbed(:page, title: 'Page 2', position: '2', page_article_links: links_b) }

    let(:work_1)     { FactoryBot.build_stubbed(:work, title: 'Work 1', identifier: 'work_id_1', pages: [page_1]) }
    let(:work_2)     { FactoryBot.build_stubbed(:work, title: 'Work 2', identifier: 'work_id_2', pages: [page_2]) }

    let(:collection) { FactoryBot.build_stubbed(:collection, works: [work_1, work_2]) }
    it 'exports headers for a blank collection' do
      subjects = SubjectExporter.new(collection)
      expect(subjects.export).to include('Work_Title')
      expect(subjects.export).to include('Identifier')
      expect(subjects.export).to include('Page_Title')
      expect(subjects.export).to include('Page_Position')
      expect(subjects.export).to include('Page_URL')
      expect(subjects.export).to include('Subject')
      expect(subjects.export).to include('Text')
      expect(subjects.export).to include('Category')
      expect(subjects.export).to include('"Work 1","work_id_1"')
      expect(subjects.export).to include('"Work 2","work_id_2"')
      expect(subjects.export).to include('"Page 1","1"')
      expect(subjects.export).to include('"Page 2","2"')
      expect(subjects.export).to include('"Article A","display_text_a"')
      expect(subjects.export).to include('"Article B","display_text_b"')
      expect(subjects.export).to include('"Category|Category|Category"')
    end
  end
end
