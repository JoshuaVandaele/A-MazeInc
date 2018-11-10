--===============================
--==    Made By Folfy Blue     ==
--===============================

--===============================
--==        INITALIZING        ==
--===============================
local config = dofile("config.ini")
local sprites = require(config.sprites)
config.mazeDir = tostring(arg[0]:gsub("\\","/"):match("(.*/)")):gsub("nil","")..config.mazeDir
config.scoresDir = tostring(arg[0]:gsub("\\","/"):match("(.*/)")):gsub("nil","")..config.scoresDir
local strings = dofile("langs/"..config.lang..".lang")
_G.Vers = "1.3a"

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

local funfact = strings.funfacts

local debug = false
if debug then config.resizeCMD = false end
--===============================
--==         FUNCTIONS         ==
--===============================

local function strReplace(str,...)
  local replacements = {...}
  for i = 1,#replacements do
    str = str:gsub("%%"..i,replacements[i])
  end
  return str
end

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
  print(strings.error..text)     --EASY TO READ ERROR MESSAGE FOR USERS
  os.exit()
end

function os.getOS()
  if package.config:sub(1, 1) == '\\' then                    
    return 'windows'
  elseif  package.config:sub(1, 1) == '/' then                     --GET THE OS
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
      local c = map:sub(i,i) --TRANSFORMS THE STRING OF THE MAP INTO A 2D ARRAY
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
    if not os.execute("clear") then                              --CLEAR SCREEN
      for i = 1, 255 do
          print()
      end
    end
  end
end

local function CheckMap(map)
  local _, teleport = map:gsub(sprites.teleport,"")
  if map == "" or not map:find(sprites.wall) and not map:find(sprites.inv_wall) then
    error(strings.mapError.walls)
  elseif not map:find(sprites.goal) then
    error(strings.mapError.goal)
  elseif not map:find(sprites.ground) then                 --CHECKS MAP CONTENT
    error(strings.mapError.ground)
  elseif not map:find(sprites.character) then
    error(strings.mapError.character)
  elseif teleport ~= 0 and teleport ~= 2 then
    error(strings.mapError.teleport)
  end
end

local function Lines(text)
  local function next_line(state)
    local text, begin, line_n = state[1], state[2], state[3]
    if begin < 0 then
      return nil
    end
    state[3] = line_n + 1
    local b, e = text:find("\n", begin, true)        --TO ITERATE THROUGH LINES
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
  map = config.scoresDir.."/"..map
  if debug then
    print("Saving high scores to "..map..config.scoresExt)
  end
  local scores = io.open(map..config.scoresExt,"r+")
  if not scores then
    scores = io.open(map..config.scoresExt,"w")
    scores:write("{{[\"m\"] = "..moves..", [\"n\"] = \'"..name.."\',[\"t\"] = "..timer.."}}")
    scores:close()
    return
  end
  local Hscores = scores:read("*a")
  scores:close()
  local Hscores = load("return "..Hscores)()
  table.insert(Hscores, {["m"] = moves, ["n"] = name,["t"] = timer})
  local Hscores = table_to_string(Hscores)                  --SAVES HIGH SCORES
  if debug then print(Hscores) end
  local scores = io.open(map..config.scoresExt,"w+")
  scores:write(Hscores)
  scores:close()
end

local function showScores(map)
  map = config.scoresDir.."/"..map
  local scores = io.open(map..config.scoresExt,"r")
  if not scores then error("An error occured while opening the scores! Do the scores exist?") end
  local highScores = scores:read("*a") 
  scores:close()
  highScores = load("return "..highScores)()
  table.sort(highScores, function(a,b)             --COMPLEMENT TO WIN FUNCTION
     return a.m < b.m or a.m == b.m and a.t > b.t
  end)
  local x = ""
  for k,v in pairs(highScores) do
    local mark = math.random(1,2)
    if mark == 1 then mark = ".\n" else mark = "!\n" end
    x = x..strReplace(strings.highscores,v.n,v.t,v.m)..mark
  end
  return x
