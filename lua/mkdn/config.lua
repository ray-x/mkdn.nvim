local config = {
  follow_link = true,
  paste_link = true,
  telescope = {
  },
}

local function setup(cfg)
  config = vim.tbl_extend('force', config, cfg or {})
  return config
end
return {
  setup = setup,
  config = config,
}
