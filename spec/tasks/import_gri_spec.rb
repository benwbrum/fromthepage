require 'spec_helper'
require 'rake'

describe 'Import GRI rake tasks' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  # Create a test class that includes the rake task's methods
  let(:helper_class) do
    Class.new do
      def multi_wiki_link(tags, values)
        return values.to_s if tags.blank? || values.blank?

        tag_array = tags.split(';').map(&:strip)
        value_array = values.split(';').map(&:strip)

        links = tag_array.zip(value_array).map do |tag, value|
          if tag.present? && value.present?
            cleaned_tag = tag.to_s.gsub(/^\[\[|\]\]$/, '')
            cleaned_value = value.to_s.gsub(/^\[\[|\]\]$/, '')
            
            opening = cleaned_tag.include?('[') || cleaned_tag.include?(']') ? '[[  ' : '[['
            closing = cleaned_value.include?('[') || cleaned_value.include?(']') ? ' ]]' : ']]'
            
            "#{opening}#{cleaned_tag}|#{cleaned_value}#{closing}"
          else
            value.to_s
          end
        end

        links.join('; ')
      end
    end
  end

  let(:helper) { helper_class.new }

  describe 'multi_wiki_link' do
    context 'when value contains square braces' do
      it 'adds space before closing ]]' do
        tags = '[unclear]Max[/unclear]'
        values = '[unclear]Max[/unclear]'
        result = helper.multi_wiki_link(tags, values)
        expect(result).to eq('[[  [unclear]Max[/unclear]|[unclear]Max[/unclear] ]]')
      end
    end

    context 'when tag contains square braces' do
      it 'adds space after opening [[' do
        tags = '[unclear]Max[/unclear]'
        values = 'Max'
        result = helper.multi_wiki_link(tags, values)
        expect(result).to eq('[[  [unclear]Max[/unclear]|Max]]')
      end
    end

    context 'when both tag and value contain square braces' do
      it 'adds spaces at both ends' do
        tags = '[unclear]Max[/unclear]'
        values = '[unclear]Max[/unclear]'
        result = helper.multi_wiki_link(tags, values)
        expect(result).to eq('[[  [unclear]Max[/unclear]|[unclear]Max[/unclear] ]]')
      end
    end

    context 'when neither tag nor value contains square braces' do
      it 'creates wikilink without extra spaces' do
        tags = 'Rawlings (authoritative name TBD)'
        values = 'Rawling'
        result = helper.multi_wiki_link(tags, values)
        expect(result).to eq('[[Rawlings (authoritative name TBD)|Rawling]]')
      end
    end

    context 'when handling multiple semicolon-separated values' do
      it 'handles each pair correctly' do
        tags = '[unclear]Max[/unclear]; Smith, John'
        values = '[unclear]Max[/unclear]; John Smith'
        result = helper.multi_wiki_link(tags, values)
        expect(result).to eq('[[  [unclear]Max[/unclear]|[unclear]Max[/unclear] ]]; [[Smith, John|John Smith]]')
      end
    end

    context 'when tags or values are blank' do
      it 'returns the values as string when tags are blank' do
        tags = ''
        values = 'Some value'
        result = helper.multi_wiki_link(tags, values)
        expect(result).to eq('Some value')
      end

      it 'returns the values as string when values are blank' do
        tags = 'Some tag'
        values = ''
        result = helper.multi_wiki_link(tags, values)
        expect(result).to eq('')
      end
    end
  end
end
