local log = require('mkdn.utils').log
local function fetch_and_paste_url_title()
  -- Get content of the unnamed register
  local url = vim.fn.getreg('*')

  -- Check if the content is likely a URL
  if not url:match('^https?://') then
    print('Register does not contain a valid URL')
    return
  end

  -- Use curl to fetch the webpage content. Adjust timeout as necessary.
  local cmd = string.format('curl -m 5 -s %s', vim.fn.shellescape(url))
  local result = vim.fn.system(cmd)

  -- Extract the title of the webpage
  local title = result:match('<title>(.-)</title>')
  if not title or title == '' then
    title = ''
  end

  -- Format and paste the Markdown link
  local markdown_link = string.format('[%s](%s)', title, url)
  vim.api.nvim_put({ markdown_link }, 'l', true, true)
end

local setup_opts = {
  auto_quoting = true,
  mappings = {},
}

local function find_word_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local start_col = col
  local end_col = col
  while start_col > 0 and line:sub(start_col, start_col):match('%w') do
    start_col = start_col - 1
  end
  while end_col < #line and line:sub(end_col, end_col):match('%w') do
    end_col = end_col + 1
  end
  if start_col == end_col then
    return nil
  end
  return {
    text = line:sub(start_col + 1, end_col),
    start_col = start_col + 1,
    end_col = end_col,
  }
end

-- for concealed text
local function find_link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local start_col = col
  local end_col = col
  while start_col > 0 and line:sub(start_col, start_col):match('%w') do
    start_col = start_col - 1
  end
  while end_col < #line and line:sub(end_col, end_col):match('%w') do
    end_col = end_col + 1
  end
  local link = line:match('%[.*%]%((.*)%)', start_col)
  log(link)
  if link then
    return {
      url = link,
      start_col = start_col + 1,
      end_col = end_col,
    }
  end
  return nil
end

local function follow_link()
  local word = find_word_under_cursor()
  local link = find_link_under_cursor() -- matches []() links only
  if link and link.url then
    if link.url:match('^https?://') then
      -- a link
      vim.ui.open(link.url)
    elseif link.url:match('^#') then
      -- an anchor
      vim.fn.search('^#* ' .. link.url:sub(2))
    else
      -- a file
      vim.cmd('e ' .. link.url)
    end
  elseif word then
    if word.text:match('^https?://') then
      -- Bare url i.e without link syntax
      vim.ui.open(word.text)
    else
      -- create a link
      local filename = string.lower(word.text:gsub('%s', '_') .. '.md')
      vim.notify('Creating link to ' .. filename)
      vim.cmd('norm! "_ciW[' .. word.text .. '](' .. filename .. ')')
    end
  end
end

-- local test_telescope = function()
-- md_grep_telescope({
--   search_files = {
--     '/Users/rayxu/Library/CloudStorage/Dropbox/obsidian/work/cms.md',
--     '/Users/rayxu/Library/CloudStorage/Dropbox/obsidian/work/rec.md',
--   },
--   -- search_dirs = {
--   --   '/Users/rayxu/Library/CloudStorage/Dropbox/obsidian/work',
--   -- },
-- })
-- end

-- test_telescope()

return {
  fetch_and_paste_url_title = fetch_and_paste_url_title,
  follow_link = follow_link,
}
