local SINGLE_QUOTE_PLACEHOLDER = "__SINGLEQUOTE__"
local BACKTICK_PLACEHOLDER = "__BACKTICK__"

function Span(el)
  -- Escape special characters like backticks and single quotes
  local content = pandoc.utils.stringify(el.content)
  if content then
    content = content:gsub(SINGLE_QUOTE_PLACEHOLDER, "`")
    content = content:gsub(BACKTICK_PLACEHOLDER, "`")
  end

  if el.classes:includes("textulst") then
    return pandoc.RawInline("latex", "\\textulst{" .. pandoc.utils.stringify(content) .. "}")
  elseif el.classes:includes("textul") then
    return pandoc.RawInline("latex", "\\textul{" .. pandoc.utils.stringify(content) .. "}")
  elseif el.classes:includes("textst") then
    return pandoc.RawInline("latex", "\\textst{" .. pandoc.utils.stringify(content) .. "}")
  end
end
