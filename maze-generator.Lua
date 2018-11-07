local config = dofile("config.ini")
local sprites = require(config.sprites)
math.randomseed(os.time())
local maxX, maxY

function generate(maxX,maxY)
  local maze = {}
  for i = 1,maxY do
    table.insert(maze,{})
  end
  for _,Y in pairs(maze) do
    for i = 1,maxX do
      table.insert(Y,"EMPTY")
    end
  end

  local teleporters = 2

  maze[math.random(1,maxY)][math.random(1,maxX)] = sprites.character -- SPAWN
  do
    ::GOAL::
    local goalY = math.random(1,maxY)
    local goalX = math.random(1,maxX)
    if maze[goalY][goalX] == "EMPTY" then
      maze[goalY][goalX] = sprites.goal -- GOAL
    else
      goto GOAL
    end
  end

  print("Generating..")
  for Y = 1,maxY do

    for X = 1,maxX do

      if maze[Y][X] == "EMPTY" then

        local random = math.random(0,1200)

        if 300 > random and random < 800 then 
          random = sprites.wall 

        elseif random > 800 and random < 900 then
          random = sprites.inv_wall

        elseif random > 900 and random < 980 then
          random = sprites.spike

        elseif teleporters ~= 0 and random < 1000 and random > 980 then 
          teleporters = teleporters - 1
          random = sprites.teleport

        else
          random = sprites.ground

        end

        maze[Y][X] = random

      end

    end

  end
  print("Generated, converting to string..")
  local mapStr = ""

  for _,y in pairs(maze) do
    for _,x in pairs(y) do 
      mapStr = mapStr..x                       
    end
    mapStr = mapStr.."\n"     
  end

  return maxX.."\n"..maxY.."\n"..mapStr

end

print("What will be the maximum X of the maze? (Leave empty for random)")
local choice = tonumber(io.read())
if choice then
  maxX = choice
else
  maxX = math.random(1,60)
end

print("What will be the maximum Y of the maze? (Leave empty for random)")
choice = tonumber(io.read())
if choice then
  maxY = choice
else
  maxY = math.random(1,60)
end

print(""..maxX.."x"..maxY.." maze.")

map = generate(maxX,maxY)

print("/!\\ I HAVE NO IDEA HOW TO GENERATE MAZES, THIS WAS MADE BY PURE RANDOMNESS AND MIGHT NOT BE POSSIBLE, BLAME YOUR RANDOM SEED. /!\\")
return map