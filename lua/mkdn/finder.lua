local readFirstNLines = require('mkdn.utils').readFirstNLines
local parseFrontmatter = require('mkdn.utils').parseFrontmatter
local function contains_all(table1, table2)
  for key, value in pairs(table2) do
    if not vim.tbl_contains(table1, value) then
      return false
    end
  end
  return true
end

local function contains_any(table1, table2)
  for key, value in pairs(table2) do
    if vim.tbl_contains(table1, value) then
      return true
    end
  end
  return false
end

local function searchMarkdownFiles(dir, N, criteria, matches)
  matches = matches or {}
  local handle, err = vim.loop.fs_scandir(dir)
  if not handle then
    print('Error opening directory: ' .. err)
    return matches
  end
  local match_all = criteria.match or 'all'
  while true do
    local name, ftype = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end -- No more files or directories

    local filePath = dir .. '/' .. name
    if ftype == 'directory' then
      searchMarkdownFiles(filePath, N, criteria, matches) -- Recursive call
    elseif ftype == 'file' and name:match('%.md$') then
      local fileContent = readFirstNLines(filePath, N)
      if not fileContent then
        print('Error reading file: ' .. filePath)
        break
      end
      local frontmatter = parseFrontmatter(fileContent)
      local match = true
      for key, value in pairs(criteria) do
        local target = frontmatter[key]
        value = type(value) == 'table' and value or { value }
        target = type(target) == 'table' and target or { target }
        if match_all == 'all' then
          match = contains_all(target, value)
        else
          match = contains_any(target, value)
        end
      end

      if match then
        table.insert(matches, filePath)
      end
    end
  end

  return matches
end

local function md_list(criteria, N)
  N = N or 20
  local currentDir = vim.fn.getcwd() -- Get the current working directory
  return searchMarkdownFiles(currentDir, N, criteria)
end

-- print(vim.inspect(md_search({}, 40)))

local md_files = function(opts)
  local pickers = require('telescope.pickers')
  -- local sorters = require('telescope.sorters')
  -- local telescope = require('telescope')
  -- local themes = require('telescope.themes')
  -- local conf = require('telescope.config').values
  local finders = require('telescope.finders')
  local make_entry = require('telescope.make_entry')
  local previewers = require('telescope.previewers')
  opts = opts or {}

  if opts.cwd then
    opts.cwd = vim.fn.expand(opts.cwd)
  else
    --- Find root of git directory and remove trailing newline characters
    opts.cwd = vim.fn.getcwd()
  end

  local conf = require('telescope.config').values
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)
  local files = md_list(opts.filter, 40)
  opts.search = nil
  pickers
    .new(opts, {
      prompt_title = 'Markdown File',
      finder = finders.new_table({ results = files }),
      previewer = previewers.cat.new(opts),
      sorter = conf.file_sorter(opts),
    })
    :find()
end

local tbl_clone = function(original)
  local copy = {}
  for key, value in pairs(original) do
    copy[key] = value
  end
  return copy
end

