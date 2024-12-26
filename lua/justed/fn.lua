local JustedFn = {}
local _H = {}

JustedFn.setup = function(config)
  vim.validate({ config = { config, 'table', true } })
  config = vim.tbl_deep_extend('force', vim.deepcopy(JustedFn.config), config or {})

  vim.validate({ show_modifier = { config.show_modifier, 'boolean' } })
  JustedFn.config = config
  _H.apply_config(config)
  _H.create_autocommands()
  JustedFn.toggle_fn()
end

-- Default values:
JustedFn.config = {
  show_modifier = true,
}

_H.fn_on = false
_H.fn_modifier_on = nil
_H.fn_wins = {}

_H.apply_config = function(config)
  _H.fn_modifier_on = config.show_modifier
end

_H.show_fn = function(win_id)
  local buf_id = vim.api.nvim_win_get_buf(win_id)
  local fn_path = vim.api.nvim_buf_get_name(buf_id)
  local fn = vim.fn.fnamemodify(fn_path, ':t')
  if fn == '' then fn = '[No Name]' end

  if _H.fn_modifier_on then
    local modifier
    local is_modified = vim.api.nvim_get_option_value("modified", { buf = buf_id })
    local is_modifiable = vim.api.nvim_get_option_value("modifiable", { buf = buf_id })
    if is_modified then
      modifier = '[+]'
    elseif not is_modifiable then
      modifier = '[-]'
    end
    if modifier then fn = modifier .. ' ' .. fn end
  end

  fn = '  ' .. fn .. '  '

  local fn_win = _H.fn_wins[win_id]
  if fn_win then
    local fn_buf = vim.api.nvim_win_get_buf(fn_win)
    vim.api.nvim_buf_set_lines(fn_buf, 0, -1, false, { fn })

    vim.api.nvim_win_set_config(fn_win, {
      relative = 'win',
      win = win_id,
      width = #fn,
      height = 1,
      row = 0,
      col = vim.api.nvim_win_get_width(win_id) - #fn,
      style = 'minimal',
    })
  else
    local fn_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(fn_buf, 0, -1, false, { fn })

    _H.fn_wins[win_id] = vim.api.nvim_open_win(fn_buf, false, {
      relative = 'win',
      win = win_id,
      width = #fn,
      height = 1,
      row = 0,
      col = vim.api.nvim_win_get_width(win_id) - #fn,
      style = 'minimal',
    })
  end
end

_H.is_float = function(win_id)
  -- Floating windows have a non-empty `relative` field
  return vim.api.nvim_win_get_config(win_id).relative ~= ''
end

_H.get_non_float_wins = function()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local wins = vim.api.nvim_tabpage_list_wins(current_tab)

  local non_float_wins = {}
  for _, win_id in ipairs(wins) do
    if not _H.is_float(win_id) then
      non_float_wins[win_id] = true
    end
  end

  return non_float_wins
end

_H.create_autocommands = function()
  local augroup = vim.api.nvim_create_augroup('JustedFn', { clear = true })


  vim.api.nvim_create_autocmd({ 'WinResized' }, {
    desc = 'Show filename at window top right corner for all windows',
    group = augroup,
    pattern = '*',
    callback = function(event)
      if not _H.fn_on then return end

      if _H.is_float(tonumber(event.file)) then return end

      local non_float_wins = _H.get_non_float_wins()
      -- Close associated filename window for closed window
      for win_id, _ in pairs(_H.fn_wins) do
        if not non_float_wins[win_id] then
          local buf_id = vim.api.nvim_win_get_buf(_H.fn_wins[win_id])
          vim.api.nvim_buf_delete(buf_id, { force = true })
          _H.fn_wins[win_id] = nil
        end
      end

      for win_id, _ in pairs(non_float_wins) do
        _H.show_fn(win_id)
      end
    end,
  })

  -- BufWinEnter is required when reading another buffer in current window
  -- TermOpen is required when terminal mode is opened with :startinsert
  -- Other events are triggered as well, but they do not cover all situations:
  -- 1. BufWinEnter doesn't capture term buffer at all
  -- 2. VimEnter only works on startup
  -- 3. BufModifiedSet only works without :startinsert
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'TermOpen' }, {
    desc = 'Show filename at window top right corner for current window',
    group = augroup,
    pattern = '*',
    callback = function(event)
      if not _H.fn_on then return end

      local win_id = vim.api.nvim_get_current_win()
      if _H.is_float(win_id) then return end

      _H.show_fn(win_id)
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufModifiedSet' }, {
    desc = 'Update modifier for windows showing the same filename',
    group = augroup,
    pattern = '*',
    callback = function(event)
      if not _H.fn_on then return end

      local wins = vim.fn.win_findbuf(event.buf)
      for _, win_id in ipairs(wins) do
        if _H.is_float(win_id) then return end

        _H.show_fn(win_id)
      end
    end,
  })
end

JustedFn.toggle_fn = function()
  _H.fn_on = not _H.fn_on

  local non_float_wins = _H.get_non_float_wins()
  for win_id, _ in pairs(non_float_wins) do
    if _H.fn_on then
      _H.show_fn(win_id)
    else
      -- In case if any of the filename windows are closed by other ways.
      if vim.api.nvim_win_is_valid(_H.fn_wins[win_id]) then
        local buf_id = vim.api.nvim_win_get_buf(_H.fn_wins[win_id])
        vim.api.nvim_buf_delete(buf_id, { force = true })
      end
      _H.fn_wins[win_id] = nil
    end
  end
end

return JustedFn
