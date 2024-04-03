-- Create new note with Command NewNote notename
local log = require('mkdn.utils').log

local function new_note(opts)
  log(opts)
  opts = opts.fargs
  local note_name = opts[1]
  if not note_name then
    vim.ui.input(
      { prompt = 'Note name: ', default = os.date('%Y-%m-%d_%H:%M:%S') },
      function(result)
        if not result then
          note_name = os.date('%Y-%m-%d_%H:%M:%S')
        end
        note_name = result
      end
    )
  end
  local note_path = os.getenv('HOME') .. '/notes/'
  if require('mkdn.config').config().notes_path then
    note_path = require('mkdn.config').config().notes_path
  end
  -- notes_root
  local notes_root
  if require('mkdn.config').config().notes_root then
    note_root = require('mkdn.config').config().notes_root
  end
  -- argument in subfoler/notename format
  if string.match(note_name, '/') then
    local subfolder = string.match(note_name, '(.*)/')
    note_name = string.match(note_name, '/(.*)')
    note_path = notes_root or note_path .. '/' .. subfolder .. '/'
  end
  note_path = note_path .. note_name .. '.md'
  -- check if file exists
  if vim.fn.filereadable(note_path) == 1 then
    vim.notify('Note already exists')
    return vim.cmd('e ' .. note_path)
  end
  local note = io.open(note_path, 'w')
  if not note then
    print('Error: Cannot create note')
    return
  end
  -- write default content include front matter
  note:write('---\n')
  note:write('title: ' .. note_name .. '\n')
  -- id unix timestamp
  note:write('id: ' .. os.time() .. '\n')
  local author = require('mkdn.config').config().author
  note:write('author:' .. author .. '\n')
  note:write('date' .. os.date('%Y-%m-%d') .. '\n')
  note:write('tags: \n')
  note:write('category: \n')
  note:write('type: post\n')
  note:write('---\n')

  note:write('# ' .. note_name .. '\n')
  note:close()
  vim.cmd('e ' .. note_path)
end

local function new_daily(opts)
  local note_name = os.date('%Y-%m-%d')
  local note_path = os.getenv('HOME') .. '/notes/'
  if require('mkdn.config').config().daily_path then
    note_path = require('mkdn.config').config().daily_path
  end

  opts = opts.fargs
  if opts[1] then
    note_name = opts[1]
  end
  note_path = note_path .. note_name .. '.md'

  -- check if file exists
  if vim.fn.filereadable(note_path) == 1 then
    vim.notify('Note already exists')
    return vim.cmd('noautocmd e ' .. note_path)
  end

  local note = io.open(note_path, 'w')
  if not note then
    print('Error: Cannot create note')
    return
  end
  -- write default content include front matter
  note:write('---\n')
  note:write('id: ' .. os.time() .. '\n')
  note:write('title: ' .. note_name .. '\n')
  local author = require('mkdn.config').config().author
  note:write('author:' .. author .. '\n')
  note:write('date' .. os.date('%Y-%m-%d') .. '\n')
  note:write('tags: \n')
  note:write('category: daily\n')
  note:write('type: post\n')
  note:write('---\n')

  note:write('# ' .. 'Daily' .. '\n')
  note:close()
  vim.cmd('e ' .. note_path)
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

-- A Telescope cmd to list all notes
local function list_notes()
  local notes_path = os.getenv('HOME') .. '/notes/'
  if require('mkdn.config').config().notes_path then
    notes_path = require('mkdn.config').config().notes_path
  end
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
