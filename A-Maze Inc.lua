--===============================
--==    Made By Folfy Blue     ==
--===============================

--===============================
--==        INITALIZING        ==
--===============================
local config = dofile("config.ini")
local sprites = require(config.sprites)
config.mazeDir = tostring(arg[0]:gsub("\\","/"):match("(.*/)")):gsub("nil","")..config.mazeDir

local movesCtrls = {
}

local controls = {
  ["move"] = {
    ["up"] = {"z", "w"},
    ["left"] = {"q", "a"},
    ["right"] = {"d"},
    ["down"] = {"s"},
  },

  ["others"] = {
    ["debug"] = {"0"},
    ["exit"] = {"e"},
    ["restart"] = {"r"},
  },
}

local funfact = {
  "Did you know this was originally an old project? Everything got rewrote, except for the sprites.",
  "I decided to remake this maze because I was bored in class. Yup, that was why.",
  "I streamed the developement of this on my twitch channel. Promotion time! https://www.twitch.tv/folfy_blue",
}

local debug = false
if debug then config.resizeCMD = false end
--===============================
--==         FUNCTIONS         ==
--===============================

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- Check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end

        -- Check the value type
        if type(v) == "table" then
            result = result..table_to_string(v)
        elseif type(v) == "boolean" then
            result = result..tostring(v)
        else
            result = result.."\""..v.."\""
        end
        result = result..","
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len()-1)
    end
    return result.."}"
end

function error(text)
  print("AN ERROR OCCURED:\n"..text)      --EASY TO READ ERROR MESSAGE FOR USERS
  os.exit()
end

function os.getOS()
  if package.config:sub(1, 1) == '\\' then                    
    return 'windows'
  elseif  package.config:sub(1, 1) == '/' then                --GET THE OS
    return 'unix'
  else
    return 'unknown'
  end
end

function mapToTbl(map)
  maptbl = {}
  line = {}
  table.insert(maptbl, line)
  for i = 1, #map do
      local c = map:sub(i,i)                                  --TRANSFORMS THE STRING OF THE MAP INTO A 2D ARRAY
      if c == "\n" then
          line = {}
          table.insert(maptbl, line)
      else
          table.insert(line, c)
      end
  end
  return maptbl
end

local function clear()
  if not os.execute("cls") then
    if not os.execute("clear") then                           --CLEAR SCREEN
      for i = 1, 255 do
          print()
      end
    end
  end
end

local function CheckMap(map)
  local _, teleport = map:gsub(sprites.teleport,"")
  if map == "" or not map:find(sprites.wall) and not map:find(sprites.inv_wall) then
    error("You probably need a map to play right? With walls and stuff.")
  elseif not map:find(sprites.goal) then
    error("Hey! what's your goal?")
  elseif not map:find(sprites.ground) then                                  --CHECKS MAP CONTENT
    error("Where will you walk? Certainly not on the non-existing ground.")
  elseif not map:find(sprites.character) then
    error("You can't play without a character, buddy. I tried once, it went badly.")
  elseif teleport ~= 0 and teleport ~= 2 then
    error("You can only have two teleporters max! It's just like shoes!")
  end
end

local function Lines(text)
  local function next_line(state)
    local text, begin, line_n = state[1], state[2], state[3]
    if begin < 0 then
      return nil
    end
    state[3] = line_n + 1
    local b, e = text:find("\n", begin, true)                   --TO ITERATE THROUGH LINES
    if b then
      state[2] = e+1
      return line_n, text:sub(begin, e-1)
    else
      state[2] = -1
      return line_n, text:sub(begin)
    end
  end
  local state = {text, 1, 1}
  return next_line, state
end

local function saveScores(name,moves,timer, map)
  map = config.mazeDir.."/"..map
  if debug then
    print("Saving high scores to "..map..".scores")
  end
  local scores = io.open(map..".scores","r+")
  if not scores then
    scores = io.open(map..".scores","w")
    scores:write("{{[\"m\"] = "..moves..", [\"n\"] = \'"..name.."\',[\"t\"] = "..timer.."}}")
    scores:close()
    return
  end
  local Hscores = scores:read("*a")
  scores:close()
  local Hscores = load("return "..Hscores)()
  table.insert(Hscores, {["m"] = moves, ["n"] = name,["t"] = timer})              --SAVES HIGH SCORES
  local Hscores = table_to_string(Hscores)
  if debug then print(Hscores) end
  local scores = io.open(map..".scores","w+")
  scores:write(Hscores)
  scores:close()
end

