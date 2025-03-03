-- Create new note with Command NewNote notename
local log = require('mkdn.utils').log
local M = {}
local sep = '/'

M.insert_template=function(opts)
  -- insert text in background
  local note_name = opts.note_name or vim.fn.expand('%:t:r')
  local abs_file_path = vim.fn.expand('%:p')
  local template = opts.template
  local note = opts.note or io.open(abs_file_path, 'a+')
  if not note then
    vim.notify('Error: Cannot open note at ' .. abs_file_path)
    return
  end
  local meta = vim.tbl_deep_extend('force', {}, require('mkdn.config').config().templates._meta)
  meta.title = note_name
  meta.name = note_name

  for _, line in ipairs(template.content) do
    local function write_line(l)
      log(l)
      -- io.write or nvim_buf_set_lines
      if type(l) == 'string' then
        -- expands {{key}} to value from meta
        local key = string.match(l, '{{(.-)}}')
        if key then
          l = string.gsub(l, '{{' .. key .. '}}', meta[key])
        end
        return note:write(l .. '\n')
      end
      -- I not plan to support tables inside table
      if type(l) == 'function' then
        local lines = l()
        log('func returns ', lines)
        if not lines then
          vim.notify('Error: invalid function inside template')
        end
        if type(lines) == 'string' then
          write_line(lines)
        elseif type(lines) == 'table' then
          for _, l2 in ipairs(lines) do
            write_line(l2)
          end
        end
      end
    end
    write_line(line)
  end
  if not opts.note then
    note:close()
  end
  vim.cmd('silent! e ')
end

M.new_note_from_template = function(template)
  local note_path = require('mkdn.templates').tmpl_path(template)
  local new_note = function(note_name)
    -- local note_name = template.name and (type(template.name) == 'function' and template.name() or template.name or 'default')
    if vim.fn.filereadable(note_name) == 1 then
      vim.notify('Note already exists')
      return vim.cmd('silent! e ' .. note_name)
    end
    local note, err = io.open(note_name, 'a+')
    if not note then
      vim.notify('Error: Cannot create note at ' .. note_name .. " err: ".. err)
      return
    end
    M.insert_template({note = note, note_name = note_name, template = template})
    note:close()
    vim.cmd('silent! e ' .. note_name)
  end
  if not note_path then
    vim.ui.input({
      prompt = 'Enter note name',
      default = template.name or 'default',
    }, function(note_name)
      local root = require('mkdn.config').config().notes_root
      local p = template.path
      note_name = root .. sep .. p .. sep .. note_name .. '.md'
      new_note(note_name)
    end)
  else
    new_note(note_path)
  end
end

-- use default templates to create note
-- the argument can be
-- 1. template_name path/note_name
-- 2. path/note_name
-- 3. template_name, note_name
-- 4. note_name
-- 5. single argumement override a template { template_name = {} } or {} override default

local function new_note(opts)
  log(opts)
  opts = opts.fargs

  local cfg = require('mkdn.config').config()
  local template = vim.tbl_deep_extend('force', {}, cfg.templates.default )

  -- if argument is a table override default template
  if type(opts[1]) == 'table' then
    for k, v in pairs(opts[1]) do
      if cfg.templates[k] then
        template = vim.tbl_deep_extend('force', cfg.templates[k], v)
      else
        template = vim.tbl_deep_extend('force', cfg.templates.default, opts[1])
      end
      goto create
    end
  end

  -- check if 1st argument is template name
  if opts[1] and cfg.templates[opts[1]] then
    template = cfg.templates[opts[1]]
    table.remove(opts, 1)
  end
  template = vim.tbl_deep_extend('force', {}, template, opts) -- clone before use

  -- template is default
  if opts[1] and type(opts[1]) == 'string' then
    local path = string.match(opts[1], '(.*)/')
    local name = string.match(opts[1], '/(.*)')
    if path and name then
      template.path = path
      template.name = name
    else
      template.name = opts[1]
    end
  end

  ::create::
  M.new_note_from_template(template)
