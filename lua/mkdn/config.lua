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
    note_root = os.getenv('HOME') .. '/notes',
    note_path = os.getenv('HOME') .. '/notes',
    daily_path = os.getenv('HOME') .. '/notes',
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
        path = 'journal/',
        content = {
          function()
            return frontmatter({ tags = 'daily', category = 'daily' })
          end,
          '# {{name}}',
          '\n',
          '## Tasks',
          '- [ ] Task 1',
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
  return M._config
end

return M
