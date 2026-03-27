local function pagebreak_block()
  if FORMAT == "docx" then
    return pandoc.RawBlock('openxml', '<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
  elseif FORMAT == "html" then
    return pandoc.RawBlock('html', '<div style="page-break-after: always;"></div>')
  elseif FORMAT == "latex" or FORMAT == "pdf" then
    return pandoc.RawBlock('latex', '\\newpage')
  else
    return pandoc.Para{pandoc.Str '\f'}
  end
end

local function hr_block()
  if FORMAT == "docx" then
    return pandoc.RawBlock('openxml', [[<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="auto"/></w:pBdr></w:pPr></w:p>]])
  elseif FORMAT == "html" then
    return pandoc.RawBlock('html', '<hr>')
  elseif FORMAT == "latex" or FORMAT == "pdf" then
    return pandoc.RawBlock('latex', '\\noindent\\rule{\\linewidth}{0.2pt}')
  else
    return pandoc.HorizontalRule()
  end
end

function handle_block(elem)
  local new_blocks = {}
  local buffer = {}

  for _, inline in ipairs(elem.content) do
    if inline.t == "Str" and inline.text == "{{startnewpage}}" then
      if #buffer > 0 then
        table.insert(new_blocks, pandoc.Para(buffer))
        buffer = {}
      end
      table.insert(new_blocks, pagebreak_block())

    elseif inline.t == "Str" and inline.text == "{{hr}}" then
      if #buffer > 0 then
        table.insert(new_blocks, pandoc.Para(buffer))
        buffer = {}
      end
      table.insert(new_blocks, hr_block())

    else
      table.insert(buffer, inline)
    end
  end

  if #buffer > 0 then
    table.insert(new_blocks, pandoc.Para(buffer))
  end

  return new_blocks
end

function handle_math(elem)
  local fixed = elem.text

  -- 1. Fix accent + \vec combos (\dot\vec{x} → \dot{\vec{x}})
  fixed = fixed:gsub("\\dot%s*\\vec%s*{(.-)}", "\\dot{\\vec{%1}}")
  fixed = fixed:gsub("\\dot%s*\\vec%s*(%a)", "\\dot{\\vec{%1}}")

  fixed = fixed:gsub("\\hat%s*\\vec%s*{(.-)}", "\\hat{\\vec{%1}}")
  fixed = fixed:gsub("\\hat%s*\\vec%s*(%a)", "\\hat{\\vec{%1}}")

  fixed = fixed:gsub("\\tilde%s*\\vec%s*{(.-)}", "\\tilde{\\vec{%1}}")
  fixed = fixed:gsub("\\tilde%s*\\vec%s*(%a)", "\\tilde{\\vec{%1}}")

  fixed = fixed:gsub("\\bar%s*\\vec%s*{(.-)}", "\\bar{\\vec{%1}}")
  fixed = fixed:gsub("\\bar%s*\\vec%s*(%a)", "\\bar{\\vec{%1}}")

  -- 2. Normalize Unicode minus sign (U+2212) to ASCII -
  fixed = fixed:gsub("−", "-")

  -- 3. Normalize multiplication signs
  fixed = fixed:gsub("×", "\\times ")
  fixed = fixed:gsub("·", "\\cdot ")

  -- 4. Normalize ellipsis (U+2026) to \ldots
  fixed = fixed:gsub("…", "\\ldots ")

  -- 5. Normalize superscript letters like ᵃ, ᵇ, ᶜ → ^{a}, ^{b}, ^{c}
  local superscripts = {
    ["ᵃ"]="a", ["ᵇ"]="b", ["ᶜ"]="c", ["ᵈ"]="d", ["ᵉ"]="e", ["ᶠ"]="f",
    ["ᵍ"]="g", ["ʰ"]="h", ["ᶦ"]="i", ["ʲ"]="j", ["ᵏ"]="k", ["ˡ"]="l",
    ["ᵐ"]="m", ["ⁿ"]="n", ["ᵒ"]="o", ["ᵖ"]="p", ["ʳ"]="r", ["ˢ"]="s",
    ["ᵗ"]="t", ["ᵘ"]="u", ["ᵛ"]="v", ["ʷ"]="w", ["ˣ"]="x", ["ʸ"]="y", ["ᶻ"]="z"
  }
  fixed = fixed:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
    if superscripts[c] then
      return "^{" .. superscripts[c] .. "}"
    else
      return c
    end
  end)

  if fixed ~= elem.text then
    elem.text = fixed
    return elem
  end
end

function handle_meta(meta)
  if not meta['header-includes'] then
    meta['header-includes'] = {}
  end

  local header = [[
\usepackage{fontspec, newunicodechar}

% For unicode support
\usepackage{fontspec}
\setmainfont{CMU Serif}
\setsansfont{CMU Sans Serif}
\setmonofont{CMU Typewriter Text}

% For tables
\usepackage{tabularray}
\UseTblrLibrary{booktabs}
\UseTblrLibrary{siunitx}
\usepackage{pdflscape}
]]

  table.insert(meta['header-includes'], pandoc.RawBlock('latex', header))

  return meta
end

function RotatetableDiv(el)
  if el.classes:includes("rotatetable") then
    local latex_blocks = {}

    table.insert(latex_blocks, pandoc.RawBlock("latex", [[
\clearpage
\begin{landscape}
\scriptsize
]]))

    for _, block in ipairs(el.content) do
      if block.t == "Table" then
        -- Count columns from the table header
        local col_count = 0
        if block.colspecs then
          col_count = #block.colspecs
        elseif block.head and block.head.rows[1] then
          col_count = #block.head.rows[1].cells
        end

        -- Fallback (just in case)
        if col_count == 0 then col_count = 1 end

        -- Build colspec = {X X X ...}
        local colspec = {}
        for i = 1, col_count do
          table.insert(colspec, "X")
        end
        local colspec_str = table.concat(colspec, " ")

        -- Convert table to LaTeX
        local latex = pandoc.write(pandoc.Pandoc({block}), "latex")

        -- Replace longtable → longtblr with dynamic colspec
        latex = latex:gsub(
          "\\begin{longtable}%b[]%b{}",
          "\\begin{longtblr}{width=\\linewidth,colspec={" .. colspec_str .. "}}"
        )

        latex = latex:gsub(
          "\\begin{longtable}",
          "\\begin{longtblr}{width=\\linewidth,colspec={" .. colspec_str .. "}}"
        )

        latex = latex:gsub("\\end{longtable}", "\\end{longtblr}")

        latex = latex:gsub("\\noalign%b{}", "")
        latex = latex:gsub("\\toprule", "")
        latex = latex:gsub("\\bottomrule", "")
        latex = latex:gsub("\\endhead", "")
        latex = latex:gsub("\\endfirsthead", "")
        latex = latex:gsub("\\endfoot", "")
        latex = latex:gsub("\\endlastfoot", "")

        table.insert(latex_blocks, pandoc.RawBlock("latex", latex))
      else
        table.insert(latex_blocks, block)
      end
    end

    table.insert(latex_blocks, pandoc.RawBlock("latex", [[
\normalsize
\end{landscape}
\clearpage
]]))

    return latex_blocks
  end
end

return {
  {
    Para = handle_block,
    Plain = handle_block,
    Math = handle_math,
    Meta = handle_meta,
    Div = RotatetableDiv
  }
}
