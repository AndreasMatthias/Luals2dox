---This is ClassB.
---@class ClassB
---@field private privateField integer This is a `private` field.
---@field protected protectedField integer This is a `protected` field.
---@field publicField integer This is a `public` field.

local ClassB = {}

ClassB.privateField = 123
ClassB.protectedField = 456
ClassB.publicField = 789

return ClassB
