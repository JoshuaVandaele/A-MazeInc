--===============================
--==       CUSTOMIZATION       ==
--===============================

local character = "@" -- Must be only one character
local wall = "#" -- Must be only one character
local goal = "O" -- Must be only one character
local spikes = "^" -- Must be only one character
local teleporter = "0" -- Must be only one character
local invisible_wall = "W" -- Must be only one character
local ground = " " -- Must be only one character
local door = "&" --must be only one character
local lever = "|" --must be only one character
local winning_message = "\n  __   __            _    _               _ \n  \\ \\ / /           | |  | |             |"..spikes.."|\n   \\ V /___  _   _  | |  | | ___  _ __   |"..wall.."|\n    \\ // _ \\| | | | | |/\\| |/ _ \\| '_ \\  |"..goal.."|\n    | | (_) | |_| | \\  /\\  / (_) | | | | |"..teleporter.."|\n    \\_/\\___/ \\__,_|  \\/  \\/ \\___/|_| |_| ("..character..")" -- as many crap as you want
local loose_message = [[                                                                     
 _|      _|                        _|                        _|      
   _|  _|    _|_|    _|    _|      _|    _|_|      _|_|_|  _|_|_|_|  
     _|    _|    _|  _|    _|      _|  _|    _|  _|_|        _|      
     _|    _|    _|  _|    _|      _|  _|    _|      _|_|    _|      
     _|      _|_|      _|_|_|      _|    _|_|    _|_|_|        _|_|]] -- as many crap as you want


local character = character:sub(1,1)
local wall = wall:sub(1,1)
local goal = goal:sub(1,1)
local spikes = spikes:sub(1,1)
local teleporter = teleporter:sub(1,1)
local invisible_wall = invisible_wall:sub(1,1)

return {
["character"] = character, 
["wall"] = wall, 
["goal"] = goal, 
["spikes"] = spikes,
["win_msg"] = winning_message,
["loose_msg"] = loose_message, 
["teleport"] = teleporter, 
["inv_wall"] = invisible_wall,
["ground"] = ground, 
["door"] = door,
["lever"] = lever,
}

--Ascii art credits: http://patorjk.com/software/taag/