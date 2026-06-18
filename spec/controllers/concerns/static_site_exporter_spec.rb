require 'spec_helper'

RSpec.describe StaticSiteExporter do
  subject(:exporter) { Class.new { include StaticSiteExporter }.new }

  describe '#category_to_tree' do
    it 'builds nested category and subject nodes' do
      subject = instance_double(Article, id: 7, title: 'Subject')
      child = instance_double(Category, title: 'Child', children: [], articles: [subject])
      category = instance_double(Category, title: 'Parent', children: [child], articles: [])

      tree = exporter.send(:category_to_tree, category)

      expect(tree).to eq(
        'title' => 'Parent',
        'has_children' => true,
        'children' => [
          {
            'title' => 'Child',
            'has_children' => true,
            'children' => [
              { 'title' => 'Subject', 'url' => '/pages/subjects/7' }
            ]
          }
        ]
      )
    end

    it 'returns an empty children array for an empty category' do
      category = instance_double(Category, title: 'Empty', children: [], articles: [])

      expect(exporter.send(:category_to_tree, category)).to eq('title' => 'Empty', 'children' => [])
    end
  end

  describe '#write_config_yaml' do
    it 'writes Jekyll config content for a collection' do
      owner = instance_double(User, email: 'owner@example.com', display_name: 'Owner Name')
      collection = instance_double(Collection, title: 'Collection Title', owner: owner, intro_block: 'Intro text')
      allow(exporter).to receive(:write_static_artifact)

      exporter.send(:write_config_yaml, 'site', '/tmp/export', collection)

      expect(exporter).to have_received(:write_static_artifact) do |args|
        expect(args[:base]).to eq('/tmp/export')
        expect(args[:relative]).to eq('site/_config.yml')
        parsed = YAML.safe_load(args[:content])
        expect(parsed['title']).to eq('Collection Title')
        expect(parsed['email']).to eq('owner@example.com')
        expect(parsed['owner']).to eq('Owner Name')
        expect(parsed['description']).to eq('Intro text')
      end
    end
  end

  describe '#write_static_artifact' do
    it 'creates parent directories and writes content' do
      Dir.mktmpdir do |dir|
        exporter.send(:write_static_artifact, base: dir, relative: 'site/page.md', content: 'content')

        expect(File.read(File.join(dir, 'site', 'page.md'))).to eq('content')
      end
    end
  end
end
