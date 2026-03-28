-- src/enemies/enemy_factory.lua
-- Factory para crear enemigos

local Transform = require('src.ecs.components.transform')
local Health = require('src.ecs.components.health')
local ChaseBehavior = require('src.enemies.behaviors.chase_behavior')
local PatrolBehavior = require('src.enemies.behaviors.patrol_behavior')

local EnemyFactory = {}

function EnemyFactory:createBat(x, y)
    return {
        type = 'bat',
        transform = Transform:new(x, y),
        health = Health:new(20),
        speed = 110, -- Reducido de 120 pero > 100
        behavior = ChaseBehavior:new(250, 20), -- Aumentado detection radius
        collider = {
            w = 16,
            h = 16,
            offsetX = 8,
            offsetY = 8
        },
        damage = 8 -- Reducido de 10
    }
end

function EnemyFactory:createGolem(x, y)
    return {
        type = 'golem',
        transform = Transform:new(x, y),
        health = Health:new(80),
        speed = 50, -- Aumentado de 40
        behavior = PatrolBehavior:new(80), -- Aumentado patrol radius
        collider = {
            w = 32,
            h = 32,
            offsetX = 16,
            offsetY = 16
        },
        damage = 20 -- Reducido de 25
    }
end

function EnemyFactory:createFromType(enemyType, x, y)
    if enemyType == 'bat' then
        return self:createBat(x, y)
    elseif enemyType == 'golem' then
        return self:createGolem(x, y)
    else
        error("Unknown enemy type: " .. tostring(enemyType))
    end
end

return EnemyFactory
