-- src/utils/math_utils.lua
-- Funciones matemáticas útiles

local MathUtils = {}

function MathUtils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

function MathUtils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function MathUtils.distanceSquared(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy
end

function MathUtils.normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length > 0 then
        return x / length, y / length
    end
    return 0, 0
end

function MathUtils.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function MathUtils.randomRange(min, max)
    return min + math.random() * (max - min)
end

function MathUtils.sign(value)
    if value > 0 then return 1 end
    if value < 0 then return -1 end
    return 0
end

return MathUtils
