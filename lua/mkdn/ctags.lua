local log = lprint or require('mkdn.utils').log

local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
-- local actions = require('telescope.actions')
-- local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
-- local sorters = require('telescope.sorters')
local conf = require('telescope.config').values

local path_to_ctags = 'tags' -- Adjust this path to where your tags file is stored
-- This function filters tags from a ctags file based on input tags
-- in the future, we can use this to filter tags
-- search ^core go !rb  (search for core (full match), go, exclude rb)
-- search go | rb (search for go or rb)
local function filter_ctags(tags)
  local result = {}
  local exclude_tags = {}
  local exclude_files = {}
  if not tags or tags == '' then
    -- return top 20 lines from tag file
    -- file exists
    if vim.fn.filereadable(path_to_ctags) == 0 then
      vim.notify('Tags file not found')
      return result
    end
    for l in io.lines(path_to_ctags) do
      table.insert(result, l)
      if #result > 20 then
        return result
      end
    end
  end
  local taglist = vim.split(tags, '%s+')
  -- remove leading '#' in tag
  for i, tag in ipairs(taglist) do
    if tag:sub(1, 1) == '#' then
      taglist[i] = tag:sub(2, #tag)
    end
    if tag:sub(1, 1) == '!' then
      local start = 2
      if tag:sub(2, 2) == '#' then
        start = 3
      end
      if #tag - start > 1 then
      table.insert(exclude_tags, tag:sub(start, #tag))
    end
    end
  end
  log ('required tags', taglist, 'exclude tags', exclude_tags)
  local files_with_tags = {}
  local taglines = {}

  for line in io.lines(path_to_ctags) do
    local tagname, file = line:match('^([^\t]+)\t([^\t]+)\t')
    for _, tag in ipairs(taglist) do
      if tagname:match(tag) then
        if not files_with_tags[file] then
          files_with_tags[file] = {}
        end
        if not vim.tbl_contains(files_with_tags[file], tagname) then
          table.insert(files_with_tags[file], tagname)
          if taglines[file] then
            table.insert(taglines[file], line)
          else
            taglines[file] = { line }
          end
        end
      end
      if vim.tbl_contains(exclude_tags, tag) then
        exclude_files[file] = true
      end
    end
  end

  local results = {}
  -- log(taglines)
  -- may be I can cache tag lines ?
  for file, ts in pairs(files_with_tags) do
    log(file, ts)
    if not ts or #ts < #taglist then
      goto continue
    end
    for _, l in ipairs(taglines[file]) do
      if not exclude_files[file] then
        table.insert(results, l)
      end
    end
    ::continue::
  end
  log('result', results)
  taglines = nil -- cleanup
  return results
end

-- Create a Telescope picker with dynamic filtering
local function tags_picker(opts)
  local make_entry = require('telescope.make_entry')
  local setup_opts = require('mkdn.config').config().telescope

  opts = vim.tbl_extend('force', setup_opts, opts or {})
  opts.bufnr = vim.api.nvim_get_current_buf()

  opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_ctags(opts))
  pickers
    .new(opts, {
      prompt_title = 'Filter Tags',
      previewer = previewers.ctags.new(opts),
      sorter = conf.generic_sorter(opts),
      finder = finders.new_dynamic({
        fn = function(prompt)
          local res = filter_ctags(prompt)
          return res
        end,
        entry_maker = opts.entry_maker,
      }),
    })
    :find()
end

return {
  picker = tags_picker,
}
