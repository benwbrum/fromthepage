# == Schema Information
#
# Table name: tags
#
#  id          :integer          not null, primary key
#  ai_text     :string(255)
#  canonical   :boolean
#  message_key :string(255)
#  tag_type    :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Tag < ApplicationRecord

  require 'openai/description_tagger'
  has_and_belongs_to_many :collections

  # return tags that are canonical and have collections that are unrestricted and have a picture and intro block
  def self.featured_tags
    joins(:collections).where(canonical: true).merge(Collection.unrestricted.has_intro_block.has_picture.not_empty)
  end

  module TagType

    DATE = 'date'
    LANGUAGE = 'language'
    SUBJECT = 'subject'
    TASK = 'task'

  end

  TAG_TYPES = [
    TagType::DATE,
    TagType::LANGUAGE,
    TagType::SUBJECT,
    TagType::TASK
  ]

  def self.tag_by_subject(description, title)
    # get the subject tags
    subject_tags = Tag.where(tag_type: TagType::SUBJECT, canonical: true).pluck(:ai_text)
    suggested_tags = DescriptionTagger.tag_description_by_subject(description, subject_tags, title)
    # now find the tag records
    find_from_string_list(suggested_tags, TagType::SUBJECT)
  end

  # create a new tag record from a string
  def self.create_from_string(tag_string, tag_type)
    tag = Tag.new
    tag.tag_type = tag_type
    tag.canonical = false
    tag.ai_text = tag_string
    tag.message_key = nil
    tag.save
    tag
  end

  # find a tag record from a string
  def self.find_from_string(tag_string, tag_type)
    tag = Tag.where(tag_type:, ai_text: tag_string).first
    tag = Tag.create_from_string(tag_string, tag_type) if tag.nil?
    tag
  end

  # take a list of string tags, and return a list of tag records
  def self.find_from_string_list(tag_string_list, tag_type)
    tag_string_list.map do |tag_string|
      Tag.find_from_string(tag_string, tag_type)
    end
  end

end
