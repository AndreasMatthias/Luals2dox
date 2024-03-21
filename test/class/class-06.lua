---@class Foo
---@field var1 integer JSON `doc.field`.
---@field var3 table fdsafdsa.
local Foo = {}

---Variable with `@field` annotation. (JSON: `doc.field`)
Foo.var1 = 123

---Variable without annotation. (JSON: `setfield`)
Foo.var2 = 123

---Variable with `@field` annotation. (JSON: `doc.field`)
Foo.var3 = {}

---Variable without annotation. (JSON: `setfield`)
Foo.var4 = {}

---Method. (JSON: `setmethod`)
function Foo:method()
end

---Class function. (JSON: `setfield`)
function Foo.func()
end
