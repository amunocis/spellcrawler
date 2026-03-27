-- src/ecs/components/health.lua
-- Componente de salud

local Health = {}
Health.__index = Health

function Health:new(maxHp, currentHp)
    local instance = {
        max = maxHp or 100,
        current = currentHp or maxHp or 100
    }
    setmetatable(instance, self)
    return instance
end

function Health:takeDamage(amount)
    self.current = math.max(0, self.current - amount)
    return self.current <= 0 -- Retorna true si murió
end

function Health:heal(amount)
    self.current = math.min(self.max, self.current + amount)
end

function Health:isDead()
    return self.current <= 0
end

function Health:getPercent()
    return self.current / self.max
end

return Health
