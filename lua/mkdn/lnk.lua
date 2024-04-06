local log = require('mkdn.utils').log

local function download_asset(url)
  -- Pattern to check if the URL points to an image
  local image_pattern = '\\v\\.(jpg|jpeg|png|gif|bmp|svg)$'
  local assets_pattern = require('mkdn.config').config().assets_pattern

  -- Check if URL ends with an image extension
  if vim.fn.matchstr(url, assets_pattern) ~= '' then
    print('URL does not point to an image.')
    return false
  end

  -- Extract filename from URL
  local filename = url:match('^.+/(.+)$')
  local note_root = require('mkdn.config').config().note_root
  local assets_path = require('mkdn.config').config().assets_path
  local bang = vim.fn.matchstr(url, image_pattern) ~= '' and '!' or ''
  local file_path = note_root .. '/' .. assets_path .. '/' .. filename
  local assets_rel_path = './' .. assets_path .. '/' .. filename

  -- Ensure the assets directory exists
  vim.fn.mkdir(assets_path, 'p')

  -- Download the image using curl
  local command = string.format("curl -s -o '%s' '%s'", vim.fn.shellescape(file_path), url)
  local result = os.execute(command)

  if result == true or result == 0 then -- os.execute returns true or 0 upon success depending on the Lua version
    vim.notify('Image downloaded successfully to: ' .. file_path)
    -- Insert the Markdown link to the image points to asset directory
    local markdown_link = string.format('%s[image](%s)', bang, assets_rel_path)
    vim.api.nvim_put({ markdown_link }, 'l', true, true)
    return true
  else
    vim.notify('Failed to download the image.')
    return false
  end
end

-- download_asset('https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png')

local function fetch_and_paste_url()
  -- Get content of the unnamed register
  local url = vim.fn.getreg('*')

  -- Check if the content is likely a URL
  if not url:match('^https?://') then
    return false
  end
  -- if it is an image URL, download the image and return
  if download_asset(url) then
    return true
  end

  -- Use curl to fetch the webpage content.
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
  return true
end

local function find_link_under_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Adjust the row to 0-indexed.

  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  if not line then
    log('no line found')
    return nil
  end

  local pattern = '()(%b[])%((.-)%)()'

  for startPos, markdownText, link, endPos in line:gmatch(pattern) do
    -- Adjust for Lua's 1-indexing in string patterns.
    startPos, endPos = startPos - 1, endPos - 1

    if col >= startPos and col <= endPos then
      -- Check if the link is an HTTP URL or a local file path.
      if link:match('^https?://') then
        return {
          url = link,
          start_col = startPos,
          end_col = endPos,
        }
      else
        return {
          path = link,
          start_col = startPos,
          end_col = endPos,
        }
      end
    end
  end
  log('no link found')
  return nil
end

local function follow_link()
  local link = find_link_under_cursor() -- matches []() links only
  log('found link: ', link)
  if link then
    if link.url then
      return vim.ui.open(link.url)
    elseif link.path then
      vim.schedule(function()
        return vim.cmd('silent edit ' .. link.path)
      end)
    end
  end
  log('lsp definition')
  vim.schedule(function()
    return vim.lsp.buf.definition()
  end)
end

-- [google](https://google.com)
-- [readme](README.md)
-- [[sample]]

-- follow_link()

return {
  fetch_and_paste_url = fetch_and_paste_url,
  follow_link = follow_link,
}