local function showScores(map)
  map = config.mazeDir.."/"..map
  local scores = io.open(map..".scores","r")
  local highScores = scores:read("*a") 
  scores:close()
  highScores = load("return "..highScores)()
  table.sort(highScores, function(a,b)                                          --COMPLEMENT TO WIN FUNCTION
     return a.m < b.m or a.m == b.m and a.t > b.t
  end)
  for k,v in pairs(highScores) do
    local mark = math.random(1,2)
    if mark == 1 then mark = "." else mark = "!" end
    print(v.n.." completed this maze in: "..v.t.." secs and "..v.m.." moves"..mark)
  end
end

local function resizeCMD(lines,cols)
  if not config.resizeCMD then return end
  if os.getOS() == "windows" then
    os.execute("mode con: cols="..(cols+2).." lines="..(lines+1))      --RESIZE CMD TO MAZE SIZE
  else
    os.execute("printf '\\e[8;"..(lines+1)..";"..(cols).."t'")
  end
end

local function win(moves,timer, map)
  timer = os.time() - timer
  resizeCMD(50,80)
  clear()
  print("ENTER YOUR USERNAME:")
  local name = io.read()                                --DISPLAYS HIGH SCORES AT 
  clear()
  io.write("\n\n" .. sprites.win_msg .. "\n\n")
  print()
  saveScores(name,moves,timer,map)
  showScores(map)
  os.exit()
end

local function loose()
  resizeCMD(50,80)
  clear()
  io.write("\n\n" .. sprites.loose_msg .. "\n\n")                       --RIP
  print()
  os.exit()
end

local function move(k,x,y)
  local Do
  for _,types in pairs(controls) do
    for action,keys in pairs(types) do
      for _, key in pairs(keys) do
        if k == key then
          Do = action                                      --CHECKS IF A DIRECTION WAS CHOSEN
        end
      end
    end
  end

  if Do == "up" then
    return x, y - 1 
  elseif Do == "left" then
    return x - 1, y
  elseif Do == "right" then                                 --RETURNS NEW COORDINATES
    return x + 1, y
  elseif Do == "down" then
    return x, y + 1
  elseif Do == "debug" then
    debug = not debug
  elseif Do == "restart" then
    return "restart"
  elseif Do == "exit" then
    os.exit()
  end

  return x,y
end

local function checkMove(x, y, map, sizeX, sizeY,teleport,invis_wall,timer,moves,mapN)
  local Tx, Ty
  if not map[y] or not map[y][x] then
    return false
  elseif map[y][x] == sprites.wall then
    return false
  elseif map[y][x] == sprites.goal then 
    win(moves,timer,mapN)
  elseif map[y][x] == sprites.spikes then
    loose()
  elseif map[y][x] == sprites.teleport then
    map[y][x] = sprites.ground
    if teleport.X1 and teleport.Y1 then
      Tx = teleport.X2
      Ty = teleport.Y2
    end
    if teleport.X2 and teleport.Y2 then
      Tx = teleport.X1
      Ty = teleport.Y1
    end
  end

  for _,pos in pairs(invis_wall) do
    if pos.X == x and pos.Y == y then                             --CHECK IF THE MOVES ARE AVAIBLE
      return false
    end
  end

  return true,Tx,Ty
end

local function update(oldX,oldY,x,y,map)
  map[oldY][oldX] = sprites.ground
  map[y][x] = sprites.character
end

--===============================
--==            MAP            ==
--===============================
--[[
TODO:
]]
local map, spawnX, spawnY, sizeX, sizeY, x, y
local teleport = {X1 = -1, X2 = -1, Y1 = -1, Y2 = -1}
local invis_wall = {}

print("What maze do you wanna play?")
if os.getOS() == "windows" then
  os.execute("dir /b \""..config.mazeDir.."\\*"..config.mazeExt.."\"")
else
  print("(Just write the file name, the directory isn't required.)")
  os.execute("find "..config.mazeDir.." -iname *"..config.mazeExt)
end
print("Random (Might not be possible to finish)")

local mapStr = io.read():gsub("%"..config.mazeDir,"")..config.mazeExt
local mapName = mapStr:match("(.+)%..+")

::START::

