local animal = require('animal')

---A cat.
--- @ingroup pets-class
---@class cat : animal
local cat = {}


---Constructor.
---@param name string # Name of cat.
---@return cat
function cat:new(name)
   local obj = animal:new(name)
   ---@protected
   self.parent = getmetatable(obj) -- Parent class.
   setmetatable(obj, self)
   setmetatable(self, self.parent)
   self.__index = self
   self.type = 'cat' -- Type of animal.
   self.init(obj)
   return obj --[[@as cat]]
end


---Initializer
---@return nil
function cat:init()
end


---Go for a walk.
---@return nil
function cat:walk()
   print("I'm not in the mood to go for a walk.")
end


return cat
