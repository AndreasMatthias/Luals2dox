---@class ClassE
local ClassE = {}


---Constructor
---@return nil
function ClassE:new()
   local t = {}
   setmetatable(t, self)
   self.__index = self
   ---This is a class variable.
   ---LuaLS cannot distinguish class variables form object variables.
   self.class_variable = 123
   ClassE.init(t)
   return t
end


---Initializer
---@return nil
function ClassE:init()
   self.__index = self
   ---This is an object variable.
   ---LuaLS cannot distinguish class variables form object variables.
   self.object_variable = 456
end
