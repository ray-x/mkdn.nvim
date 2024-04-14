local M = {}
M.config = function()
  return M._config
end

M.setup = function(cfg)
  local function frontmatter(args)
    local frontmatter = {
      '---',
      'title: {{title}}',
      'auther: {{author}}',
      'date: ' .. os.date('%Y-%m-%d'),
      'id: ' .. os.time(),
      'tags: ' .. (args['tags'] or ''),
      'category: ' .. (args['category'] or ''),
      'type: post',
    }

    local used = { 'title', 'author', 'date', 'id', 'tags', 'category', 'type' }
    -- we can have other optional frontmatter values
    for k, v in pairs(args) do
      if not vim.tbl_contains(used, k) then
        if type(v) == 'table' then
          v = '[' .. table.concat(v, ',') .. ']'
        elseif type(v) == 'function' then
          v = v()
        end
        table.insert(frontmatter, k .. ': ' .. v)
      end
    end

    table.insert(frontmatter, '---')
    return frontmatter
  end

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
        -- some default value for templates e.g. {{auther}}
        author = os.getenv('USER'),
        date = os.date('%Y-%m-%d'),
      },
      daily = {
        name = function()
          return os.date('%Y-%m-%d')
        end, -- or a function that returns the name
        path = 'journal',
        content = {
          function()
            return frontmatter({ tags = 'daily', category = 'daily' })
          end,
          '',
          '---',
          '',
          '# {{date}}',
          '',
          '## Tasks',
          '',
          '- [ ] Task 1',
          '',
          '---',
          '',
          '## Notes',
          '',
        },
      },
      default = {
        path = '',
        name = function()
          -- default name with random number in hex
          vim.ui.input({
            prompt = 'Note name: ',
            default = 'default_' .. string.format('%x', math.random(16, 1000000)):sub(1, 4),
          }, function(result)
            return result
          end)
        end, -- or a function that returns the name
        content = {
          function()
            return frontmatter({ category = 'note' })
          end,
          '# {{name}}',
        },
      },
    },
  }
  M._config = vim.tbl_deep_extend('force', M._config, cfg or {})
  if M._config.notes_root[#M._config.notes_root] ~= '/' then
    M._config.notes_root = M._config.notes_root .. '/'
  end
  for _, template in pairs(M._config.templates) do
    if template.path and template.path[#template.path] ~= '/' then
      template.path = template.path .. '/'
    end
  end
  return M._config
end

return M
