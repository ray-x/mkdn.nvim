local function setup(cfg)
  local cfg = require('mkdn.config').setup(cfg or {})

  if cfg.follow_link then
    local key = 'gx'
    if type(cfg.follow_link) == 'string' then
      key = cfg.follow_link
      vim.keymap.set({ 'n', 'x' }, key, function()
        require('mkdn.lnk').follow_link()
      end, { noremap = true, desc = 'Follow the link under the cursor' })
    elseif type(cfg.follow_link) == 'function' then
      cfg.follow_link()
    end
  end

  if cfg.paste_link then
    local key = '<leader>u'
    if type(cfg.parse_link) == 'string' then
      key = cfg.parse_link
      vim.keymap.set({ 'n', 'x' }, key, require('mkdn.lnk').fetch_and_paste_url, {
        noremap = true,
        desc = 'Fetch the title of the URL under the cursor and paste it as a Markdown link',
      })
    elseif type(cfg.paste_link) == 'function' then
      cfg.paste_link()
    end
  end

  require('mkdn.commands')
  require('mkdn.notes')
  if cfg.internal_features then
    require('mkdn.gtd')
    require('mkdn.ctags')
  end
end

return {
  setup = setup,
  list_files = require('mkdn.finder').md_files,
  grep_files = require('mkdn.finder').md_grep,
  grep_tag = require('mkdn.finder').md_tag,
  config = require('mkdn.config').config,
}
