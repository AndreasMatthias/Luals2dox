---@diagnostic disable:lowercase-global
---@file
---Global functions.


---@return nil
function func01()
end


---@return nil # comment
function func02()
end


---@return integer
function func03()
   return 123
end


---@return integer # comment
function func04()
   return 123
end


---@return integer, string # one comment for both
function func05()
   return 123, 'foo'
end


---@return integer # comment integer
---@return string # comment string
function func06()
   return 123, 'foo'
end


---@return integer | string
function func07()
   return 'foo'
end


---@return fun(cnt: integer): integer
function func08()
   return function(cnt)
      return 2 * cnt
   end
end
