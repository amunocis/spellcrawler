-- src/ecs/systems/movement_system.lua
-- Sistema de movimiento: aplica velocidad a transformación

local MathUtils = require('src.utils.math_utils')

local MovementSystem = {}
MovementSystem.__index = MovementSystem

function MovementSystem:new(collisionWorld)
    local instance = {
        world = collisionWorld
    }
    setmetatable(instance, self)
    return instance
end

function MovementSystem:update(entities, dt)
    for _, entity in ipairs(entities) do
        if entity.transform and entity.velocity then
            self:updateEntity(entity, dt)
        end
    end
end

function MovementSystem:updateEntity(entity, dt)
    local transform = entity.transform
    local velocity = entity.velocity

    -- Aplicar fricción si no hay input
    -- (El input system debería haber aplicado aceleración antes)
    -- velocity:applyFriction()

    -- Calcular nueva posición
    local newX = transform.x + velocity.x * dt
    local newY = transform.y + velocity.y * dt

    -- Si tiene collider, usar bump
    if entity.collider and self.world then
        local actualX, actualY, cols, len = self.world:move(
            entity.collider,
            newX + entity.collider.offsetX,
            newY + entity.collider.offsetY
        )

        transform.x = actualX - entity.collider.offsetX
        transform.y = actualY - entity.collider.offsetY

        -- Notificar colisiones
        if len > 0 and entity.onCollision then
            for _, col in ipairs(cols) do
                entity:onCollision(col)
            end
        end
    else
        -- Sin colisiones, mover directamente
        transform.x = newX
        transform.y = newY
    end
end

return MovementSystem
