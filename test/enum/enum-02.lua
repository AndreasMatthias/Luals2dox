---@enum level1
---Description of enum level1.
local level1 = {
   low = 1, --Low level.
   high = 2, --High level.
}

---@enum (key) level2
---Description of enum level2.
local level2 = {
   low = 1, --Low level.
   high = 2, --High level.
}


---@param level level2
---@return level2
local function foo2(level)
   return level
end


---@param level level1
---@return level1
local function foo1(level)
   return level
end


foo1(level1.low)

foo2('low')
