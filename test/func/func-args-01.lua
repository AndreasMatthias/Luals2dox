---@diagnostic disable:lowercase-global
---@file
---Global functions.

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


---Function with one argument.
---@param aaa integer # This is an integer.
function func06(aaa)
end


---Function with two arguments.
---@param aaa integer # This is an integer.
---@param bbb string # This is a string.
function func07(aaa, bbb)
end


---Function with `...`.
---@param ... string # Several strings.
function func08(...)
end


---Optional argument.
---@param aaa? integer # optional
function func09(aaa)
end


---Union argument
---@param aaa integer | string
function func10(aaa)
end
