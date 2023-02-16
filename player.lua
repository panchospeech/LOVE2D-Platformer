playerStartX = 0
playerStartY = 0


player = world:newRectangleCollider(playerStartX, playerStartY, 40, 100, {collision_class = "Player"}) -- collider or physic object (body, fixture and shape) in player variable
player:setFixedRotation(true)
player.speed = 240 -- collider is a specific type of table, so there is no need to declare player = {}
player.animation = animations.idle -- set the animations to the player
player.isMoving = false
player.direction = 1
player.grounded = true

function updatePlayer(dt)
 --Player movement
    if player.body then --checks if the player object, the body exists
        -- query collider, to prevent jump in mid air
        local colliders = world:queryRectangleArea(player:getX() - 20, player:getY() + 50, 40, 2, {'Platform'}) -- find a list of platform class collider
        if #colliders > 0 then
            player.grounded = true
        else 
            player.grounded = false
        end

        player.isMoving = false
        local px, py = player:getPosition ()
        if love.keyboard.isDown('right', 'd') then
            player:setX(px + player.speed*dt)    
            player.isMoving = true
            player.direction = 1
        end
        if love.keyboard.isDown('left', 'a') then
            player:setX(px - player.speed*dt)
            player.isMoving = true
            player.direction = -1
        end
    
-- Danger / Player Collision
        if player:enter('Danger') then -- when the player gets to danger collide then
            player:setPosition(playerStartX, playerStartY)-- eliminate the object
        end
    end
    
    if player.grounded then
        if player.isMoving then --  player.isMoving == true
            player.animation = animations.run
        else
            player.animation = animations.idle
        end
    else
        player.animation = animations.jump 
    end
-- Player animation
    player.animation:update(dt)
end

function drawPlayer()
    local px, py = player:getPosition()
    player.animation:draw(sprites.playerSheet, px, py, nil, 0.25 * player.direction, 0.25, 130, 300) -- colliders are like circles, their position is at its center, we need offset
    -- direction can be fixed when we scale images in negatives values, they flip.
end