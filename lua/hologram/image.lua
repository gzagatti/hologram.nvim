local Job = require('hologram.job')
local base64 = require('hologram.base64')
local terminal = require('hologram.terminal')
local utils = require('hologram.utils')

local image = {}

local Image = {}
Image.__index = Image

-- source, row, col
function Image:new(opts)
    opts = opts or {}

    local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
    opts.row = opts.row or cur_row
    opts.col = opts.col or cur_col

    local buf = vim.api.nvim_get_current_buf()
    local ext = vim.api.nvim_buf_set_extmark(buf, vim.g.hologram_extmark_ns,
      opts.row-1, opts.col-1, {})

    local obj = setmetatable({
        id = ext,
        config = opts.config,
        source = opts.source,
        _buf = buf,
        _row = opts.row,
        _col = opts.col,
    }, self)

    obj:identify()

    return obj
end

function Image:buf()
  return self._buf
end

function Image:ext()
  return self.id
end

function Image:pos()
  return self._row, self._col
end

function Image:transmit(opts)
    opts = opts or {}
    opts.medium = opts.medium or 'f'
    local set_case = opts.hide and string.lower or string.upper
    local cellsize = {
        y = self.config.window_info.ypixels/self.config.window_info.rows,
        x = self.config.window_info.xpixels/self.config.window_info.cols,
    }
    self._buf = opts.buf or self._buf
    self._row = opts.row or self._row
    self._col = opts.col or self._col

    print(vim.inspect(self))

    local virt_lines = {}
    for i=1,math.ceil(178 / cellsize.y) do
      virt_lines[i] = { {''..i, 'LineNr' } }
      -- virt_lines[i] = { {'', 'Normal' } }
    end

    self._virt_lines = #virt_lines

    local ext = vim.api.nvim_buf_set_extmark(self._buf, vim.g.hologram_extmark_ns,
      self._row-1, self._col-1, { id=self.id, virt_lines=virt_lines })

    local keys = {
        image_id = self.id,
        transmission_type = opts.medium:sub(1, 1),
        format = opts.format or 100,
        placement_id = 1,
        action = set_case('t'),
        quiet = 2, --supress response
    }

    if not opts.hide then terminal.move_cursor(image.winpos(self.id)) end
    terminal.send_graphics_command(keys, self.source)
    if not opts.hide then terminal.restore_cursor() end

end

function Image:adjust(opts)
    opts = opts or {}
    opts = vim.tbl_extend('keep', opts, {
        z_index = 0,
        crop = {},
        area = {},
        edge = {},
        offset = {},
        placement_id = 1
    })

    local keys = {
        action = 'p',
        image_id = self.id,
        z_index = opts.z_index,
        width = opts.crop[1],
        height = opts.crop[2],
        cols = opts.area[1],
        rows = opts.area[2],
        x_offset = opts.edge[1],
        y_offset = opts.edge[2],
        cell_x_offset = opts.offset[1],
        cell_y_offset = opts.offset[2],
        placement_id = opts.placement_id,
        cursor_movement = 1,
        quiet = 2,
    }

    terminal.move_cursor(image.winpos(self.id))
    terminal.send_graphics_command(keys)
    terminal.restore_cursor()
end

function Image:delete(opts)
    opts = opts or {}
    opts.free = opts.free or false
    opts.all = opts.all or false

    local set_case = opts.free and string.upper or string.lower

    local keys = {}

    keys.action = 'd'

    if opts.all == false then
      keys.delete_action = set_case('i')
      keys.image_id = self.id
    end
    if opts.z_index then
        keys.delete_action = set_case('z')
        keys.z_index = opts.z_index
    end
    if opts.col then
        keys.delete_action = set_case('x')
        keys.x_offset = opts.col
    end
    if opts.row then
        keys.delete_action = set_case('y')
        keys.y_offset = opts.row
    end
    if opts.cell then
        keys.delete_action = set_case('p')
        keys.cell_x_offset = opts.cell[1]
        keys.cell_y_offset = opts.cell[2]
    end


    terminal.send_graphics_command(keys)

    if opts.free then
      vim.api.nvim_buf_del_extmark(0, vim.g.hologram_extmark_ns, self:ext())
    -- else
    --   vim.api.nvim_buf_set_extmark(self._buf, vim.g.hologram_extmark_ns,
    --     self._row, self._col, { id=self.id })
    end
end

function Image:identify()
    -- Get image width + height
    if vim.fn.executable('identify') == 1 then
        Job:new({
            cmd = 'identify',
            args = {'-format', '%hx%w', self.source},
            on_data = function(data)
                data = {data:match("(.+)x(.+)")}
                self.height = tonumber(data[1])
                self.width  = tonumber(data[2])
            end,
        }):start()
    else
        vim.api.nvim_err_writeln("Unable to run command 'identify'."..
            " Make sure ImageMagick is installed.")
    end
end

function Image:move(row, col)
    vim.api.nvim_buf_set_extmark(0, vim.g.hologram_extmark_ns, row, col, {
        id = self.id
    })
end

function image.bufpos(id, buf)
    if buf == nil then buf = 0 end
    local row, col = unpack(vim.api.nvim_buf_get_extmark_by_id(0,
        vim.g.hologram_extmark_ns, id, {}))
    -- nvim_buf_get_extmark_by_id returns a 0-index (row, col) tuple
    return col + 1, row + 1
end

function image.winpos(id, win)
    if win == nil then win = 0 end
    local wb = utils.winbounds(win)
    local col, row = image.bufpos(id)

    local virt = 1

    row = row - vim.fn.line('w0') + virt
    row = row + wb.top
    col = col + wb.left

    return col, row
end


return Image
