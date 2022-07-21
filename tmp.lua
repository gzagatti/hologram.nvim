reload 'hologram'

img = require'hologram'.add_image(0, '/home/gzagatti/src/hologram.nvim/tmp.png', 3, 1)

vim.fn.getwininfo(vim.api.nvim_get_current_win())                                       ssdfsdsd

require'hologram'.clear_images(1)

vim.fn.line('w0')
vim.fn.line('w$')


vim.api.nvim_get_current_buf()

stdout = vim.loop.new_tty(1, false)

stdout = vim.loop.new_tty(1, true)

stdin = vim.loop.new_tty(0, true)

stdin:read_start(function(err, chunk)
  if err then
    print('err')
  elseif chunk then
    print('chunk '..chunk)
  else
    print('else')
  end
  stdin:read_stop()
end)
stdout:write('i')

stdout:write('\x1b_G'..ctrl..'\x1b\\')

stdout:write('\x1b_G'..'a=d'..'\x1b\\')

stdout:write('\x1b_G'..'a=d,d=i,i=1'..'\x1b\\')

stdout:write('\x1b[s')
stdout:write('\x1b['..'6'..':'..'1'..'H')


















