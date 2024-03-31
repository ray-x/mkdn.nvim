
local function readFirstNLines(filePath, N)
  local lines = {}
  local file = io.open(filePath, 'r')
  if file then
    for _ = 1, N do
      local line = file:read('*line')
      if not line then
        break
      end
      table.insert(lines, line)
      if line == '---' then
        break
      end
    end
    file:close()
  end
  return table.concat(lines, '\n')
end


local function parseFrontmatter(fileContent)
  local frontmatter = {}
  local inFrontmatter = false
  local currentKey, currentList, currentIndent
  if type(fileContent) == 'string' then
    -- split the string into lines
    fileContent = vim.split(fileContent, '\n', true)
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

      if not currentKey then -- Process a new key or a non-list line
        local key, value = line:match('^(%w+):%s*(.*)$')
        if key then
          if value == '' then -- Prepare for a list in the second format
            currentKey, currentList = key, {}
            currentIndent = #line:match('^%s*')
          elseif value:match('^%[.*%]$') then -- Array in the first format
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

  if currentKey and currentList then -- Handle case where EOF is reached while parsing a list
    frontmatter[currentKey] = currentList
  end
  -- print(vim.inspect(frontmatter))
  return frontmatter
end


return {
  readFirstNLines = readFirstNLines,
  parseFrontmatter = parseFrontmatter,
}

-- local filecontent1 = [[
-- ---
-- title: My title
-- tags: [tag1, tag2]
-- ---
--
-- This is the content
-- - item 1
-- - item 2
-- ]]

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

-- parseFrontmatter(filecontent1)
-- parseFrontmatter(filecontent2)
