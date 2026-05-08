FactoryBot.define do
  factory :cdm_export_setting do
    collection
    transcript_source { CdmExportSetting::HUMAN_ONLY }
    fulltext_field    { 'transc' }
    include_ai_provenance { false }
    ai_provenance_field   { nil }
    prepend_ai_warning    { false }

    trait :human_and_ai do
      transcript_source { CdmExportSetting::HUMAN_AND_AI }
    end

    trait :with_provenance do
      include_ai_provenance { true }
      ai_provenance_field   { 'descri' }
    end

    trait :with_warning do
      prepend_ai_warning { true }
    end
  end
end
