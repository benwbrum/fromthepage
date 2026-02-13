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
    static_keys = unused_keys.key_names.select { |key| !(key.match(/collection\.edit_buttons/)||key.match(/category\..*abled_for/)||key.match(/page_version\.show\.page_version_status/)) }

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
    # Words that should be "work of literature" not "labor"
    let(:incorrect_translations) do
      {
        'de' => ['arbeit', 'arbeiten'],
        'es' => ['trabajo', 'trabajos'],
        'fr' => ['travail', 'travaux'],
        'pt' => ['trabalho', 'trabalhos']
      }
    end

    # Message keys where "labor" translation is acceptable
    let(:allowlist) do
      [
        # Phrases about "working on" something (labor is correct)
        'collection.recent_contributor_list.recent_contributor_description', # "working on the project"
        'work.download.warning_work_not_complete', # "work on this document"
        'work.configurable_printout.text_contents_description', # "metadata about the work" (ambiguous but acceptable)
        'collection.edit_danger.blank_collection_description', # "work on the collection" (labor context)
        'collection.edit_look.alphabetize_works_description', # "amount of work remaining" (labor context)
        'collection.contributors_body.time_on_this', # "time on this" (labor context)
        'collection.show.this_work_has_pages_that_need_work', # "pages that need work" (labor context)
        'dashboard.upload.to_specify_metadata', # "work" referring to literary work but in metadata context (acceptable)
        'shared.page_navigation.describe_work', # "describe the work" (ambiguous but referring to the literary work in context)
        # AI transcription jobs (these are background jobs/tasks, not literary works)
        'collection.ai_transcriptions.create.success', # "AI transcription job"
        'collection.ai_transcriptions.form.description', # "AI transcription job"
        'collection.ai_transcriptions.form.retry', # "retry failed jobs"
        'collection.ai_transcriptions.update.success' # "AI transcription job"
      ]
    end

    # Helper to recursively extract all key-value pairs from YAML
    def extract_translations(hash, prefix = '', results = {})
      hash.each do |key, value|
        full_key = prefix.empty? ? key : "#{prefix}.#{key}"
        if value.is_a?(Hash)
          extract_translations(value, full_key, results)
        elsif value.is_a?(String)
          results[full_key] = value
        end
      end
      results
    end

    it 'does not contain incorrect translations in locale files' do
      locale_files = Dir[Rails.root.join('config', 'locales', '**', '*.yml')]
      errors = []

      locale_files.each do |file|
        begin
          data = YAML.safe_load_file(file)
          next unless data.is_a?(Hash)

          # Get the locale code (e.g., 'de', 'es', 'fr')
          locale = data.keys.first
          next unless incorrect_translations.key?(locale)

          translations = extract_translations(data)
          bad_words = incorrect_translations[locale]

          translations.each do |key, value|
            # Skip if key is in allowlist
            next if allowlist.include?(key.sub(/^#{locale}\./, ''))

            bad_words.each do |word|
              # Use word boundary regex to avoid matching compound words
              # e.g., don't flag "bearbeiten" when looking for "arbeit"
              if value.downcase.match?(/\b#{Regexp.escape(word)}\b/)
                errors << {
                  file: file.sub(Rails.root.to_s, ''),
                  key: key,
                  value: value,
                  word: word
                }
              end
            end
          end
        rescue Psych::Exception, Errno::ENOENT
          # Skip files that can't be parsed or don't exist
          next
        end
      end

      if errors.any?
        error_message = "\n\nFound #{errors.count} incorrect translation(s):\n\n"
        errors.each do |error|
          error_message += "File: #{error[:file]}\n"
          error_message += "Key: #{error[:key]}\n"
          error_message += "Bad word: '#{error[:word]}'\n"
          error_message += "Message: #{error[:value]}\n"
          error_message += "\n"
        end
        RSpec.configuration.reporter.message(error_message)
      end

      expect(errors).to be_empty, "Found #{errors.count} incorrect translation(s). See output above for details."
    end
  end
end