-- grep 2  (?:#|\\[\\[|(?:^|\\s)-\\s*|tags:\\s*[^,]*,\\s*)keyword(?:\\]\\]|(?=,|\\s|$))

local grep_tag = function(opts)
  local pickers = require('telescope.pickers')
  local sorters = require('telescope.sorters')
  -- local telescope = require('telescope')
  local themes = require('telescope.themes')
  local conf = require('telescope.config').values
  local finders = require('telescope.finders')
  local make_entry = require('telescope.make_entry')
  local previewers = require('telescope.previewers')
  local setup_opts = require('mkdn.config').setup().telescope
  opts = vim.tbl_extend('force', setup_opts, opts or {})

  opts.vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd)

  -- if opts.filter then
  --   opts.search_files = md_list(opts.filter, 40)
  -- end
  if opts.search_dirs then
    for i, path in ipairs(opts.search_dirs) do
      opts.search_dirs[i] = vim.fn.expand(path)
    end
  end
  local where = opts.search_dirs or {}

  local cmd_generator = function(prompt)
    local args = tbl_clone(opts.vimgrep_arguments)

    if not prompt or prompt == '' then
      prompt = vim.fn.expand('<cword>')
    end
    prompt =
      string.format([[(?:#|\[\[|(?:^|\s)-\s*|tags:\s*[^,]*,\s*)%s(?:\]\]|(?=,|\s|$))]], prompt)
    table.insert(args, '--pcre2')
    local types = { '-t', 'md' }
    local cmd = vim.tbl_flatten({ args, prompt, where, types })
    return cmd
  end

  -- apply theme
  if type(opts.theme) == 'table' then
    opts = vim.tbl_extend('force', opts, opts.theme)
  elseif type(opts.theme) == 'string' then
    if themes['get_' .. opts.theme] == nil then
      vim.notify_once(
        'live grep args config theme »' .. opts.theme .. '« not found',
        vim.log.levels.WARN
      )
    else
      opts = themes['get_' .. opts.theme](opts)
    end
  end

  local finder = function()
    return finders.new_job(cmd_generator, opts.entry_maker, opts.max_results, opts.cwd)
  end

  pickers
    .new(opts, {
      prompt_title = 'Live Grep Markdown Files',
      finder = finder(),
      previewer = conf.grep_previewer(opts),
      sorter = sorters.highlighter_only(opts),
      -- attach_mappings = function(_, map)
      --   for mode, mappings in pairs(opts.mappings) do
      --     for key, action in pairs(mappings) do
      --       map(mode, key, action)
      --     end
      --   end
      --   return true
      -- end,
    })
    :find()
end

local md_grep = function(opts)
  local pickers = require('telescope.pickers')
  local sorters = require('telescope.sorters')
  local themes = require('telescope.themes')
  local conf = require('telescope.config').values
  local finders = require('telescope.finders')
  local make_entry = require('telescope.make_entry')
  local setup_opts = require('mkdn.config').setup().telescope
  opts = vim.tbl_extend('force', setup_opts, opts or {})

  opts.vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd)

  if opts.filter then
    opts.search_files = md_list(opts.filter, 40)
  end
  if opts.search_dirs then
    for i, path in ipairs(opts.search_dirs) do
      opts.search_dirs[i] = vim.fn.expand(path)
    end
  end
  local where = opts.search_dirs
  if opts.search_files then
    -- flatten the list of files
    where = opts.search_files
  end

  local cmd_generator = function(prompt)
    local args = tbl_clone(opts.vimgrep_arguments)

    local prompt_parts
    if not prompt or prompt == '' then
      prompt = [[^#\s]]
    end
    prompt_parts = vim.split(prompt, ' ')
    local cmd = vim.tbl_flatten({ args, prompt_parts, where })
    return cmd
  end

  -- apply theme
  if type(opts.theme) == 'table' then
    opts = vim.tbl_extend('force', opts, opts.theme)
  elseif type(opts.theme) == 'string' then
    if themes['get_' .. opts.theme] == nil then
      vim.notify_once(
        'live grep args config theme »' .. opts.theme .. '« not found',
        vim.log.levels.WARN
      )
    else
      opts = themes['get_' .. opts.theme](opts)
    end
  end

  local finder = function()
    local prompt_bufnr = vim.api.nvim_get_current_buf()
    local action_state = require('telescope.actions.state')
    local action_utils = require('telescope.actions.utils')
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    return finders.new_job(cmd_generator, opts.entry_maker, opts.max_results, opts.cwd)
  end

  pickers
    .new(opts, {
      prompt_title = 'Live Grep Markdown Files',
      finder = finder(),
      previewer = conf.grep_previewer(opts),
      sorter = sorters.highlighter_only(opts),
      -- attach_mappings = function(_, map)
      --   for mode, mappings in pairs(opts.mappings) do
      --     for key, action in pairs(mappings) do
      --       map(mode, key, action)
      --     end
      --   end
      --   return true
      -- end,
    })
    :find()
end

return {
  md_files = md_files,
  md_list = md_list,
  md_grep = md_grep,
  md_tag = grep_tag,
}
