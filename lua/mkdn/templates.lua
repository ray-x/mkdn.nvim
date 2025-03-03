local sep = '/'

local function frontmatter(args)
  local frontmatter = {
    '---',
    'title: {{title}}',
    'author: {{author}}',
    'date: ' .. os.date('%Y-%m-%d'),
    'id: ' .. os.time(),
    'tags: ' .. (args['tags'] or ''),
    'category: ' .. (args['category'] or ''),
    'type: post',
  }

  local used = { 'title', 'author', 'date', 'id', 'tags', 'category', 'type' }
  -- we can have other optional frontmatter values
  for k, v in pairs(args) do
    if not vim.tbl_contains(used, k) then
      if type(v) == 'table' then
        v = '[' .. table.concat(v, ',') .. ']'
      elseif type(v) == 'function' then
        v = v()
      end
      table.insert(frontmatter, k .. ': ' .. v)
    end
  end

  table.insert(frontmatter, '---')
  return frontmatter
end

-- markdown templates example
--[[

---
author: {{author}},
date: {{date}},
id: {{id}},
tags: [{{tags}}],
title: {{title}},
category: {{category}},
type: post,
---

# {{title}}

{{content}}
]]
--

local prepare_kv = function(args)
  args = args or {}
  -- expand author, date, id, title
  args['author'] = args['author'] or os.getenv('USER')
  args['date'] = args['date'] or os.date('%Y-%m-%d')
  args['id'] = args['id'] or os.time()
  -- title default to file name
  args['title'] = args['title'] or vim.fn.fnamemodify(vim.fn.expand('%'), ':t:r')
  return args
end

local function expand_line(line, args)
  for k, v in pairs(args) do
    line = string.gsub(line, '{{' .. k .. '}}', v)
  end
  return line
end

local function load_template(path)
  local content = {}
  for line in io.lines(path) do
    table.insert(content, line)
  end
  return content
end

local function gen_lines_from_tmpl(tmpl_name, args)
  -- __meta
  for _, path in ipairs(require('mkdn.config').config().templates._meta.paths) do
    local tmpl_path = path .. tmpl_name
    if vim.fn.filereadable(tmpl_path) == 1 then
      tmpl_name = tmpl_path
    end
  end
  if not vim.fn.filereadable(tmpl_name) then
    return { '' }
  end
  local content = load_template(tmpl_name)
  local lines = {}
  for _, line in ipairs(content) do
    if type(line) == 'function' then
      line = line(args)
    end
    table.insert(lines, line)
  end
  return lines
end

local insert_lines = function(lines)
  -- insert lines into current buffer
  local current_line = vim.fn.line('.')
  vim.api.nvim_put(lines, 'l', true, true)
end

return {
  frontmatter = frontmatter,
  insert_tmpl = function(tmpl_name, args)
    args = prepare_kv(args)
    local lines = gen_lines_from_tmpl(tmpl_name, args)
    insert_lines(lines)
  end,
  tmpl_path = function(template)
    local cfg = require('mkdn.config').config()
    local note_root = cfg.notes_root
    local path = template.path or ''
    local file_path = note_root .. sep .. path

    local note_name = template.name
    if type(template.name) == 'function' then
      note_name = template.name()
      if not note_name then
        return
      end
    end
    local note_path = file_path .. sep .. note_name .. '.md'
    return note_path
  end,
  daily = {
    name = function()
      return os.date('%Y-%m-%d')
    end, -- or a function that returns the name
    path = 'journal',
    content = {
      function()
        return frontmatter({ tags = 'daily', category = 'daily' })
      end,
      '',
      '---',
      '',
      '# {{date}}',
      '',
      '## Tasks',
      '',
      '- [ ] Task 1',
      '',
      '---',
      '',
      '## Notes',
      '',
    },
  },
  default = {
    path = '',
    -- name = function()
    --   -- default name with random number in hex
    --     return 'default_' .. string.format('%x', math.random(16, 1000000)):sub(1, 4)
    -- end, -- or a function that returns the name
    content = {
      function()
        return frontmatter({ category = 'note' })
      end,
      '',
      '# {{name}}',
    },
  },
}
