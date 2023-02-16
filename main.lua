------------------------ LOAD --------------------------------
function love.load()
love.window.setMode(1000, 768)

    anim8 = require ('libraries/anim8/anim8')  --animation
    sti = require ('libraries/Simple-Tiled-Implementation/sti') -- tile
    cameraFile = require ('libraries/hump/camera') -- camera file needed to create a camera object

    cam = cameraFile() -- create camera object

    sounds = {}
    sounds.jump = love.audio.newSource("audio/jump.wav", "static") -- static(special sounds) or stream (music)
    sounds.music = love.audio.newSource("audio/music.mp3", "stream")
    sounds.music:setLooping(true) -- this makes the music loop all the time
    sounds.music:setVolume(0.3)

    sounds.music:play()

    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')
    sprites.enemySheet = love.graphics.newImage('sprites/enemySheet.png')
    sprites.background = love.graphics.newImage('sprites/background.png')

    local grid = anim8.newGrid(614, 564, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight()) -- grid dimention can be calculated dividing width for columns, and height for rows
    local enemyGrid = anim8.newGrid(100, 79, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight()) -- arguments: width and height of each frame, and then width and height of the entire sprite sheet

    animations = {}
    animations.idle = anim8.newAnimation(grid('1-15', 1), 0.07) -- grid: first value columns, second row. then is defined the time between each image
    animations.jump = anim8.newAnimation(grid('1-7', 2), 0.07)
    animations.run = anim8.newAnimation(grid('1-15', 3), 0.07)
    animations.enemy = anim8.newAnimation(enemyGrid('1-2', 1), 0.05)

    wf = require('libraries/windfield/windfield')
    world = wf.newWorld(0,1000, false) --gravity x, y (in this case, down), also gravity sleep turned off
    world:setQueryDebugDrawing(true) --visually see the query that we make

    world:addCollisionClass('Platform') -- class created, now can be assigned in the collision creation
    world:addCollisionClass('Player'--[[, {ignores = {"Platform"}}]] ) -- this collision class ignores a table (platform)
    world:addCollisionClass('Danger')

    require ('player') -- adds load information from player.lua
    require ('enemy')
    require ('libraries/show') -- this libraries serialize and save data
    
    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, {collision_class = "Danger"})
    dangerZone:setType('static')

    platforms = {}

    flagX = 0 -- keeps track of flag location
    flagY = 0

    saveData = {} -- this table will save the data that we want, in this case we only want to save currentLevel
    saveData.currentLevel = "level1"
    
    if love.filesystem.getInfo("data.lua") then -- if there is saved data
        local data = love.filesystem.load("data.lua")
        data()
    end

    loadMap(saveData.currentLevel)-- here you use the name map

end


------------------------ UPDATE --------------------------------
function love.update(dt)
    gameMap:update(dt)
    world:update(dt)
    updatePlayer(dt) -- calls update functions in player.lua
    updateEnemies(dt)

    local px, py = player:getPosition() -- this keeps track of player position
    cam:lookAt(px, love.graphics.getHeight()/2) -- this makes the camera follows, vertically the camera is not moving (its centered)

    local colliders = world:queryCircleArea(flagX, flagY, 10, {'Player'})
    if #colliders > 0 then
        if saveData.currentLevel == "level1" then
        loadMap("level2")
        elseif saveData.currentLevel == "level2" then
            loadMap("level1")
        end
    end
end
------------------------ DRAW --------------------------------
function love.draw()
    love.graphics.draw(sprites.background, 0, 0)
    cam:attach() -- everything down the camera is drawn with it, that is why its indented
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"]) -- name of the map from tile program's layer
        --world:draw()
        drawPlayer() -- calls draw functions in player.lua
        drawEnemies()
    cam:detach()
    -- health bar for example, that its ditached
end

------------------------ OTHER FUNCTIONS --------------------------------
-- Player jumping
function love.keypressed(key)
    if key == 'up' or key == 'w' or key == 'space' then
        if player.grounded then -- if we find at least 1 platform class collider below the player, therebefore, jump
            player:applyLinearImpulse(0, -5000)
            sounds.jump:play()
        end
    end
end

-- Destroy all platforms and enemies when a map is loaded
function destroyAll()
    local i = #platforms
    while i > -1 do
        if platforms[i] ~= nil then
            platforms[i]:destroy()
        end
        table.remove(platforms, i)
        i = i - 1
    end

    local e = #enemies
    while e > -1 do
        if enemies[e] ~= nil then
            enemies[e]:destroy()
        end
        table.remove(enemies, e)
        e = e - 1
    end
end

-- Tile Map
function loadMap(mapName) -- works to use any level p.e using "level1"
    saveData.currentLevel = mapName -- update everytime to keep track of which level we are currently on
    love.filesystem.write("data.lua", table.show(saveData, "saveData" )) -- save data to our file data.lua, this is saved in App Data (not in proyect directory)
    destroyAll() -- call the function
    gameMap = sti("maps/" .. mapName .. ".lua")

    for i, obj in pairs(gameMap.layers["Start"].objects) do
        playerStartX = obj.x 
        playerStartY = obj.y
    end
    player:setPosition(playerStartX, playerStartY)

    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemy(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers["Flag"].objects) do
        flagX = obj.x 
        flagY = obj.y
    end
end

-- Spawning Platform
function spawnPlatform(x, y, width, height) -- function that creates an unique platform collider based on whatever parameter we provide
    if width > 0 and height > 0 then
        local platform = world:newRectangleCollider(x, y, width, height, {collision_class = "Platform"}) -- class asigned
        platform:setType('static') -- types: Dynamic (by default, affected by physics forces), Static and Kinematic
        table.insert(platforms, platform)
    end
end


