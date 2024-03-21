local animal = require('animal')

---A dog.
--- @ingroup pets-class
---@class dog : animal
local dog = {}


---Constructor.
---@param name string # Name of dog.
---@return dog
function dog:new(name)
   local obj = animal:new(name)
   ---@protected
   self.parent = getmetatable(obj) -- Parent class.
   setmetatable(obj, self)
   setmetatable(self, self.parent)
   self.__index = self
   self.type = 'dog' -- Type of animal.
   self.init(obj)
   return obj --[[@as dog]]
end


---Initializer
---@return nil
function dog:init()
end


---Go for a walk.
---@return nil
function dog:walk()
   print('I love going for a walk. Let\'s go!')
end


return dog
