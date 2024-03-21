---@diagnostic disable:lowercase-global
---@file

---@class MyArray<T>: { [integer]: T }

---@class MyDictionary<T>: { [string]: T }


---Generic array.
---@param aaa MyArray<string> # Array of strings.
---@return nil
function gen01(aaa)
end

---Generic array.
---@param aaa MyArray<integer> # Array of integer.
---@return nil
function gen02(aaa)
end


---Generic dictionary.
---@param aaa MyDictionary<string> # Dictionary of strings.
---@return nil
function gen02(aaa)
end
