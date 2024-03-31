local config = {
  follow_link = true,
  paste_link = true,
}

local function setup(cft)
  config = vim.tbl_extend('force', config, cft)
  if config.follow_link then
    vim.keymap.set({ 'n', 'x' }, 'gx', require('mkdn.lnk').follow_link)
  end
  if config.paste_link then
    vim.keymap.set({ 'n', 'x' }, 'gp', require('mkdn.lnk').paste_link)
  end
end

return {
  setup = setup,
  find_files = require('mkdn.finder').md_files,
  grep_files = require('mkdn.finder').md_grep_telescope,
}
