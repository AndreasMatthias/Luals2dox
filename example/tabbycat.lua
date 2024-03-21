local cat = require('cat')

--- A tabbycat
--- @ingroup pets
---@class tabbycat : cat
local tabbycat = {}

---Constructor.
---@param name string # Name.
---@param color string # Color.
---@return tabbycat
function tabbycat:new(name, color)
   local obj = cat:new(name)
   ---@protected
   self.parent = getmetatable(obj) -- Parent class.
   setmetatable(obj, self)
   setmetatable(self, self.parent)
   self.__index = self
   self.type = 'tabby cat' -- Type of animal.
   self.init(obj, color)
   return obj --[[@as tabbycat]]
end

---Initializer.
---@param color string # Color.
---@return nil
function tabbycat:init(color)
   self.color = color -- Color of fur.
end

---Say something.
--- @bug Let's say this is a bug ...
---@return nil
function tabbycat:say()
   print('Meow!')
   self.parent.say(self)
end

return tabbycat
