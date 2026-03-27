-- src/states/dungeon_state.lua
-- Estado de gameplay en la mazmorra

local bump = require('lib.bump')

local DungeonState = {}
DungeonState.__index = DungeonState

function DungeonState:new()
    local instance = {}
    setmetatable(instance, self)
    return instance
end

function DungeonState:enter()
    print("DungeonState: enter")

    -- Mundo de colisiones
    self.world = bump.newWorld(64)

    -- Jugador
    self.player = {
        x = 400,
        y = 300,
        w = 20,
        h = 20,
        speed = 250,
        hp = 100,
        maxHp = 100,
        mana = 50,
        maxMana = 50
    }
    self.world:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)

    -- Paredes de prueba
    self.walls = {}
    self:createWalls()

    -- Proyectiles
    self.projectiles = {}

    -- Cámara
    self.cameraX = 0
    self.cameraY = 0

    -- Cooldowns
    self.castCooldown = 0
    self.castCooldownMax = 0.3
end

function DungeonState:createWalls()
    -- Crear un cuarto simple
    local roomWidth = 800
    local roomHeight = 600

    -- Paredes horizontales
    for x = 0, roomWidth, 40 do
        table.insert(self.walls, {x = x, y = 0, w = 40, h = 40})
        table.insert(self.walls, {x = x, y = roomHeight - 40, w = 40, h = 40})
    end

    -- Paredes verticales
    for y = 40, roomHeight - 40, 40 do
        table.insert(self.walls, {x = 0, y = y, w = 40, h = 40})
        table.insert(self.walls, {x = roomWidth - 40, y = y, w = 40, h = 40})
    end

    -- Obstáculos internos
    table.insert(self.walls, {x = 300, y = 200, w = 40, h = 40})
    table.insert(self.walls, {x = 500, y = 400, w = 80, h = 40})
    table.insert(self.walls, {x = 200, y = 450, w = 40, h = 80})

    -- Registrar paredes en el mundo de colisiones
    for _, wall in ipairs(self.walls) do
        self.world:add(wall, wall.x, wall.y, wall.w, wall.h)
    end
end

function DungeonState:exit()
    print("DungeonState: exit")
end

function DungeonState:update(dt)
    local input = _G.Registry:get('input')

    -- Actualizar cooldowns
    if self.castCooldown > 0 then
        self.castCooldown = self.castCooldown - dt
    end

    -- Movimiento del jugador
    self:updatePlayerMovement(dt, input)

    -- Castear hechizo
    if input:isDown('cast_spell') and self.castCooldown <= 0 then
        self:castSpell()
        self.castCooldown = self.castCooldownMax
    end

    -- Actualizar proyectiles
    self:updateProjectiles(dt)

    -- Actualizar cámara
    self.cameraX = self.player.x - love.graphics.getWidth() / 2
    self.cameraY = self.player.y - love.graphics.getHeight() / 2
end

function DungeonState:updatePlayerMovement(dt, input)
    local moveX, moveY = input:getMovementVector()

    -- Calcular nueva posición
    local newX = self.player.x + moveX * self.player.speed * dt
    local newY = self.player.y + moveY * self.player.speed * dt

    -- Mover con resolución de colisiones (bump)
    local actualX, actualY, cols, len = self.world:move(self.player, newX, newY)

    self.player.x = actualX
    self.player.y = actualY
end

function DungeonState:castSpell()
    local input = _G.Registry:get('input')
    local aimX, aimY = input:getAimDirection(
        self.player.x - self.cameraX,
        self.player.y - self.cameraY
    )

    if aimX == 0 and aimY == 0 then
        aimX = 1 -- Default a la derecha
    end

    -- Crear proyectil
    local projectile = {
        x = self.player.x + self.player.w / 2 - 5,
        y = self.player.y + self.player.h / 2 - 5,
        w = 10,
        h = 10,
        vx = aimX * 400,
        vy = aimY * 400,
        lifetime = 2.0
    }

    self.world:add(projectile, projectile.x, projectile.y, projectile.w, projectile.h)
    table.insert(self.projectiles, projectile)

    -- Emitir evento
    local eventBus = _G.Registry:get('event_bus')
    eventBus:emit('spell:cast', {
        type = 'chispa',
        x = projectile.x,
        y = projectile.y,
        direction = {x = aimX, y = aimY}
    })
