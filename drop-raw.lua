-- drop-raw.lua: clean up embedded HTML/CSS/VML and fix Confluence code blocks
-- ponytail: stateful filter; drops all Para between <style>...</style> markers
--           and also drops obvious lone HTML tag paragraphs (e.g. <div ...>, <!--...-->)

local dropping = false

-- Convert Confluence code panel divs (class="codeContent ...") to proper CodeBlock nodes
function Div(el)
  for _, cls in ipairs(el.classes) do
    if cls == "codeContent" then
      local code = pandoc.utils.stringify(el)
      return pandoc.CodeBlock(code)
    end
  end
end

function Para(el)
  local text = pandoc.utils.stringify(el)

  -- toggle drop zone on <style> / </style>
  if text:match("^<style") then dropping = true;  return {} end
  if text:match("^</style") then dropping = false; return {} end
  if dropping then return {} end

  -- drop lone HTML-ish lines outside the style block (VML, comments, div wrappers)
  if text:match("^<!") or text:match("^<[%a/][^>]*>%s*$") then return {} end

  return el
end

function RawBlock() return {} end
function RawInline() return {} end
