-- src/enemies/behaviors/chase_behavior.lua
-- Comportamiento: perseguir al jugador con sistema de detección en dos etapas
-- Fase 1: Detección (detectionRadius) - primera vez que ve al jugador
-- Fase 2: Focus (focusRadius) - una vez detectado, persigue a mayor distancia

local ChaseBehavior = {}
ChaseBehavior.__index = ChaseBehavior

function ChaseBehavior:new(detectionRadius, attackRadius, focusRadius)
    local instance = {
        type = 'chase',
        detectionRadius = detectionRadius or 150,  -- Rango inicial de detección (corto)
        attackRadius = attackRadius or 30,         -- Rango de ataque (muy cerca)
        focusRadius = focusRadius or 400,          -- Rango de persecución una vez detectado (largo)
        focused = false                            -- Flag: ¿ha detectado al jugador?
    }
    setmetatable(instance, self)
    return instance
end

function ChaseBehavior:update(enemy, target, dt)
    if not target then return end

    local dx = target.x - enemy.transform.x
    local dy = target.y - enemy.transform.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Determinar si debemos perseguir
    local shouldChase = false
    
    if self.focused then
        -- Si ya estamos enfocados, perseguimos hasta que salga del focusRadius
        if dist <= self.focusRadius then
            shouldChase = true
        else
            -- Pierde el foco cuando el jugador sale del rango de focus
            self.focused = false
        end
    else
        -- Si no estamos enfocados, solo detectamos en detectionRadius
        if dist <= self.detectionRadius then
            -- ¡Detectado! Activamos el modo focus
            self.focused = true
            shouldChase = true
        end
    end

    -- Perseguir si corresponde
    if shouldChase then
        -- Normalize direction
        local nx, ny
        if dist > 0 then
            nx = dx / dist
            ny = dy / dist
        else
            nx, ny = 0, 0
        end
        
        -- If within attack range, circle around the player instead of stopping
        if dist <= self.attackRadius then
            -- Perpendicular direction for circling
            local circleX = -ny
            local circleY = nx
            enemy.transform.x = enemy.transform.x + circleX * enemy.speed * 0.5 * dt
            enemy.transform.y = enemy.transform.y + circleY * enemy.speed * 0.5 * dt
        else
            -- Normal chase
            enemy.transform.x = enemy.transform.x + nx * enemy.speed * dt
            enemy.transform.y = enemy.transform.y + ny * enemy.speed * dt
        end
    end
end

return ChaseBehavior
