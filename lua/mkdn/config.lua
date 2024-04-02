local M = {}
M.config = {
  follow_link = 'gx',
  paste_link = '<leader>u',
  telescope = {},
}

M.setup = function(cfg)
  M.config = vim.tbl_extend('force', M.config, cfg or {})
  return M.config
end

return M
