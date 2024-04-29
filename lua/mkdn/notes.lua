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
  local meta = require('mkdn.config').config().templates._meta
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
  log(template)
  local cfg = require('mkdn.config').config()
  local note_root = cfg.notes_root
  if not template then
    template = cfg.templates.default
  end
  local path = template.path and (template.path .. sep) or ''
  local file_path = note_root .. path
  local note_name = type(template.name) == 'function' and template.name() or template.name
  local note_path = file_path .. note_name .. '.md'
  log('note name: ', note_name, 'note path: ', note_path)
  -- check if file exists
  if vim.fn.filereadable(note_path) == 1 then
    vim.notify('Note already exists')
    return vim.cmd('silent! e ' .. note_path)
  end
  local note, err = io.open(note_path, 'a+')
  if not note then
    vim.notify('Error: Cannot create note at ' .. note_path .. " err: ".. err)
    return
  end
  M.insert_template({note = note, note_name = note_name, template = template})
  note:close()
  vim.cmd('silent! e ' .. note_path)
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
  opts = opts.fargs or {}
  local cfg = require('mkdn.config').config().templates.daily
  local daily = vim.tbl_deep_extend('force', {}, cfg)

  M.new_note_from_template(daily)
end

vim.api.nvim_create_user_command('MkdnNew', new_note, {
  nargs = '*',
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
local function capture_note()
  select_template(function(choice)
  local templates = require('mkdn.config').config().templates
    local template = templates[choice]
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
  nargs = 0,
  bang = false,
  bar = false,
  range = false,
})



return M
