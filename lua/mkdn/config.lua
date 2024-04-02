local M = {}
M.config = function()
  return M._config
end

M.setup = function(cfg)
  M._config = {
    follow_link = 'gx',
    paste_link = '<leader>u',
    telescope = {},
  }
  M._config = vim.tbl_extend('force', M._config, cfg or {})
  return M._config
end

return M
