-- drop-raw.lua: clean up embedded HTML/CSS/VML and fix Confluence code blocks
-- ponytail: stateful filter; drops all Para between <style>...</style> markers
--           and also drops obvious lone HTML tag paragraphs (e.g. <div ...>, <!--...-->)

local dropping = false

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

-- Drop HTML/VML junk from Word exports, but keep LaTeX we inject ourselves
function RawBlock(el)
  if el.format == 'latex' or el.format == 'tex' then return el end
  return {}
end

function RawInline(el)
  if el.format == 'latex' or el.format == 'tex' then return el end
  return {}
end

-- Give tables proportional column widths so LaTeX wraps instead of overflowing,
-- and set header cell text to white for the teal header row.
function Table(tbl)
  local n = #tbl.colspecs
  if n > 0 then
    for i, spec in ipairs(tbl.colspecs) do
      tbl.colspecs[i] = { spec[1], 1.0 / n }
    end
  end

  -- Word/Confluence exports carry no <th>: promote the first available row to header
  if #tbl.head.rows == 0 and #tbl.bodies > 0 then
    if #tbl.bodies[1].head > 0 then
      tbl.head.rows = { table.remove(tbl.bodies[1].head, 1) }
    elseif #tbl.bodies[1].body > 0 then
      tbl.head.rows = { table.remove(tbl.bodies[1].body, 1) }
    end
  end

  for _, row in ipairs(tbl.head.rows) do
    for _, cell in ipairs(row.cells) do
      for _, blk in ipairs(cell.contents) do
        if blk.content then
          table.insert(blk.content, 1, pandoc.RawInline('latex', '\\color{white}\\bfseries '))
        end
      end
    end
  end

  return tbl
end

-- Wrap inline code in a dedicated command so the template can style it
-- without redefining \texttt globally.
function Code(el)
  return {
    pandoc.RawInline('latex', '\\stormcode{'),
    pandoc.Str(el.text),
    pandoc.RawInline('latex', '}')
  }
end

-- Confluence headings sometimes carry hand-typed numbering ("1. Scope"),
-- sometimes wrapped in <strong>. LaTeX numbers sections itself, so we strip the prefix.
function Header(el)
  -- drop author-applied bold/italic first; heading level defines the styling
  el.content = el.content:walk({
    Strong = function(s) return s.content end,
    Emph   = function(s) return s.content end
  })

  -- skip leading breaks/spaces Confluence left in the heading
  while el.content[1] and (el.content[1].t == 'LineBreak'
                        or el.content[1].t == 'SoftBreak'
                        or el.content[1].t == 'Space') do
    table.remove(el.content, 1)
  end

  -- drop manual numbering ("1.", "2)")
  if el.content[1] and el.content[1].t == 'Str'
     and el.content[1].text:match('^%d+[%.%)]?$') then
    table.remove(el.content, 1)
    while el.content[1] and el.content[1].t == 'Space' do
      table.remove(el.content, 1)
    end
  end

  return el
end