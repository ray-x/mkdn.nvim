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
  print(vim.inspect(...))
end

if lprint then
  log = lprint
end

-- Function to calculate relative path
function get_relative_path(target_path, current_dir)
  -- Get the full path of the current file
  local current_file = vim.fn.expand('%:p')
  -- Get the directory of the current file
  current_dir = current_dir or vim.fn.fnamemodify(current_file, ':h') .. '/'
  -- Normalize target path
  local absolute_target_path = vim.fn.fnamemodify(target_path, ':p')

  -- Function to split path into parts
  local function split_path(path)
    local parts = {}
    for part in string.gmatch(path, '[^/]+') do
      table.insert(parts, part)
    end
    return parts
  end

  local current_parts = split_path(current_dir)
  local target_parts = split_path(absolute_target_path)
  local relative_parts = {}

  while #current_parts > 0 and #target_parts > 0 and current_parts[1] == target_parts[1] do
    table.remove(current_parts, 1)
    table.remove(target_parts, 1)
  end

  for _ in ipairs(current_parts) do
    table.insert(relative_parts, '..')
  end

  for _, part in ipairs(target_parts) do
    table.insert(relative_parts, part)
  end

  return table.concat(relative_parts, '/')
end

-- local assets_path = '/home/ray/Projects/notes/assets'
-- local current_dir = '/home/ray/Projects/notes/abc'
-- print(get_relative_path(assets_path, current_dir))

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
  get_relative_path = get_relative_path,
}
