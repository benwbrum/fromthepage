-- Custom underline-strike effect
function Span(el)
  local content = pandoc.utils.stringify(el.content)

  if el.classes:includes("ulst") then
    return pandoc.RawInline("latex", "\\ulst{" .. pandoc.utils.stringify(content) .. "}")
  end
end

-- Custom small font text effect
function Div(el)
  if el.classes:includes("smalltext") then
    return {
      pandoc.RawBlock("latex", "\\begin{smalltext}"),
      el,
      pandoc.RawBlock("latex", "\\end{smalltext}")
    }
  end
end
