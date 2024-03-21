---@mainpage
---@author    Jane Doe
---@version   1.1.1
---@date      2024
---@copyright XXX
---
---This is an example of using Doxygen with luals2dox.


local cat = require('cat')
local tabbycat = require('tabbycat')
local dog = require('dog')
local retriever = require('retriever')

local myPets = {
   cat:new('Molly'),
   tabbycat:new('Lucy', 'brown'),
   dog:new('Rocky'),
   retriever:new('Charlie', 'golden')}

for _, pet in pairs(myPets) do
   pet:say()
   pet:walk()
end
