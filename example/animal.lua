---@defgroup pets Pets
---Summary of all pets.

---@defgroup pets-class Classification
---Classification of pets.

---An animal.
---@class animal
local animal = {}

---Constructor
---@param name string # Name of animal.
---@return animal
function animal:new(name)
   local obj = {}
   setmetatable(obj, self)
   self.__index = self
   self.type = 'animal' -- Type of animal.
   self.init(obj, name)
   return obj
end


---Initializer
---@private
---@param name string # Name of animal.
---@return nil
function animal:init(name)
   self.name = name -- Name of animal.
end


---Introduce yourself.
---@return nil
function animal:say()
   print(string.format('My name is %s. I\'m a %s.', self.name, self.type))
end


---@deprecated
---Deprecated: Use aninal:say() instead..
---
---Say hello.
---@return nil
function animal:hello()
   self:say()
end

return animal