end

local function new_daily(opts)
  local bang = opts.bang == 1
  opts = opts.fargs or {}
  local append
  local cfg = vim.tbl_deep_extend('keep', {}, require('mkdn.config').config().templates.daily)
  if bang then
    append = vim.fn.getreg('*')
    local content = vim.tbl_deep_extend('force', {}, cfg.content)
    table.insert(content, append)
    cfg.content = content
  end

  local daily = vim.tbl_deep_extend('force', {}, cfg, opts)
  M.new_note_from_template(daily)
end

vim.api.nvim_create_user_command('MkdnNew', new_note, {
  nargs = '*',
  bang = false,
  bar = false,
  range = false,
})

vim.api.nvim_create_user_command('MkdnDaily', function(args)

  local daily = vim.tbl_deep_extend('keep', {}, require('mkdn.config').config().templates.daily)
  local note_path = require('mkdn.templates').tmpl_path(daily)
  if vim.fn.filereadable(note_path) == 1 then
    vim.notify('Note already exists')
    return vim.cmd('silent! e ' .. note_path)
  end
  new_daily(args)
end, {
  -- nargs = '*',
  bang = false,
  bar = false,
  range = false,
})

vim.api.nvim_create_user_command('MkdnNewDaily', new_daily, {
  -- nargs = '*',
  bang = false,
  bar = false,
  range = false,
})

local select_template = function(on_choice)
  local templates = require('mkdn.config').config().templates
  local templates_list = {}

  local reserved = { '_meta' }
  for k, v in pairs(templates) do
    if not vim.tbl_contains(reserved, k) then
      table.insert(templates_list, k)
    end
  end
  local selected_template
  vim.ui.select(templates_list, {
    prompt = 'Select template',
    format_item = function(item)
      return 'use ' .. item .. ' to create note'
    end,
  }, function(choice)
    on_choice(choice)
  end)
end

-- capture note: create a new note with predefined template
-- arguments:
-- 1. opts: table from cmd line and wrapped by create_user_command
local function capture_note(opts)
  local bang = opts.bang == 1
  local range = opts.range or 0
  if bang then
    -- new daily with clipboard content
    return new_daily(opts)
  end
  local append
  if range == 2 then
    append = vim.fn.getline(line1, line2)
  end
  select_template(function(choice)
    local templates = require('mkdn.config').config().templates
    local template = templates[choice]
    template = vim.tbl_deep_extend('force', {}, template) -- clone template
    -- local template = vim.tbl_deep_extend('force', template, templates[choice])
    local clipboard = opts.register or false
    local notes = function()
      if clipboard then
        -- read from register *
        local content = vim.fn.getreg('*')
        if content then
          return content
        end
      end
      -- for visal mode
      if range or vim.api.nvim_get_mode().mode:lower() == 'v' then
        local content = vim.fn.getline("'<", "'>")
        if content then
          return content
        end
      end
      return ''
    end
    -- append capture content to end of note content
    table.insert(template.content, notes)
    M.new_note_from_template(template)
  end)
end


local function insert_template()
  select_template( function(choice)
    local templates = require('mkdn.config').config().templates
    local template = templates[choice]
    M.insert_template({template = template})
  end)
end

-- A Telescope cmd to list all notes
local function list_notes()
  local notes_path = require('mkdn.config').config().notes_root
  require('telescope.builtin').find_files({
    prompt_title = 'Notes',
    cwd = notes_path,
  })
end

vim.api.nvim_create_user_command('MkdnListNotes', list_notes, {
  nargs = 0,
  bang = false,
  bar = false,
  range = false,
})

vim.api.nvim_create_user_command('MkdnInsertTemplate', insert_template, {
  nargs = 0,
  bang = false,
  bar = false,
  range = false,
})

vim.api.nvim_create_user_command('MkdnCapture', capture_note, {
  nargs = '*',
  bang = true,
  bar = false,
  range = true,
})



return M
