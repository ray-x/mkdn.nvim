-- Create new note with Command NewNote notename
local log = require('mkdn.utils').log
local M = {}

-- use default templates to create note
-- the argument is path/notename
local function new_note(opts)
  log(opts)
  opts = opts.fargs
  local note_name = opts[1]
  local default_templates = {}
  local _defult = require('mkdn.config').config().templates.default
  default_templates = vim.tbl_deep_extend('force', default_templates, _defult)
  if note_name ~= nil then
    -- split path and name
    local path = string.match(note_name, '(.*)/')
    local name = string.match(note_name, '/(.*)')
    if path and name then
      default_templates.path = path
      default_templates.name = name
    else
      default_templates.name = note_name
    end
  end
  M.new_note_from_template(default_templates)
end

local function new_daily(opts)
  local cfg = require('mkdn.config').config().templates.daily
  local daily = vim.tbl_deep_extend('force', {}, cfg, opts)
  M.new_note_from_template(daily)
end

vim.api.nvim_create_user_command('MkdnNewNote', new_note, {
  nargs = 1,
  complete = 'file',
  bang = false,
  bar = false,
  range = false,
})

vim.api.nvim_create_user_command('MkdnNewDaily', new_daily, {
  nargs = 1,
  -- complete = os.date('%Y-%m-%d'),
  bang = false,
  bar = false,
  range = false,
})

M.new_note_from_template = function(template)
  local note_root = require('mkdn.config').config().notes_root
  local templates = require('mkdn.config').config().templates
  if not template then
    template = templates.default
  end
  local path = template.path and template.path .. '/' or '/'
  local file_path = note_root .. path
  local note_name
  log(template)
  if type(template.name) == 'function' then
    note_name = template.name()
  else
    note_name = template.name
  end
  local note_path = file_path .. '/' .. note_name .. '.md'
  -- check if file exists
  if vim.fn.filereadable(note_path) == 1 then
    vim.notify('Note already exists')
    return vim.cmd('silent! e ' .. note_path)
  end
  local note = io.open(note_path, 'w')
  if not note then
    vim.notify('Error: Cannot create note')
    return
  end

  local meta = require('mkdn.config').config().templates._meta
  meta.title = note_name
  meta.name = note_name

  for _, line in ipairs(template.content) do
    local function write_line(l)
      log(l)
      if type(l) == 'string' then
        -- expands {{key}} to value from meta
        local key = string.match(l, '{{(.-)}}')
        if key then
          l = string.gsub(l, '{{' .. key .. '}}', meta[key])
        end
        return note:write(l .. '\n')
      end
      -- I not plan to support tables inside talbe
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
  note:close()
  vim.cmd('silent! e ' .. note_path)
end

-- capture note: create a new note with predefined template
local function capture_note()
  -- write default content include front matter
  -- read templates from config
  local templates = require('mkdn.config').config().templates
  -- let user select template use ui.select
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
    local template = templates[choice]
    M.new_note_from_template(template)
  end)
end

-- A Telescope cmd to list all notes
local function list_notes()
  notes_path = require('mkdn.config').config().notes_root
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

vim.api.nvim_create_user_command('MkdnCapture', capture_note, {
  nargs = 0,
  bang = false,
  bar = false,
  range = false,
})

return M
