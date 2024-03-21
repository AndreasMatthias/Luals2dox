---@diagnostic disable:lowercase-global
---@file
---Same function names as in `func-args-01.lua`.

function func01()
end


---@param aaa integer
function func02(aaa)
end


---@param aaa integer
---@param bbb string
function func03(aaa, bbb)
   end


---@param ... string
function func04(...)
end


---@param aaa? integer # optional
function func05(aaa)
end


---Function with one argument. Same function name as in `func-args-01.lua`.
---@param aaa integer # This is an integer.
function func06(aaa)
end


---Function with two arguments. Same function name as in `func-args-01.lua`.
---@param aaa integer # This is an integer.
---@param bbb string # This is a string.
function func07(aaa, bbb)
end


---Function with `...`. Same function name as in `func-args-01.lua`.
---@param ... string # Several strings.
function func08(...)
end


---Optional argument. Same function name as in `func-args-01.lua`.
---@param aaa? integer # optional
function func09(aaa)
end
