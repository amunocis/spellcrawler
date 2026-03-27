-- src/ecs/components/velocity.lua
-- Componente de velocidad para movimiento

local Velocity = {}
Velocity.__index = Velocity

function Velocity:new(vx, vy, maxSpeed, friction)
    local instance = {
        x = vx or 0,
        y = vy or 0,
        maxSpeed = maxSpeed or 300,
        friction = friction or 0.9
    }
    setmetatable(instance, self)
    return instance
end

function Velocity:set(vx, vy)
    self.x = vx
    self.y = vy
    self:clamp()
end

function Velocity:add(vx, vy)
    self.x = self.x + vx
    self.y = self.y + vy
    self:clamp()
end

function Velocity:clamp()
    local speed = math.sqrt(self.x * self.x + self.y * self.y)
    if speed > self.maxSpeed and speed > 0 then
        local scale = self.maxSpeed / speed
        self.x = self.x * scale
        self.y = self.y * scale
    end
end

function Velocity:applyFriction()
    self.x = self.x * self.friction
    self.y = self.y * self.friction
end

function Velocity:getSpeed()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

return Velocity
