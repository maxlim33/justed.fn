describe('justed.fn', function()
  it('can be required', function()
    require('justed.fn')
  end)

  -- TODO:
  -- 1. After setup(), filename is shown at top right corner.
  -- 2. Vertical/horizontal splitting the screen with a new buffer will move first filename to new window size,
  -- and new window shows filename of new buffer as windows resize.
  -- 3. Closing a window will close its corresponding filename, and also move other filenames as windows resize vertically and horizontally.
  -- 4. When show_modifier = true, modify a buffer will show the modifier in the filename for every window showing the same buffer.
  -- 5. Open a help file will show the help text filename and a non-modifiable modifier in the filename.
  -- 6. Open a terminal buffer wll show 'zsh' as filename and a non-modifiable modifier in the filename.
  -- 7. Start Neovim with +terminal will show 'zsh' and non-modifiable modifier correctly.
  -- 8. Call toggle_fn() will remove all filenames and scratch buffers that contain the filenames.
  -- 9. Call toggle_fn() again will create the scratch buffers and display the filenames correctly.
end)
