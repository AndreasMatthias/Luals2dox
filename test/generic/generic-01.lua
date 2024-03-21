---@diagnostic disable:lowercase-global
---@file

---@generic T
---@param foo T # generic T
---@param x integer
---@return T # generic T
function gen01(foo, x)
   return foo
end


---@generic T
---@param foo T[] # generic array
---@return T[] # generic array
function gen02(foo)
   return foo
end


---@generic T : number
---@param foo T
---@return T
function gen03(foo)
   return foo
end


---@generic T1
---@generic T2
---@generic T3
---@param foo T1
---@param bar T2
---@param xox T3
function gen04(foo, bar, xox)
end