end

function DungeonState:updateProjectiles(dt)
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]

        -- Mover proyectil
        local newX = p.x + p.vx * dt
        local newY = p.y + p.vy * dt

        -- Colisiones con el mundo
        local actualX, actualY, cols, len = self.world:move(p, newX, newY, function(item, other)
            -- Filtro de colisiones: proyectil choca con paredes
            if other ~= self.player then
                return 'touch'
            end
            return 'cross'
        end)

        p.x = actualX
        p.y = actualY

        -- Si chocó con algo, destruir
        if len > 0 then
            self.world:remove(p)
            table.remove(self.projectiles, i)

            -- Emitir evento de impacto
            local eventBus = _G.Registry:get('event_bus')
            eventBus:emit('spell:impact', {
                x = p.x,
                y = p.y,
                target = cols[1] and cols[1].other or nil
            })
        else
            -- Actualizar lifetime
            p.lifetime = p.lifetime - dt
            if p.lifetime <= 0 then
                self.world:remove(p)
                table.remove(self.projectiles, i)
            end
        end
    end
end

function DungeonState:draw()
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)

    -- Aplicar cámara
    love.graphics.push()
    love.graphics.translate(-self.cameraX, -self.cameraY)

    -- Dibujar suelo
    love.graphics.setColor(0.12, 0.12, 0.18)
    love.graphics.rectangle('fill', 0, 0, 800, 600)

    -- Dibujar paredes
    love.graphics.setColor(0.3, 0.3, 0.4)
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle('fill', wall.x, wall.y, wall.w, wall.h)
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.rectangle('line', wall.x, wall.y, wall.w, wall.h)
        love.graphics.setColor(0.3, 0.3, 0.4)
    end

    -- Dibujar proyectiles
    for _, p in ipairs(self.projectiles) do
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.circle('fill', p.x + p.w/2, p.y + p.h/2, p.w/2)

        -- Glow
        love.graphics.setColor(1, 0.6, 0, 0.3)
        love.graphics.circle('fill', p.x + p.w/2, p.y + p.h/2, p.w)
    end

    -- Dibujar jugador
    love.graphics.setColor(0.6, 0.4, 0.9)
    love.graphics.rectangle('fill', self.player.x, self.player.y, self.player.w, self.player.h)

    -- Indicador de dirección
    local input = _G.Registry:get('input')
    local aimX, aimY = input:getAimDirection(
        self.player.x - self.cameraX,
        self.player.y - self.cameraY
    )
    if aimX ~= 0 or aimY ~= 0 then
        love.graphics.setColor(0.8, 0.6, 1)
        love.graphics.line(
            self.player.x + self.player.w/2,
            self.player.y + self.player.h/2,
            self.player.x + self.player.w/2 + aimX * 40,
            self.player.y + self.player.h/2 + aimY * 40
        )
    end

    love.graphics.pop()

    -- UI (sin cámara)
    self:drawUI()
end

function DungeonState:drawUI()
    -- Barra de HP
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle('fill', 20, 20, 200, 20)
    love.graphics.setColor(0.9, 0.2, 0.2)
    local hpPercent = self.player.hp / self.player.maxHp
    love.graphics.rectangle('fill', 20, 20, 200 * hpPercent, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', 20, 20, 200, 20)
    love.graphics.print("HP: " .. self.player.hp .. "/" .. self.player.maxHp, 25, 22)

    -- Barra de Mana
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle('fill', 20, 50, 200, 15)
    love.graphics.setColor(0.2, 0.6, 1)
    local manaPercent = self.player.mana / self.player.maxMana
    love.graphics.rectangle('fill', 20, 50, 200 * manaPercent, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', 20, 50, 200, 15)
    love.graphics.print("Mana: " .. self.player.mana .. "/" .. self.player.maxMana, 25, 50)

    -- Instrucciones
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.print("WASD: Mover | MOUSE: Apuntar | CLICK/ESPACIO: Disparar", 20, love.graphics.getHeight() - 30)
    love.graphics.print("ESC: Volver al Hub", 20, love.graphics.getHeight() - 50)
end

function DungeonState:keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        local stateManager = _G.Registry:get('state_manager')
        stateManager:switch('hub')
    end
end

return DungeonState
