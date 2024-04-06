local function read_first_nlines(filePath, N)
  local lines = {}
  local file = io.open(filePath, 'r')
  if file then
    for i = 1, N do
      local line = file:read('*line')
      if not line then
        break
      end
      table.insert(lines, line)
      if line == '---' and i > 1 then
        break
      end
    end
    file:close()
  end
  return lines
end

local function parse_frontmatter(fileContent)
  local frontmatter = {}
  local inFrontmatter = false
  local currentKey, currentList, currentIndent
  if type(fileContent) == 'string' then
    fileContent = vim.split(fileContent, '\n', { plain = true })
  end

  for _, line in ipairs(fileContent) do
    if line:match('^---') then
      if inFrontmatter then
        if currentKey and currentList then
          frontmatter[currentKey] = currentList
        end
        break -- End of frontmatter
      end
      inFrontmatter = true
    elseif inFrontmatter then
      if currentKey then
        local itemIndent, item = line:match('^(%s*)%- (.*)$')
        if itemIndent and item and #itemIndent > (currentIndent or 0) then
          table.insert(currentList, item)
        else
          if currentList then -- Save the previous list if any
            frontmatter[currentKey] = currentList
          end
          currentKey, currentList, currentIndent = nil, nil, nil -- Reset for the next key
        end
      end

      if not currentKey then
        local key, value = line:match('^(%w+):%s*(.*)$')
        if key then
          if value == '' then
            currentKey, currentList = key, {}
            currentIndent = #line:match('^%s*')
          elseif value:match('^%[.*%]$') then -- Array in the [] format
            frontmatter[key] = {}
            for item in value:gmatch('[%w_-]+') do
              table.insert(frontmatter[key], item)
            end
          else
            frontmatter[key] = value
          end
        end
      end
    end
  end

  if currentKey and currentList then --  EOF is reached while parsing a list
    frontmatter[currentKey] = currentList
  end
  -- print(vim.inspect(frontmatter))
  return frontmatter
end
local log = function(...)
  if require('mkdn').config().debug then
    if lprint then
      lprint(...)
    else
      print(vim.inspect(...))
    end
  end
end

local filecontent1 = [[
---
title: My title
tags: [tag1, tag2]
---

This is the content
- item 1
- item 2
]]

-- local filecontent1 = {
--   '---',
--   'title: My title',
--   'tags: [tag1, tag2]',
--   '---',
--   'This is the content',
--   '- item 1',
--   '- item 2',
--   '---',
-- }
--
-- local filecontent2 = {
--   '---',
--   'title: My title',
--   'tags:',
--   '  - tag1',
--   '  - tag2',
--   '---',
--   'This is the content',
--   '- item 1',
--   '- item 2',
--   '---',
-- }

-- print(vim.inspect(parse_frontmatter(filecontent1)))

return {
  read_first_nlines = read_first_nlines,
  parse_frontmatter = parse_frontmatter,
  log = log,
}
