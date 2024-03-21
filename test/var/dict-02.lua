---@diagnostic disable:lowercase-global
---@file
---Same variable names as in `dict-01.lua`.

---Dictionary: string -> integer. (Another one with the same name.)
---@type { [string]: integer }
dict1 = {}

---Dictionary: integer -> integer. (Another one with the same name.)
---@type { [integer]: integer }
dict2 = {}

---Dictionary: integer -> boolean. (Another one with the same name.)
---@type { [integer]: boolean }
dict3 = {}


---The `table` type is identical to the `dictionary` type.
---But the syntax to define `table` and `dictionary` in LuaLS
---is different. Nevertheless the JSON output is the same.


---Table: integer -> string. (Another one with the same name.)
---@type table<integer, string>
tab1 = {}

---Table: integer -> boolean. (Another one with the same name.)
---@type table<integer, boolean>
tab2 = {}
