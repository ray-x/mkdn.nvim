-- Helper function to format the current time as a string.
local log = require('mkdn.utils').log
local function current_time_str()
  return os.date('%H:%M')
end

local function find_yaml_block(bufnr, current_line)
  local start_line, end_line
  for i = current_line, current_line + 4 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    if line:match('```') then
      start_line = i
      break
    end
  end
  for i = start_line + 1, start_line + 30, 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    if line:match('```') then -- assume yml length less 20
      end_line = i
      break
    end
  end
  return start_line, end_line
end

-- Helper function to add new time entry or update the last entry in the time list.
local function update_time_list(lines, action)
  local time_list_start, time_list_end
  for i, line in ipairs(lines) do
    if line:find('^time:') then
      time_list_start = i + 1 -- time list starts from the next line
    elseif time_list_start and not time_list_end and line:find('^total:') then
      time_list_end = i - 1 -- time list ends just before the total line
      break
    end
  end

  if not time_list_start or not time_list_end then
    return
  end -- time list not found

  if action == 'start' or action == 'resume' then
    table.insert(lines, time_list_end, '- [' .. current_time_str() .. ']')
  elseif action == 'pause' or action == 'finish' then
    -- Assuming the last entry is the current time range being updated
    local last_entry = lines[time_list_end]
    local new_entry = last_entry:gsub('%]$', ', ' .. current_time_str() .. ']')
    lines[time_list_end] = new_entry
  end
end

local function update_total_time(bufnr, start_row, end_row, total_minutes)
  local hours = math.floor(total_minutes / 60)
  local minutes = total_minutes % 60
  local total_time_str
  if hours > 0 then
    total_time_str = string.format('%d hours %d mins', hours, minutes)
  else
    total_time_str = string.format('%d mins', minutes)
  end
  -- Find the 'total:' line and update it
  for i = start_row + 2, end_row - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    if line:find('^total:') then
      vim.api.nvim_buf_set_lines(bufnr, i, i + 1, false, { 'total: ' .. total_time_str })
      break
    end
  end
end
local function parse_time_entry_to_minutes(entry)
  local hour, min = entry:match('(%d+):(%d+)')
  return tonumber(hour) * 60 + tonumber(min)
end
local function calculate_total_time(bufnr, start_row, end_row)
  local total_minutes = 0
  for i = start_row + 2, end_row  do -- Skipping the "time:" line and the last line
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
    local times = vim.split(line:gsub("[%[%]']", ''), ',')
    if #times == 2 then -- If it's a start and end time
      local start_time = parse_time_entry_to_minutes(times[1])
      local end_time = parse_time_entry_to_minutes(times[2])
      total_minutes = total_minutes + (end_time - start_time)
    end
  end
  return total_minutes
end
local function update_task_total(state)
  local old_state = '%[>%]'
  local new_state = '[|]'
  if state == 'finish' then
    new_state = '[x]'
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Adjust for Lua indexing
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  if not line:match(old_state) then
    return vim.notify('task not started yet')
  end

  local updated_line = line:gsub(old_state, new_state)
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { updated_line })
  local start_line, end_line = find_yaml_block(bufnr, row)
  if not start_line or not end_line then
    vim.notify('YAML block not found')
    return
  end

  -- Assuming the last entry in 'time' is the current session to pause.
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
  for i, line in ipairs(lines) do
    if line:match('- %[%d+:%d+%]') then -- A start time without an end time
      local end_time = os.date('%H:%M')
      line = line:sub(1, #line - 1) -- remove tailing ]
      lines[i] = line .. ', ' .. end_time .. ']'
      vim.api.nvim_buf_set_lines(bufnr, start_line + i - 1, start_line + i, false, { lines[i] })
    end
  end

  local total_minutes = calculate_total_time(bufnr, start_line, end_line)
  update_total_time(bufnr, start_line, end_line, total_minutes)
end

local function finish_task()
  update_task_total('finish')
end

local function pause_task()
  update_task_total('pause')
end

local function start_task()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local task_row = cursor_pos[1] - 1 -- Adjusted for Lua's 1-based indexing

  local line = vim.api.nvim_buf_get_lines(bufnr, task_row, task_row + 1, false)[1]

  local updated_line = line:gsub('%[%s*%]', '[>]')
  vim.api.nvim_buf_set_lines(bufnr, task_row, task_row + 1, false, { updated_line })
  -- Fetch the whole buffer lines
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local yml_start, yml_end

  -- Check if YAML metadata already exists below the task
  for i = task_row + 1, #lines do
    if lines[i]:match('^```yml') then
      yml_start = i
    elseif yml_start and not yml_end and lines[i]:match('^```$') then
      yml_end = i
      break
    elseif lines[i]:match('^%[%s*%]') then -- Regex to detect the start of the next task
      break -- Stop searching if the next task is encountered before finding the end of a YAML block
    end
  end

  if yml_start and yml_end then
    -- YAML exists, update start time
    local updated = false
    for i = yml_start + 1, yml_end - 1 do
      if lines[i]:match('^time:') then
        table.insert(lines, i + 1, '- [' .. current_time_str() .. ']')
        updated = true
        break
      end
    end
    if updated then
      vim.api.nvim_buf_set_lines(bufnr, yml_start, yml_end + 1, false, lines)
    end
  else
    -- YAML doesn't exist, insert it at the correct position
    local metadata = {
      '',
      '```yml',
      'due: ',
      'time:',
      '- [' .. current_time_str() .. ']',
      'total: ',
      '```',
    }
    -- Find the correct insertion point, which is after the current task or any following empty lines
    local insert_point = task_row + 1 -- Default to inserting after the current task line
    vim.api.nvim_buf_set_lines(bufnr, insert_point, insert_point, false, metadata)
  end
end

local function resume_task()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1

  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  if not line or not line:match('%[|%]') then
    vim.notify('Task is not paused.')
    return
  end

  local updated_line = line:gsub('%[|%]', '[>]')
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { updated_line })
  local start_line, end_line = find_yaml_block(bufnr, row)
  if not start_line or not end_line then
    vim.notify('YAML block not found')
    return
  end

  local start_time = os.date('%H:%M')
  local new_entry = '- [' .. start_time .. ']'
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  table.insert(lines, #lines, new_entry) -- Insert before the last line (`:END:`)
  vim.api.nvim_buf_set_lines(
    bufnr,
    start_line,
    end_line,
    false,
    lines
  )
end

vim.api.nvim_create_user_command('GtdStartTask', start_task, {
  bang = false,
  bar = false,
  nargs = 0,
})

vim.api.nvim_create_user_command('GtdPauseTask', pause_task, {
  bang = false,
  bar = false,
  nargs = 0,
})

vim.api.nvim_create_user_command('GtdResumeTask', resume_task, {
  bang = false,
  bar = false,
  nargs = 0,
})

vim.api.nvim_create_user_command('GtdFinishTask', finish_task, {
  bang = false,
  bar = false,
  nargs = 0,
})

-- start_task()
-- pause_task()
-- resume_task()
-- finish_task()
--[[
[x] sample task1
```yml
due:
time:
- [09:47, 10:01]
- [10:11, 10:11]
total: 14 mins
```
[ ] sample task
[] sample task


]]
--
return {
  start_task = start_task,
  pause_task = pause_task,
  resume_task = resume_task,
  finish_task = finish_task,
}
