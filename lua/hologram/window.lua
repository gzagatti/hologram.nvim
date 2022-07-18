ffi = require 'ffi'

ffi.cdef[[
  int ioctl(int __fd, unsigned long int __request, ...);
  typedef struct winsize {
    unsigned short ws_row;
    unsigned short ws_col;
    unsigned short ws_xpixel;
    unsigned short ws_ypixel;
  };
]]

-- need a more robust way to get this number
local TIOCGWINSZ = 21523

-- TODO refresh sizes once window changes

local Window = {}
Window.__index = Window

function Window:new()
  local obj = setmetatable({}, self)
  obj:_get_size()
  return obj
end

function Window:_get_size()
  sz = ffi.new('struct winsize')
  ffi.C.ioctl(0, TIOCGWINSZ, sz)
  self._rows = sz.ws_row
  self._cols = sz.ws_col
  self._height = sz.ws_ypixel
  self._width = sz.ws_xpixel
  self._cell_height = math.floor(self._height / self._rows)
  self._cell_width = math.floor(self._width / self._cols)
end

function Window:rows()
  return self._rows
end

function Window:cols()
  return self._cols
end

function Window:height()
  return self._height
end

function Window:width()
  return self._width
end

function Window:cell_height()
  return self._cell_height
end

function Window:cell_width()
  return self._cell_width
end

return Window
