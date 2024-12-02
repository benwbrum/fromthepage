# == Schema Information
#
# Table name: editor_buttons
#
#  id            :integer          not null, primary key
#  key           :string(255)
#  prefer_html   :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer          not null
#
# Indexes
#
#  index_editor_buttons_on_collection_id  (collection_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
class EditorButton < ApplicationRecord
  belongs_to :collection

  module Keys
    ABBR = 'abbr'
    ADD = 'add'
    DATE = 'date'
    DEL = 'del'
    EXPAN = 'expan'
    FIG = 'fig'
    FOOTNOTE = 'footnote'
    GAP = 'gap'
    HEAD = 'head'
    MARGINALIA = 'marginalia'
    REG = 'reg'
    SOFT_BREAK = 'lb'
    STRIKE = 'strike'
    SUB = 'sub'
    SUP = 'sup'
    TABLE = 'table'
    UNCLEAR = 'unclear'
    UNDERLINE = 'u'
    ITALIC = 'i'
  end

  BUTTON_MAP = {
    Keys::ABBR => ['<abbr expan="">'],
    Keys::ADD => ['<add>'],
    Keys::DATE => ['<date when="">'],
    Keys::DEL => ['<del>'],
    Keys::EXPAN => ['<expan abbr="">'],
    Keys::FIG => ['<fig rend="hr">'],
    Keys::FOOTNOTE => ['<footnote marker="*">'],
    Keys::GAP => ['<gap>'],
    Keys::HEAD => ['<head>'],
    Keys::ITALIC => ['<hi rend="italics">', '<i>'],
    Keys::SOFT_BREAK => ['<lb break="no">'],
    Keys::MARGINALIA => ['<marginalia>'],
    Keys::REG => ['<reg orig="">'],
    Keys::STRIKE => ['<hi rend="str">', '<strike>'],
    Keys::SUB => ['<hi rend="sub">', '<sub>'],
    Keys::SUP => ['<hi rend="sup">', '<sup>'],
    Keys::TABLE => [''],
    Keys::UNCLEAR => ['<unclear>'],
    Keys::UNDERLINE => ['<hi rend="underline">', '<u>']
  }


  def open_tag
    tags = BUTTON_MAP[self.key]
    if self.prefer_html && tags.size > 1
      tags[1].html_safe
    else
      tags[0].html_safe
    end
  end


  def close_tag
    ('</' + open_tag.sub('<', '').sub(/\s.*/, '').sub('>','') + '>').html_safe
  end

  def cursor_offset
    self.close_tag.length
  end

  def has_attribute
    open_tag.match /\s/
  end

  def hotkey
    "Ctrl-E"
  end

end
