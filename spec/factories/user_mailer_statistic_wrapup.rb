FactoryBot.define do
  # You must pass a user object as the owner in your spec to use this factory
  # ex: user = build_stubbed(:user)
  #     wrapup = build(:statistic_wrapup, owner: user )
  factory :statistic_wrapup, class: 'UserMailer::StatisticWrapup' do
    contributor_emails { "#{owner.display_name} <#{owner.email}>" }
    contributor_count { 2 }
    work_count { 2 }
    completed_work_count { 2 }
    page_count { 2 }
    comment_count { 2 }
    transcription_count { 2 }
    edit_count { 2 }
    translation_count { 2 }
    ocr_count { 2 }
    subject_count { 2 }
    mention_count { 2 }
    index_count { 2 }

    initialize_with { new(
      owner: nil,
      collection: nil,
      title: nil,
      contributor_emails: contributor_emails,
      contributor_count: contributor_count,
      work_count: work_count,
      completed_work_count: completed_work_count,
      page_count: page_count,
      comment_count: comment_count,
      transcription_count: transcription_count,
      edit_count: edit_count,
      translation_count: translation_count,
      ocr_count: ocr_count,
      subject_count: subject_count,
      mention_count: mention_count,
      index_count: index_count
    ) }
  end
end
