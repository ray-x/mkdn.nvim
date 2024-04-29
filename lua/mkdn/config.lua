local M = {}
M.config = function()
  return vim.tbl_deep_extend('keep', {}, M._config)
end

M.setup = function(cfg)
  local frontmatter = require('mkdn.templates').frontmatter
  M._config = {
    follow_link = 'gx',
    paste_link = '<leader>u',
    telescope = {},
    notes_root = os.getenv('HOME') .. '/notes',
    note_path = '',
    daily_path = '',
    assets_path = 'assets',
    assets_pattern = [[\v\.(png|jpg|jpeg|gif|svg|pdf|mp4|webm|zip|tar|gz|7z|rar|mp3|wav|flac|ogg|docx|pptx|xlsx|csv|json|xml|yaml|toml|ts|go|py|rb|java|c|cpp|rs|lua|sh|bash|zsh|fish|ps1|bat|cmd|txt|md|org|tex|vim|yaml|yml|toml|json|scss|sass|less|js|ts|jsx|tsx|vue|py|rb|java|c|cpp|h|hpp|rs|lua|sh|bash|zsh|fish|ps1|bat|cmd|txt|md|org|tex|vim)$]],
    author = os.getenv('USER'),
    templates = {
      _meta = { -- meta data for templates
        -- some default value for templates e.g. {{author}}
        author = os.getenv('USER'),
        date = os.date('%Y-%m-%d'),
        paths = {
          -- plugin install dir of lazy
          vim.fn.stdpath('data') .. '/lazy/mkdn.nvim/templates/',
          -- workspace ./tempaltes
          vim.fn.getcwd() .. '/templates/',
        },
      },
      daily = require('mkdn.templates').daily,
      default = require('mkdn.templates').default,
    },
  }

  M._config = vim.tbl_deep_extend('force', M._config, cfg or {})

  if M._config.notes_root[#M._config.notes_root] ~= '/' then
    M._config.notes_root = M._config.notes_root .. '/'
  end
  for k, template in pairs(M._config.templates) do
    if template.path and template.path[#template.path] ~= '/' then
      M._config.templates[k].path = template.path .. '/'
    end
  end
  return M._config
end

return M
