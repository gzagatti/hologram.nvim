local base64 = require('hologram.base64')
local uv = require'luv'

local terminal = {}
local stdout = vim.loop.new_tty(1, false)

--[[
     All Kitty graphics commands are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control keys> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--

local CTRL_KEYS = {
    -- General
    action = 'a',
    delete_action = 'd',
    quiet = 'q',

    -- Transmission
    format = 'f',
    transmission_type = 't',
    --data_width = 's',
    --data_height = 'v',
    data_size = 'S',
    data_offset = 'O',
    image_id = 'i',
    --image_number = 'I',
    compressed = 'o',
    more = 'm',

    -- Display
    placement_id = 'p',
    x_offset = 'x',
    y_offset = 'y',
    width = 'w',
    height = 'h',
    cell_x_offset = 'X',
    cell_y_offset = 'Y',
    cols = 'c',
    rows = 'r',
    cursor_movement = 'C',
    z_index = 'z',

    -- TODO: Animation
}

function terminal.send_graphics_command(keys, payload)
    local ctrl = ''
    for k, v in pairs(keys) do
        ctrl = ctrl..CTRL_KEYS[k]..'='..v..','
    end
    ctrl = ctrl:sub(0, -2) -- chop trailing comma
    -- print(ctrl)

    if payload then
        if keys.transmission_type ~= 'd' then
            payload = base64.encode(payload)
        end
        payload = terminal.get_chunked(payload)
        for i=1,#payload do
            -- print('i '..i..': '..ctrl..';'..payload[i])
            stdout:write('\x1b_G'..ctrl..';'..payload[i]..'\x1b\\')
            if i == #payload-1 then ctrl = 'm=0' else ctrl = 'm=1' end
        end
    else
        stdout:write('\x1b_G'..ctrl..'\x1b\\')
    end
end

-- Split into chunks of max 4096 length
function terminal.get_chunked(str)
    local chunks = {}
    for i = 1,#str,4096 do
        local chunk = str:sub(i, i + 4096 - 1):gsub('%s', '')
        if #chunk > 0 then
            table.insert(chunks, chunk)
        end
    end
    return chunks
end

function terminal.move_cursor(col, row)
    -- print('move cursor to '..row..':'..col)
    stdout:write('\x1b[s')
    stdout:write('\x1b['..row..':'..col..'H')
end

function terminal.restore_cursor()
    stdout:write('\x1b[u')
end

function terminal.send_window_command(keys)
  -- local ctrl = ''
  -- local output = ''
  -- local stdin = uv.new_tty(0, true)
  -- local stdout = uv.new_tty(1, false)
  -- print('stdin readable ', stdin:is_readable())
  -- stdin:write('foo')
  -- ct = 0
  -- stdout:write('\x1b[16t', function(err) 
  --   stdin:read_start(function(err, chunk)
  --     print(chunk)
  --     -- print('here from stdin')
  --     -- print('chunk ', chunk)
  --     stdout:write('\x1b[16t')
  --     ct = ct + 1
  --     if err then
  --       print('error')
  --     elseif chunk then
  --       output = chunk
  --     end
  --     if ct > 1 then
  --     print('closing')
  --     stdin:close()
  --     end
  --   end)
  -- end)
  ffi = require'ffi'
  ffi.cdef[[
  int ioctl(int __fd, unsigned long int __request, ...);
  typedef struct winsize {
    unsigned short ws_row;
    unsigned short ws_col;
    unsigned short ws_xpixel;
    unsigned short ws_ypixel;
  };
  ]]
  sz = ffi.new('struct winsize')
  ffi.C.ioctl(0, 21523, sz)
  print(sz.ws_ypixel / sz.ws_row)
end

return terminal
