class CreateTags < ActiveRecord::Migration[5.0]
  def change
    create_table :tags do |t|
      t.string :tag_type
      t.boolean :canonical
      t.string :ai_text
      t.string :message_key

      t.timestamps
    end

    DEFAULT_SUBJECT_TAGS.each do |tag|
      Tag.create(tag_type: Tag::TagType::SUBJECT, canonical: true, ai_text: tag, message_key: tag.downcase.gsub(/\W/, "_"))
    end

    create_table :collections_tags, id: false do |t|
      # foreign key to collections
      t.column :collection_id, :integer
      # foreign key to tags
      t.column :tag_id, :integer
    end
  end

  DEFAULT_SUBJECT_TAGS=[ "African-American History", "Agriculture and Farming", "Arts", "Australia", "Book of Hours", "Book History", "Catholicism", "City Council", "China", "Civil Rights", "Civil War and Reconstruction", "Cookbooks", "Communism", "Correspondence", "Diaries", "Disability and Illness", "Education", "England", "Family Papers", "Federal Writers Project", "Field notes", "Financial", "Gold Rush", "Government Records", "Health and Medicine", "Historic sites", "Holocaust", "Immigration and naturalization", "Imprisonment", "Indigenous History", "Judaica", "Legal", "LGBTQ", "Linguistics and Anthropology", "Literature", "Logs", "Maritime", "Mexican-American War", "Military", "Mormonism", "Natural Disasters", "Natural Sciences", "Newspapers", "Oral History", "Parks", "Philosophy", "Railroads", "Religion", "Science", "Slavery", "Society", "Sports", "The Revolution and Early America", "Technology", "Travel", "University", "US Presidents", "Vital Records", "Women's History", "World War I", "World War II", "Zines", "Photographs and Images", "Latin America History", "Finding Aids and Catalogs" ]
end
