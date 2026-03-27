-- src/ecs/components/transform.lua
-- Componente de transformación: posición y rotación

local Transform = {}
Transform.__index = Transform

function Transform:new(x, y, rotation)
    local instance = {
        x = x or 0,
        y = y or 0,
        rotation = rotation or 0
    }
    setmetatable(instance, self)
    return instance
end

function Transform:setPosition(x, y)
    self.x = x
    self.y = y
end

function Transform:translate(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

function Transform:getPosition()
    return self.x, self.y
end

function Transform:setRotation(angle)
    self.rotation = angle
end

function Transform:rotate(angle)
    self.rotation = self.rotation + angle
end

return Transform
