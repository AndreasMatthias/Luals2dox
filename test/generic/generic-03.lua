---@class ClassGen1
local ClassGen1 = {}


---Method (colon notation).
---@generic T1
---@generic T2
---@generic T3
---@param foo T1
---@param bar T2
---@param xox T3
function ClassGen1:method01(foo, bar, xox)
end


---Field function (dot notation).
---@generic T1
---@generic T2
---@generic T3
---@param foo T1
---@param bar T2
---@param xox T3
function ClassGen1.field_function01(foo, bar, xox)
end