end

local function resizeCMD(lines,cols)
  if not config.resizeCMD then return end
  if os.getOS() == "windows" then                     --RESIZE CMD TO MAZE SIZE
    os.execute("mode con: cols="..(cols+2).." lines="..(lines+1))      
  else
    os.execute("printf '\\e[8;"..(lines+1)..";"..(cols+1).."t'")
  end
end

local function win(moves,timer, map)
  timer = os.time() - timer
  resizeCMD(50,80)
  clear()
  print(strings.username)
  local name = io.read()                              --DISPLAYS HIGH SCORES AT 
  clear()
  io.write("\n\n" .. sprites.win_msg .. "\n\n")
  print()
  saveScores(name,moves,timer,map)
  print(showScores(map))
  os.exit()
end

local function loose()
  resizeCMD(50,80)
  clear()
  io.write("\n\n" .. sprites.loose_msg .. "\n\n")                         --RIP
  print()
  os.exit()
end

local function move(k,x,y)
  local Do
  for _,types in pairs(controls) do
    for action,keys in pairs(types) do
      for _, key in pairs(keys) do
        if k == key then
          Do = action                        --CHECKS IF A DIRECTION WAS CHOSEN
        end
      end
    end
  end

  if Do == "up" then
    return x, y - 1 
  elseif Do == "left" then
    return x - 1, y
  elseif Do == "right" then                           --RETURNS NEW COORDINATES
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
  elseif map[y][x] == sprites.door then
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
    if pos.X == x and pos.Y == y then          --CHECK IF THE MOVES ARE AVAIBLE
      return false
    end
  end

  return true,Tx,Ty
end

local function update(oldX,oldY,x,y,map)
  map[oldY][oldX] = sprites.ground
  map[y][x] = sprites.character
end

if os.getOS() == "windows" then
  os.execute("title "..strReplace(strings.title,_G.Vers,firstToUpper(os.getOS())))
else
  os.execute([[set-title(){
  ORIG=$PS1
  TITLE="\e]2;$@\a"
  PS1=${ORIG}${TITLE}
  }]].."\nset-title \""..strReplace(strings.title,_G.Vers,firstToUpper(os.getOS())).."\"")
end

local function colorprint(x)
  local replacements = {
      ["character"] = "[96m[1m"..sprites.character.."[0m",
      ["wall"] = "[34m"..sprites.wall.."[0m",
      ["goal"] = "[33m"..sprites.goal.."[0m",
      ["spikes"] = "[90m"..sprites.spikes.."[0m",
      ["teleport"] = "[37m"..sprites.teleport.."[0m",
      ["ground"] = sprites.ground,
      ["door"] = "[32m"..sprites.door.."[0m",
      ["lever"] = "[95m"..sprites.lever.."[0m",
    }
  for k,v in pairs(replacements) do
    for spriteName, sprite in pairs(sprites) do
      if sprite == x and spriteName == k then
        io.write(v)
      end
    end
  end
end

local function checkDoor(map)
  local door = false
  for y,yt in pairs(map) do
    for _,x in pairs(yt) do 
      if x == sprites.lever then
        door = true
      end      
    end
  end
  if not door then
    for y,yt in pairs(map) do
      for xnt,x in pairs(yt) do 
        if x == sprites.door then
          map[y][xnt] = sprites.ground
        end      
      end
    end
  end
  return map
end

--===============================
--==            MAP            ==
--===============================
--[[
TODO:
Update sub-menu:
Update Linux compability

Other floors for the maps
V OR ^ depending on direction - Enemy that goes up/down only (Must change default spike sprite; suggestion: *)
> OR < depending on direction - Enemy that goes left/right only
X - Enemy that goes random directions
D - Wall that closes when you pass through it
F - Same as above but with an invisible wall
+ - Jumps over the wall in front of you IF POSSIBLE
° - Easter egg, if walked on does crap to the map
]]

