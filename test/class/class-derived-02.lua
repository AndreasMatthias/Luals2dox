---@class SuperE
local SuperE = {}


---Constructor
---@return nil
function SuperE:new()
   local t = {}
   setmetatable(t, self)
   self.__index = self
   SuperE.init(t)
   return t
end


---Initializer
---@return nil
function SuperE:init()
   self.__index = self
   self.var_SuperE = 123
end


---Method of SuperE.
---@return nil
function SuperE:foo()
end


---@class DerivedF: SuperE
local DerivedF = {}


---Constructor
---@return nil
function DerivedF:new()
   setmetatable(self, SuperE:new())
   local t = {}
   setmetatable(t, self)
   self.__index = self
   DerivedF.init(t)
   return t
end


---Initializer
---@return nil
function DerivedF:init()
   self.__index = self
   self.var_DerivedF = 456
end


---Method of DerivedF
---@return nil
function DerivedF:bar()
end
