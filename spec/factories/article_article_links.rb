FactoryGirl.define do

  factory :article_article_link1, class: ArticleArticleLink do
    source_article_id 1
    target_article_id 2
    display_text "Article Article link"
  end

end