local map, spawnX, spawnY, sizeX, sizeY, x, y
local teleport = {X1 = -1, X2 = -1, Y1 = -1, Y2 = -1}
local invis_wall = {}

::MENU::
clear()
print(strings.menu.maze)
if os.getOS() == "windows" then
  os.execute("dir /b \""..config.mazeDir.."\\*"..config.mazeExt.."\"")
else
  print(strings.menu.mazeLinux)
  os.execute("find "..config.mazeDir.." -iname \"*"..config.mazeExt.."\"")
end
print(strings.menu.random)
print()
print(strings.menu.more)
print(strings.menu.exit)

io.write("\n> ")
local mapStr = io.read():upper()

if mapStr:upper() == "M" then
  print(strings.menu.others)
  print(strings.menu.deleteAll)
  print(strings.menu.deleteSpec)
  print()
  print(strings.menu.update)
  print(strings.menu.updateDir)
  print(strings.menu.updateCheck)
  print()
  print(strings.menu.changelog)
  print(strings.menu.changelogCheck)
  print()
  print(strings.menu.scores)
  print(strings.menu.scoresTxt)
  print()
  print(strings.menu.Return)
  io.write("\n> ")
  mapStr = io.read():upper()
end

if mapStr == "R" then
  goto MENU
elseif mapStr == "U" then
  if os.execute("git --version") then
    if os.getOS() == "windows" then
      local cmd = [[@echo off
set D=%CD%
echo.move /Y "%CD%\REPLACE_ME_MAZEDIR" "%temp%/REPLACE_ME_MAZEDIR"> ../tmp.bat
echo.move /Y "%CD%\REPLACE_ME_SCOREDIR" "%temp%/REPLACE_ME_SCOREDIR"> ../tmp.bat
echo.rmdir /S %D%>> ../tmp.bat
echo.git clone https://github.com/FolfyBlue/A-MazeInc.git>> ../tmp.bat
echo.move /Y "%temp%\REPLACE_ME_MAZEDIR" A-MazeInc>> ../tmp.bat
echo.move /Y "%temp%\REPLACE_ME_SCOREDIR" A-MazeInc>> ../tmp.bat
echo.del tmp.bat>>../tmp.bat
cd ..
tmp.bat]];cmd = cmd:gsub("REPLACE_ME_MAZEDIR",config.mazeDir):gsub("REPLACE_ME_SCOREDIR",config.scoresDir)
      local f = io.open("update.bat","w+")
      f:write(cmd)
      f:close()
      os.execute("update.bat")
      os.execute("cmd /k lua A-MazeInc.lua")
      os.exit()
    else
      local cmd = [[
D=$PWD
echo mv -f "$D/REPLACE_ME_MAZEDIR" "/tmp"> ../tmp.sh
echo mv -f "$D/REPLACE_ME_SCOREDIR" "/tmp"> ../tmp.sh
echo rm -rf "$D">> ../tmp.sh
echo git clone https://github.com/FolfyBlue/A-MazeInc.git>> ../tmp.sh
echo mv -f "/tmp/REPLACE_ME_MAZEDIR" A-MazeInc>> ../tmp.sh
echo mv -f "/tmp/REPLACE_ME_SCOREDIR" A-MazeInc>> ../tmp.sh
echo rm tmp.sh>>../tmp.sh
cd ..
chmod +x tmp.sh
./tmp.sh]];cmd = cmd:gsub("REPLACE_ME_MAZEDIR",config.mazeDir):gsub("REPLACE_ME_SCOREDIR",config.scoresDir)
      local f = io.open("update.sh","w+")
      f:write(cmd)
      f:close()
      os.execute("chmod +x update.sh")
      os.execute("./update.sh")
      os.execute("chmod +x ../tmp.sh")
      os.exit()
    end
  else
    print(strings.menu.gitError)
  end
  mapStr = true
