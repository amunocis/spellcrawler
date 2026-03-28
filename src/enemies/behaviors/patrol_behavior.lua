-- src/enemies/behaviors/patrol_behavior.lua
-- Comportamiento: patrullar área

local PatrolBehavior = {}
PatrolBehavior.__index = PatrolBehavior

function PatrolBehavior:new(radius)
    local instance = {
        type = 'patrol',
        radius = radius or 50,
        targetX = nil,
        targetY = nil,
        waitTimer = 0,
        waitDuration = 1.0
    }
    setmetatable(instance, self)
    return instance
end

function PatrolBehavior:update(enemy, target, dt)
    -- Pick new target if none exists
    if not self.targetX or not self.targetY then
        self:pickNewTarget(enemy)
    end

    -- Waiting at target
    if self.waitTimer > 0 then
        self.waitTimer = self.waitTimer - dt
        if self.waitTimer <= 0 then
            self:pickNewTarget(enemy)
        end
        return
    end

    local dx = self.targetX - enemy.transform.x
    local dy = self.targetY - enemy.transform.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 5 then
        -- Reached target, start waiting
        self.waitTimer = self.waitDuration
    else
        -- Move towards target
        local nx = dx / dist
        local ny = dy / dist

        enemy.transform.x = enemy.transform.x + nx * enemy.speed * dt
        enemy.transform.y = enemy.transform.y + ny * enemy.speed * dt
    end
end

function PatrolBehavior:pickNewTarget(enemy)
    local angle = math.random() * math.pi * 2
    local dist = math.random() * self.radius

    self.targetX = enemy.transform.x + math.cos(angle) * dist
    self.targetY = enemy.transform.y + math.sin(angle) * dist
end

return PatrolBehavior
