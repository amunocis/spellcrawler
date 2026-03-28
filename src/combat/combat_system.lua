-- src/combat/combat_system.lua
-- Sistema de combate: maneja colisiones proyectil-enemigo y daño

local CombatSystem = {}
CombatSystem.__index = CombatSystem

function CombatSystem:new()
    local instance = {
        projectiles = {},
        enemies = {}
    }
    setmetatable(instance, self)
    return instance
end

function CombatSystem:addProjectile(projectile)
    table.insert(self.projectiles, projectile)
end

function CombatSystem:addEnemy(enemy)
    table.insert(self.enemies, enemy)
end

function CombatSystem:checkCollision(projectile, enemy)
    -- Calculate enemy bounds
    local ex = enemy.transform.x + (enemy.collider.offsetX or 0)
    local ey = enemy.transform.y + (enemy.collider.offsetY or 0)
    local ew = enemy.collider.w
    local eh = enemy.collider.h

    -- Projectile bounds
    local px = projectile.x
    local py = projectile.y
    local pw = projectile.w
    local ph = projectile.h

    -- AABB collision check
    return px < ex + ew and
           px + pw > ex and
           py < ey + eh and
           py + ph > ey
end

function CombatSystem:update(dt)
    local killedEnemies = {}

    -- Check projectile-enemy collisions
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]
        local hit = false

        for _, enemy in ipairs(self.enemies) do
            -- Skip dead enemies and enemies with no health
            if not enemy.dead and enemy.health and enemy.health.current > 0 and self:checkCollision(projectile, enemy) then
                -- Apply damage
                local died = enemy.health:takeDamage(projectile.damage)

                if died then
                    enemy.dead = true
                    table.insert(killedEnemies, enemy)
                end

                hit = true
                break -- Projectile hits only one enemy
            end
        end

        if hit then
            table.remove(self.projectiles, i)
        end
    end

    return killedEnemies
end

function CombatSystem:removeDeadEntities()
    for i = #self.enemies, 1, -1 do
        if self.enemies[i].dead then
            table.remove(self.enemies, i)
        end
    end
end

return CombatSystem