elseif mapStr == "UD" then
  if os.execute("git --version") then
    os.execute("git clone https://github.com/FolfyBlue/A-MazeInc.git A-MazeInc_LATEST")
  else
    print(strings.menu.gitError)
  end
  mapStr = true
elseif mapStr == "C" then
  f = io.open("changelog.cl","r")
  local changelog = f:read("*a")
  print(changelog)
  f:close()
elseif mapStr == "S" then
  print(strings.menu.scorewhich)
  print(showScores(io.read()))
  mapStr = true
  elseif mapStr == "ST" then
  print(strings.menu.scorewhichGet)
  local which = io.read()
  f = io.open(which..".txt","w")
  f:write(showScores(which))
  f:close()
  print(strReplace(strings.menu.scorewhichGot,which..".txt"))
  mapStr = true

elseif mapStr:upper() == "D" then
  local scoreList
  if os.getOS() == "windows" then
    scoreList = io.popen("dir /b \""..config.scoresDir.."\\*.scores"):read("*a")
  else
    scoreList = io.popen("find "..config.scoresDir.." -iname \"*.scores\""):read("*a")
  end
  scoreList = "{\""..scoreList:gsub("\n","\",\n\"").."\"}"
  scoreList = load("return "..scoreList)()
  
  for _,file in pairs(scoreList) do
    if os.getOS() == "windows" then
      file = config.scoresDir.."/"..file
    end
    os.remove(file)
  end
  mapStr = true
elseif mapStr:upper() == "DS" then
  print(strings.menu.deleteSpecWhich)
  local YourTimeHasBegun = io.read():gsub(config.scoresExt,""):gsub(".maze","")
  os.remove(config.scoresDir.."/"..YourTimeHasBegun..config.scoresExt)
  mapStr = true
elseif mapStr:lower() == "exit" or mapStr:lower() == "e" then
  os.exit()
end

if mapStr == true or mapStr == "" then
  print("Press ENTER to continue.")
  io.read()
  goto MENU
end

::START::

if mapStr:lower() == "random" then
  map = require("maze-generator")
else
  local mapStr = mapStr:gsub("%"..config.mazeDir,"")..config.mazeExt
  mapName = mapStr:match("(.+)%..+")
  print(strings.loading)
  print(funfact[math.random(#funfact)])
  local mapf = io.open(config.mazeDir.."/"..mapStr,"rb")
  if not mapf then error(strings.mapError.loading) end
  map = mapf:read("*a")                             --READING MAP FILE
  mapf:close()  
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
  error(strings.mapError.characters)
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

print(strings.loaded)
clear()
--===============================
--==         GAME LOOP         ==
--===============================
--[[TODO:
Resize in game loop
Resize if debug turned on
Show moves & time on the side 
Show #1 in moves and #1 in time on the High Score
A square around the map to see it (Example:
====
=#O=
=@ =
====

C - See controls & start screen
P - Pause (Maybe fuse with above suggestion?)
If in debug: F - Enable placing of elements, if enabled instead of moving it'll place an element on the selected direction

]]

print(strings.startInfo.controls)
for direction,keys in pairs(controls.move) do
  print(strReplace(strings.startInfo.move,direction):upper()..table.concat(keys, strings.startInfo.OR))
end
print()
for action,keys in pairs(controls.others) do
  print(strReplace(strings.startInfo.action,action):upper()..table.concat(keys, strings.startInfo.OR))
end

print(strReplace(strings.startInfo.objects,sprites.character,sprites.wall,sprites.spikes,sprites.teleport,sprites.goal,sprites.door,sprites.lever))

print(strings.startInfo.start)
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
  
  if x > sizeX or y > sizeY then error(strings.mapError.how) end                          --ERROR CATCHING

  map = checkDoor(map)

  for _,y in pairs(map) do
    for _,x in pairs(y) do 
      colorprint(x)                       --SHOWS MAP
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

print(strings.somehow)
io.read()