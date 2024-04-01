local function setup(cfg)
  local cfg = require('mkdn.config').setup(cfg or {})

  if cfg.follow_link then
    vim.keymap.set({ 'n', 'x' }, 'gx', require('mkdn.lnk').follow_link)
  end
  -- if cfg.paste_link then
  --   vim.keymap.set({ 'n', 'x' }, 'gp', require('mkdn.lnk').paste_link)
  -- end
end

return {
  setup = setup,
  list_files = require('mkdn.finder').md_files,
  grep_files = require('mkdn.finder').md_grep,
}