if not mapStr:lower() == "random" then
print("Loading the maze...")
print(funfact[math.random(#funfact)])
  local mapf = io.open(config.mazeDir.."/"..mapStr,"rb")
  if not mapf then error("Was the file name correctly spelled?") end
  map = mapf:read("*a")                             --READING MAP FILE
  mapf:close()
else
  map = dofile("maze-generator.lua")
end
map = map:gsub("%-%-(.-)\n","\n")                 --REMOVING COMMENTS

sizeX = map:match('(.-)\n')
map = map:gsub(sizeX.."\n","")
sizeY = map:match('(.-)\n')                        --GETTING X / Y (Info at the start)
map = map:gsub(sizeY.."\n","")
sizeY,sizeX = tonumber(sizeY),tonumber(sizeX)


for n,line in Lines(map) do
  if n > sizeY then break end
  line:sub(sizeX)                                 --VERYFYING MAP IS RIGHT SIZE
end

local _,errorchk = map:gsub(sprites.character, "")
if errorchk > 1 then
  error("There can be only one you.")
end

CheckMap(map)
map = mapToTbl(map)

local curY = 0

for _,y in pairs(map) do
  curY = curY+1                                   --ITERATING THROUGH THE Y
  local curX = 0
  for _, x in pairs(y) do
    curX = curX+1                                 --ITERATING THROUGH THE X
    if x == "@" then spawnX, spawnY = curX, curY end     --GETTING SPAWNPOINT
    if x == "0" then 
      if teleport.X1 == -1 then
        teleport.X1 = curX
        teleport.Y1 = curY
      else                                       --GETTING TELEPORTERS POS
        teleport.X2 = curX
        teleport.Y2 = curY
      end
    end
    if x == sprites.inv_wall then
      local pos = {
      ["X"] = curX, 
      ["Y"] = curY
    }
      table.insert(invis_wall,pos)
      map[curY][curX] = sprites.ground
    end
  end
end

print("Maze loaded! If you see this I hope you have a nice day.")
clear()
--===============================
--==         GAME LOOP         ==
--===============================

print("Controls:")
for direction,keys in pairs(controls.move) do
  print("To go "..direction..": "..table.concat(keys, " OR "):upper())
end
print()
for action,keys in pairs(controls.others) do
  print("To "..action..": "..table.concat(keys, " OR "):upper())
end


print("Your character is "..sprites.character.." and the walls are "..sprites.wall..". But beware, some walls are invisible or you could even ecounter spikes "..sprites.spikes.." !\nYou may sometimes encounter telepoters that look like this: "..sprites.teleport.." but we're low on energy, so you can only use them once. But the most important of all, your goal is "..sprites.goal.."!")

print("Press ENTER to start!")
io.read()

local timer = os.time()
local moves = 0

resizeCMD(sizeY,sizeX)

clear()

local x, y = spawnX, spawnY
local oldX, oldY, newX, newY = x, y, x, y
local teleported = false

while true do

  if debug then
    print("X = "..x.."   oldX = "..oldX.."   sizeX = "..sizeX.."   newX = "..newX.."   teleportX = "..tostring(teleportX).." teleport.X1,2 = "..teleport.X1..", "..teleport.X2)
    print("Y = "..y.."   oldY = "..oldY.."   sizeY = "..sizeY.."   newY = "..newY.."   teleportY = "..tostring(teleportY).." teleport.Y1,2 = "..teleport.Y1..", "..teleport.Y2)      -- FOR DEBUG
    print("moves = "..moves.." started at: "..timer.." ("..(os.time() - timer).."s)") 
  end
  
  if x > sizeX or y > sizeY then error("How'd you get over here anyways?") end                          --ERROR CATCHING
  
  for _,y in pairs(map) do
    for _,x in pairs(y) do 
      io.write(x)                       --SHOWS MAP
    end
    print()
  end
  
  local INPUT = io.read():lower():sub(1,1)
  moves = moves+1
  newX, newY = move(INPUT,x,y)           --TRIES TO MOVE
  if newX == "restart" then goto START end

  local canMove,teleportX,teleportY = checkMove(newX, newY ,map, sizeX, sizeY,teleport,invis_wall,timer,moves,mapName)

  if canMove then
    
    if newX >= sizeX then
      if map[y][1] == sprites.ground or (map[y][1] == sprites.ground and newX-1 == sprites.wall) then
        newX = 2
      else
        newX = newX-1
      end
    elseif newX <= 1 then
      if map[y][sizeX-1] == sprites.ground or (map[y][sizeX-1] == sprites.ground and newX+1 == sprites.wall) then
        newX = sizeX-1
      else
        newX = newX+1
      end
    end                                  --GOES TO THE OTHER SIDE OF THE MAP IF AT THE EXTREMITY OF IT
    if newY >= sizeY then
      if map[1][x] == sprites.ground or (map[1][x] == sprites.ground and newY-1 == sprites.wall) then
        newY = 2
      else
        newY = newY-1
      end
    elseif newY <= 1 then
      if map[sizeY-1][x] == sprites.ground or (map[sizeY-1][x] == sprites.ground and newY+1 == sprites.wall) then
        newY = sizeY-1
      else
        newY = newY+1
      end
    end
    
    oldX, oldY = x, y
    
      x = newX
      y = newY

    if teleportX ~= nil and not teleported then
      x = teleportX
      y = teleportY
      teleportX = nil
      teleportY = nil
      teleported = true
    end

    update(oldX,oldY,x,y,map)
  end
  clear()
end

print("You somehow got here. Press ENTER to continue.")
io.read()