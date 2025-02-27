local M = {}

-- function M.copy_file(old, new)
--    local fd_old = io.open(old, 'rb')
--    local size_old, size_new
--    if not fd_old then
--       return false
--    end
--    local fd_new = io.open(new, 'wb')
--    if not fd_new then
--       return false
--    end
--    while true do
--       local block = fd_old:read(2^13)
--       if not block then
--          size_old = fd_old:seek('end')
--          break
--       end
--       fd_new:write(block)
--    end
--    fd_old:close()
--    size_new = fd_new:seek('end')
--    fd_new:close()
--    return size_new == size_old
-- end


M.sleep = function(s)
   local time = os.time() + s
   repeat until os.time() > time
end


local function getOS()
   if package.config:sub(1, 1) == '\\' then
      return 'Windows'
   else
      return io.popen('uname -s', 'r'):read()
   end
end

local function dos_fn(file)
   return file:gsub('/', '\\')
end


if getOS() == 'Windows' then
   M.copy_file = function(old, new)
      os.execute(string.format('copy %s %s > null', dos_fn(old), dos_fn(new)))
   end
   M.remove_file = function(file)
      os.remove(dos_fn(file))
   end
else
   M.copy_file = function(old, new)
      os.execute(string.format('cp -p %s %s', old, new))
   end
   M.remove_file = function(file)
      os.remove(file)
   end
end


return M
