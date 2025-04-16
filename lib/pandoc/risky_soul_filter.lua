function Span(el)
  -- Escape special characters like backticks and single quotes
  local content = pandoc.utils.stringify(el.content)

  if el.classes:includes("ulst") then
    return pandoc.RawInline("latex", "\\ulst{" .. pandoc.utils.stringify(content) .. "}")
  end
end
