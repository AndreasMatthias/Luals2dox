local dog = require('dog')

---A retriever.
--- @ingroup pets
---@class retriever : dog
local retriever = {}


---Constructor.
---@param name string # Name of retriever.
---@param color string # Color.
---@return retriever
function retriever:new(name, color)
   local obj = dog:new(name)
   ---@protected
   self.parent = getmetatable(obj) -- Parent class.
   setmetatable(obj, self)
   setmetatable(self, self.parent)
   self.__index = self
   self.type = 'retriever' -- Type of animal.
   self.init(obj, color)
   return obj --[[@as retriever]]
end


---@Initializer
---@param color string # Color.
---@return nil
function retriever:init(color)
   self.color = color -- Color of fur.
end


---Say something.
--- @warning This is a warning!
---@return nil
function retriever:say()
   print('Woof!')
   self.parent.say(self)
end


return retriever
