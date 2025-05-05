# frozen_string_literal: true

require 'spec_helper'
require 'i18n/tasks'
require 'pry'

RSpec.describe I18n do
  let(:i18n) { I18n::Tasks::BaseTask.new }
  let(:missing_keys) { i18n.missing_keys }
  let(:unused_keys) { i18n.unused_keys }
  let(:inconsistent_interpolations) { i18n.inconsistent_interpolations }

  it 'does not have missing keys' do
    expect(missing_keys).to be_empty,
                            "Missing #{missing_keys.leaves.count} i18n keys, run `i18n-tasks missing' to show them"
  end

  it 'does not have unused keys' do
    # edit button keys are dynamic and will throw false positives here
    static_keys = unused_keys.key_names.select{|key| !(key.match(/collection\.edit_buttons/)||key.match(/category\..*abled_for/))}

    expect(static_keys).to be_empty,
                           "#{static_keys.count} unused i18n keys, run `i18n-tasks unused' to show them"
  end

  it 'files are normalized' do
    non_normalized = i18n.non_normalized_paths
    error_message = "The following files need to be normalized:\n" \
                    "#{non_normalized.map { |path| "  #{path}" }.join("\n")}\n" \
                    "Please run `i18n-tasks normalize' to fix"
    expect(non_normalized).to be_empty, error_message
  end

  it 'does not have inconsistent interpolations' do
    error_message = "#{inconsistent_interpolations.leaves.count} i18n keys have inconsistent interpolations.\n" \
                    "Run `i18n-tasks check-consistent-interpolations' to show them"
    expect(inconsistent_interpolations).to be_empty, error_message
  end

  describe 'translations' do
    let(:incorrect_translations) do
      ['travail', 'travaux', 'trabalho', 'trabalhos', 'arbeit', 'arbeiten', 'trabajo', 'trabajos', 'dokumentensatz']
    end

    it 'does not contain incorrect translations in locale files' do
      locale_files = Dir[Rails.root.join('config', 'locales', '**', '*.yml')]
      errors = []

      locale_files.each do |file|
        file_content = File.read(file).downcase

        incorrect_translations.each do |word|
          errors << "Found incorrect translation '#{word}' in file: #{file}" if file_content.include?(word)
        end
      end

      RSpec.configuration.reporter.message(errors.join("\n")) if errors.any?

      expect(true).to eq(true)
    end
  end
end
