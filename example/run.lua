local animal = require('animal')
local cat = require('cat')
local tabbycat = require('tabbycat')
local retriever = require('retriever')


---@param pets animal[] # House gang.
---@return nil
local function who_are_you(pets)
   for _, pet in ipairs(pets) do
      pet:say()
   end
end


local fluffy = cat:new('Fluffy')
local lucy = tabbycat:new('Lucy', 'brown')
local dusty = retriever:new('Dusty', 'golden')
local my_pets = {fluffy, lucy, dusty}

who_are_you(my_pets)
