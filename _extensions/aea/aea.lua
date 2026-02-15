
--
local kHeightAttr = 'add-textheight'

local text_height_div = function(el)
  for k,v in pairs(el.attr.attributes) do
    if k == kHeightAttr then
      if quarto.doc.is_format("pdf") then
        local heightAdjust = pandoc.utils.stringify(v)
        local endHeight = '-' .. heightAdjust
        if heightAdjust:sub(1,1) == "-" then
          endHeight = heightAdjust:sub(2)
        end

        local rawStart = pandoc.RawBlock("latex", "\\addtolength{\\textheight}{" .. heightAdjust .."}%")
        local rawEnd = pandoc.RawBlock("latex", "\\addtolength{\\textheight}{" .. endHeight .."}%")
        table.insert(el.content, 1, rawStart)
        table.insert(el.content, rawEnd)

        return el
      end
    end
  end
end

local processSupplementary = function(el)
  if el.attr.classes:includes('supplementary') then

    if quarto.doc.is_format("pdf") then
      local content = el.content
      local titleText = pandoc.utils.stringify(content);
      titleText = pandoc.text.upper(titleText);
      local rendered = {
        pandoc.RawInline("latex", "\\bigskip\n"),
        pandoc.RawInline("latex", "\\begin{center}\n"),
        pandoc.RawInline("latex", "{\\large\\bf " .. titleText .. "}\n"),
        pandoc.RawInline("latex", "\\end{center}"),
      }
      return pandoc.Div(rendered, el.attr)
    elseif quarto.doc.is_format("html") then
      local content = el.content
      local titleText = pandoc.write(pandoc.Pandoc(pandoc.Plain(content)), 'html')
      local heading = pandoc.Header(2, content, { el.attr.identifier, {"supplementary", "unnumbered"}, el.attr.attributes} )
      return heading
    end
  end
end

-- Insert \newpage\appendix before the first header with .appendix class
local appendix_inserted = false
local function process_appendix_header(el)
  if quarto.doc.is_format("pdf") then
    if el.attr.classes:includes('appendix') and not appendix_inserted then
      appendix_inserted = true
      return {
        pandoc.RawBlock("latex", "\\newpage\n\\appendix"),
        el
      }
    end
  end
end

-- Set default image width to \textwidth when no explicit width is given
local function set_default_image_width(img)
  if quarto.doc.is_format("pdf") then
    if not img.attributes["width"] then
      img.attributes["width"] = "100%"
    end
  end
  return img
end

return {
  {
    Div = text_height_div,
    Header = function(el)
      -- Process supplementary first, then appendix
      local result = processSupplementary(el)
      if result then return result end
      return process_appendix_header(el)
    end,
    Image = set_default_image_width
  }
}
