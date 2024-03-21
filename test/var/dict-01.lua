---@diagnostic disable:lowercase-global
---@file
---Dictionaries and tables.

---Dictionary: string -> integer.
---@type { [string]: integer }
dict1 = {}

---Dictionary: integer -> integer.
---@type { [integer]: integer }
dict2 = {}

---Dictionary: integer -> boolean.
---@type { [integer]: boolean }
dict3 = {}


---The `table` type is identical to the `dictionary` type.
---But the syntax to define `table` and `dictionary` in LuaLS
---is different. Nevertheless the JSON output is the same.


---Table: integer -> string
---@type table<integer, string>
tab1 = {}

---Table: integer -> boolean
---@type table<integer, boolean>
tab2 = {}
