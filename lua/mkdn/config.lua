local M = {}
M.config = function()
  return M._config
end

M.setup = function(cfg)
  M._config = {
    follow_link = 'gx',
    paste_link = '<leader>u',
    telescope = {},
    note_root = os.getenv('HOME') .. '/notes',
    note_path = os.getenv('HOME') .. '/notes',
    daily_path = os.getenv('HOME') .. '/notes',
    author = os.getenv('USER'),
  }
  M._config = vim.tbl_extend('force', M._config, cfg or {})
  return M._config
end

return M
