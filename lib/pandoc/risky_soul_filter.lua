function Span(el)
  local content = pandoc.utils.stringify(el.content)

  if el.classes:includes("ulst") then
    return pandoc.RawInline("latex", "\\ulst{" .. pandoc.utils.stringify(content) .. "}")
  elseif el.classes:includes("smalltext") then
    return pandoc.RawInline("latex", "\\smalltext{" .. pandoc.utils.stringify(el.content) .. "}")
  end
end
