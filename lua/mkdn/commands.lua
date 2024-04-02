vim = vim or {}
local function parse_args(args_str)
  local params = {}
  for _, param in ipairs(vim.split(args_str, ' ')) do
    local key, value = unpack(vim.split(param, ':'))
    if not value then
      break
    end
    if value:find(',') then
      params[key] = vim.split(value, ',')
    else
      params[key] = value
    end
  end
  return params
end

local function mkdn_grep_files(args)
  local args_table = parse_args(args)
  require('mkdn.finder').md_files({ filter = args_table })
  -- Process the args_table as needed
end
local function mkdn_list_files(args)
  local args_table = parse_args(args)
  require('mkdn.finder').md_grep({ filter = args_table })
  -- Process the args_table as needed
end

local function mkdn_tag(args)
  if vim.fn.empty(args) == 1 then
    args = vim.fn.expand('<cword>')
  end
  require('mkdn.finder').md_tag({ default_text = args })
end

vim.api.nvim_create_user_command('MkdnListFiles', function(input)
  mkdn_list_files(input.args)
end, {
  nargs = '*',
  complete = function(ArgLead, CmdLine, CursorPos)
    return { 'key:value' }
  end,
})

vim.api.nvim_create_user_command('MkdnTag', function(input)
  mkdn_tag(input.args)
end, {
  nargs = '*',
  complete = function(ArgLead, CmdLine, CursorPos)
    return { 'tagname' }
  end,
})

vim.api.nvim_create_user_command('MkdnGrepFiles', function(input)
  mkdn_grep_files(input.args)
end, {
  nargs = '*',
  complete = function(ArgLead, CmdLine, CursorPos)
    return { 'key:value' }
  end,
})

vim.api.nvim_create_user_command('MkdnToc', function()
  vim.lsp.buf.document_symbol()
end, {
  nargs = 0,
})

vim.api.nvim_create_user_command('MkdnTocTelescope', function()
  vim.cmd('Telescope lsp_document_symbols')
end, {
  nargs = 0,
})
