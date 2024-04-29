local log = require('mkdn.utils').log

local function download_asset(url)
  -- Pattern to check if the URL points to an image
  local image_pattern = '\\v\\.(jpg|jpeg|png|gif|bmp|svg)$'
  local assets_pattern = require('mkdn.config').config().assets_pattern
  log(vim.fn.empty(vim.fn.matchstr(url, assets_pattern)))
  -- Check if URL ends with an image extension
  if vim.fn.empty(vim.fn.matchstr(url, assets_pattern)) == 1 then
    return false
  end

  -- Extract filename from URL
  local filename = url:match('^.+/(.+)$')
  local notes_root = require('mkdn.config').config().notes_root
  local assets_path = require('mkdn.config').config().assets_path
  local bang = vim.fn.matchstr(url, image_pattern) ~= '' and '!' or ''
  local file_dir = notes_root .. assets_path
  local file_path = file_dir .. '/' .. filename
  -- Ensure the assets directory exists
  vim.fn.mkdir(file_dir, 'p')

  local rel_path = require('mkdn.utils').get_relative_path(file_path)

  -- use -L to follow redirects
  local command = string.format('curl --silent -L -o %s %s', file_path, vim.fn.shellescape(url))

  log(command)
  local result = os.execute(command)
  local result = 0

  if result == true or result == 0 then -- os.execute returns true or 0 upon success depending on the Lua version
    vim.notify('Image downloaded successfully to: ' .. file_path)
    -- Insert the Markdown link to the image points to asset directory
    local markdown_link = string.format('%s[image](%s)', bang, rel_path)
    vim.api.nvim_put({ markdown_link }, 'l', true, true)
    return true
  else
    vim.notify('Failed to download the image.' .. result)
    return false
  end
end

-- download_asset('https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png')

local function fetch_and_paste_url(url)
  -- Get content of the unnamed register
  url = url or vim.fn.getreg('*')

  -- Check if the content is likely a URL
  if not url:match('^https?://') then
    vim.notify('No URL found in the clipboard.')
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
  vim.notify('no link found at cursor position')
  return nil
end

local function image_open(rel_uri)
  local uv = vim.uv or vim.loop
  local os_name = uv.os_uname().sysname
  local is_win = os_name:find('Windows') or os_name:find('MINGW')
  local is_linux = os_name:find('Linux')

  -- check if the path exists
  if vim.fn.filereadable(rel_uri) == 0 then
    -- restore relative path
    local current_file = vim.fn.expand('%:p')

    rel_uri = vim.fn.fnamemodify(current_file, ':h') .. '/' .. rel_uri

    if vim.fn.filereadable(rel_uri) == 0 then
      vim.notify('File not found: ' .. rel_uri)
      return
    end
  end

  local cmd = 'open ' .. rel_uri
  if is_win then
    cmd = 'start ' .. rel_uri
  end
  if is_linux then
    cmd = 'xdg-open ' .. rel_uri
  end

  log(cmd)
  vim.fn.system(cmd)
end

local function follow_link()
  local link = find_link_under_cursor() -- matches []() links only
  log('found link: ', link)
  if link then
    if link.url then
      return vim.ui.open(link.url)
    elseif link.path then
      -- check if path is a local file of image
      local assets_pattern = require('mkdn.config').config().assets_pattern
      local assets_path = require('mkdn.config').config().assets_path
      log(link.path, link.path:find(assets_path), vim.fn.matchstr(link.path, assets_pattern))
      if link.path:find(assets_path) and vim.fn.matchstr(link.path, assets_pattern) ~= '' then
        return image_open(link.path)
      end
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

-- paste a image from clipboard
--   -- MacOS (osascript) as a fallback  https://gist.github.com/miguelmota/b0e05d8c60cd92c646ddd3edcb66ea05
-- mac only
local paste_cmd = [[osascript \
    -e 'on run args' \
    -e 'set png_data to the clipboard as «class PNGf»' \
    -e 'set the_file to open for access POSIX path of (POSIX file (first item of args)) with write permission' \
    -e 'write png_data to the_file' \
    -e 'close access the_file'\
    -e end \
    "$@"]]

-- follow_link()
-- [google](https://google.com)
-- [readme](README.md)
-- [[sample]]
-- ![image](./assets/nvim-icon.png)

-- follow_link()

return {
  fetch_and_paste_url = fetch_and_paste_url,
  follow_link = follow_link,
}

-- download_asset('https://ashki23.github.io/markdown-latex.html')
-- download_asset('https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png')
-- download_asset('https://icons.iconarchive.com/icons/papirus-team/papirus-apps/256/nvim-icon.png')
-- fetch_and_paste_url('https://ashki23.github.io/markdown-latex.html')
-- fetch_and_paste_url('https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png')
