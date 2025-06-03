local ShuffleBag = require("shufflebag")
local loops = require("loops")
local P = {};

P.solar_system = {}
local colors = {
    {1, 0.5, 0.4},  -- pink
    {1, 0.7, 0.4},  -- light orange
    {1, 0.9, 0.4},  -- light yellow
    {0.4, 1, 0.7},  -- greenish-blue
    {0.4, 1.7, 1},  -- light blue
    {0.5, 0.4, 1}   -- periwinkle
}
local colorBag = ShuffleBag.new(colors)
local loopBag = ShuffleBag.new(loops)

function P.generateSolarSystem(numPlanets, minRadius, maxRadius, maxAttempts)
    for i = 1, numPlanets do
        local placed = false
        local attempts = 0
    
        while not placed and attempts < maxAttempts do
            attempts = attempts + 1
    
            local angle = math.random() * 2 * math.pi
            local dist = math.random(100, 250)
            local x = width / 2 + math.cos(angle) * dist
            local y = height / 2 + math.sin(angle) * dist
    
            local tooClose = false
    
            for _, other in ipairs(P.solar_system) do
                local ox, oy = other.body:getPosition()
                local dx = x - ox
                local dy = y - oy
                local dSq = dx * dx + dy * dy
                if dSq < (maxRadius * 2)^2 then
                    tooClose = true
                    break
                end
            end
    
            if not tooClose then
                local planet = {}
                planet.alive = true
                planet.body = love.physics.newBody(world, x, y, "static")
                planet.shape = love.physics.newCircleShape(love.math.random(minRadius, maxRadius))
                planet.color = colorBag:next()
                planet.loop = loopBag:next()
                planet.fixture = love.physics.newFixture(planet.body, planet.shape)

                planet.bullets = {}
                planet.lastShot = love.timer.getTime()
    
                table.insert(P.solar_system, planet)
                planet.fixture:setUserData({ id="planet", index=#P.solar_system })
                placed = true
            end
        end
    
        if not placed then
            print("couldn't place planet " .. i .. " without overlap after " .. maxAttempts .. " attempts.")
        end
    end
end

function P.destroyPlanet(planet)
    if (love.timer.getTime() - planet.explosionTime) < 0.02 then
        love.graphics.setColor(1, 0.5, 0.1, 0.8)
        love.graphics.circle("fill", planet.body:getX(), planet.body:getY(), 5*planet.shape:getRadius())
    else
        -- Play loop
        if planet.alive and not planet.loop:isPlaying() then
            planet.loop:setVolume(0.7)
            planet.loop:setLooping(true)
            love.audio.play(planet.loop)
        end

        -- Safe to finalize destruction
        if planet.alive then
            print("planet " .. planet.fixture:getUserData().index .. " destroyed")
            planet.alive = false
            planet.body:destroy()
        end

        -- Remove from solar_system
        for i, p in ipairs(P.solar_system) do
            if p == planet then
                table.remove(P.solar_system, i)
                destroyedPlanets = destroyedPlanets + 1
                break
            end
        end
    end
end

function P.clearPlanets()
    for _, planet in ipairs(P.solar_system) do
        if planet.body and not planet.body:isDestroyed() then
            planet.body:destroy()
        end
    end
    P.solar_system = {}
end

function P.updateBullets(dt)
    for _, planet in ipairs(P.solar_system) do
        local now = love.timer.getTime()
        if now - planet.lastShot > 1.5 then  -- fire every 1.5 seconds
            planet.lastShot = now

            local px, py = planet.body:getPosition()
            local angle = math.random() * 2 * math.pi
            local speed = 200

            local bullet = {
                body = love.physics.newBody(world, px, py, "dynamic"),
                shape = love.physics.newCircleShape(3),
                ttl = 3  -- seconds to live
            }
            bullet.fixture = love.physics.newFixture(bullet.body, bullet.shape)
            bullet.body:setLinearVelocity(math.cos(angle) * speed, math.sin(angle) * speed)
            bullet.body:setUserData({ _destroy = false })
            bullet.fixture:setUserData({ id = "bullet" })

            table.insert(planet.bullets, bullet)
        end

        -- Update + remove dead bullets
        for i = #planet.bullets, 1, -1 do
            local b = planet.bullets[i]
            b.ttl = b.ttl - dt
            local data = b.body:getUserData()
            local shouldDestroy = (b.ttl <= 0) or (data and data._destroy)

            if shouldDestroy then
                if not b.body:isDestroyed() then
                    b.body:destroy()
                end
                table.remove(planet.bullets, i)
            end
        end


    end
end

function P.drawBullets()
    love.graphics.setColor(1, 1, 0.5)
    for _, planet in ipairs(P.solar_system) do
        for _, b in ipairs(planet.bullets) do
            local x, y = b.body:getPosition()
            love.graphics.circle("fill", x, y, b.shape:getRadius())
        end
    end
end



return P