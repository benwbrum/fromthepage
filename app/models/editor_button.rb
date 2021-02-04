class EditorButton < ApplicationRecord
  belongs_to :collection

  module Keys
    ABBR = 'abbr'
    ADD = 'add'
    DATE = 'date'
    DEL = 'del'
    EXPAN = 'expan'
    FIG = 'fig'
    GAP = 'gap'
    REG = 'reg'
    STRIKE = 's'
    SUB = 'sub'
    SUP = 'sup'
    UNCLEAR = 'unclear'
    UNDERLINE = 'u'
  end

  BUTTON_MAP = {
    Keys::ABBR => ['<abbr expan="">'],
    Keys::ADD => ['<add>'],
    Keys::DATE => ['<date when="">'],
    Keys::DEL => ['<del>'],
    Keys::EXPAN => ['<expan abbr="">'],
    Keys::FIG => ['<fig rend="hr">'],
    Keys::GAP => ['<gap>'],
    Keys::REG => ['<reg orig="">'],
    Keys::STRIKE => ['<hi rend="str">', '<s>'],
    Keys::SUB => ['<hi rend="sub">', '<sub>'],
    Keys::SUP => ['<hi rend="sup">', '<sup>'],
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
