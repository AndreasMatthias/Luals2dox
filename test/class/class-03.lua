---@class ClassD
---@field myInt integer This is an integer.
---@field myArrInt [integer] This is an array of integers.
---@field myFunTable [integer, string, boolean] Nice type! Definitely not C++!
local ClassD = {}

ClassD.myInt = 123
ClassD.myArrInt = {1, 2, 3}
ClassD.myFunTable = {212, 'fdsa', true}

return ClassD
