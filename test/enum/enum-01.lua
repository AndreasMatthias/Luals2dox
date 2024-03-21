---@diagnostic disable:lowercase-global
---@file

---@enum level
---Description of enum `level`.
level = {
   low = 1, --Low level.
   medium = 2, --Medium level.
   high = 3, --High level.
   ['this-is a funny.name'] = 4, --What's this.
}

---@param lev level
---@return level
function fill(lev)
   print(lev)
   return lev
end

fill(level.high)


---@enum (key) suit
---Description of enum `suit`.
suit = {
   clubs = 1, --It's clubs.
   diamonds = 2, --It's diamonds.
   hearts = 3, --It's hearts.
   spades = 4, --It's spades.
   ['this-is a funny.name'] = 5, --What's this.
}

---@param s suit
---@return suit
function play(s)
   print(s)
   return s
end

play('clubs')
