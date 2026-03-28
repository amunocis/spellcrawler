-- src/states/dungeon_state.lua
-- Estado de gameplay en la mazmorra (con generación procedural)

local bump = require('lib.bump')
local SpellRegistry = require('src.spells.spell_registry')
local SpellCaster = require('src.spells.spell_caster')
local SpellDataLoader = require('src.spells.spell_data_loader')
local EnemyFactory = require('src.enemies.enemy_factory')
local CombatSystem = require('src.combat.combat_system')
local FloorGenerator = require('src.dungeon.floor_generator')
local RoomRenderer = require('src.dungeon.room_renderer')

local DungeonState = {}
DungeonState.__index = DungeonState

function DungeonState:new()
    local instance = {}
    setmetatable(instance, self)
    return instance
end

function DungeonState:enter(seed)
    print("DungeonState: enter")

    -- Generar dungeon procedural
    local generator = FloorGenerator:new(seed)
    self.floor = generator:generate(8)  -- 8 habitaciones
    self.roomRenderer = RoomRenderer:new()
    
    -- Renderizar cada habitación a tiles
    self.roomTiles = {}
    self.walls = {}
    
    for _, room in ipairs(self.floor.rooms) do
      self.roomTiles[room] = self.roomRenderer:generateTiles(room, 'cavern')
      local collisionObjects = self.roomRenderer:createCollisionObjects(room, self.roomTiles[room])
      
      for _, obj in ipairs(collisionObjects) do
        table.insert(self.walls, obj)
      end
    end

    -- Mundo de colisiones
    self.world = bump.newWorld(64)

    -- Cargar hechizos
    SpellDataLoader:loadAllSpells()

    -- Encontrar habitación de entrada y posicionar jugador
    local entranceRoom = self.floor:getEntrance()
    local spawnPos = self.roomRenderer:getPlayerSpawn(entranceRoom)
    
    -- Jugador con SpellCaster
    self.player = {
        x = spawnPos.x,
        y = spawnPos.y,
        w = 20,
        h = 20,
        speed = 250,
        hp = 100,
        maxHp = 100,
        mana = 50,
        maxMana = 50,
        spellCaster = SpellCaster:new()
    }
    self.world:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)

    -- Equipar hechizos
    self.player.spellCaster:equipSpell(1, 'chispa')
    self.player.spellCaster:equipSpell(2, 'dardo_magico')
    self.player.spellCaster:equipSpell(3, 'rafaga_viento')

    -- Slot seleccionado
    self.selectedSlot = 1

    -- Estado de game over
    self.gameOver = false
    self.gameOverTimer = 0

    -- Feedback visual
    self.damageFlash = 0
    self.particles = {}

    -- Registrar paredes en bump
    for _, wall in ipairs(self.walls) do
      self.world:add(wall, wall.x, wall.y, wall.w, wall.h)
    end

    -- Sistema de combate
    self.combatSystem = CombatSystem:new()

    -- Spawnear enemigos en cada habitación de combate
    self:spawnEnemiesInRooms()

    -- Cámara
    self.cameraX = 0
    self.cameraY = 0
    
    -- Habitación actual del jugador
    self.currentRoom = entranceRoom
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



function DungeonState:isPositionSafeFromPlayer(x, y, minDistance)
    minDistance = minDistance or 150
    local dx = x - self.player.x
    local dy = y - self.player.y
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist >= minDistance
end

function DungeonState:isInsideWorldBounds(x, y, w, h)
    local bounds = self:calculateWorldBounds()
    local offsetX = (w or 16) / 2
    local offsetY = (h or 16) / 2
    return x >= bounds.x + offsetX and
           x <= bounds.x + bounds.w - offsetX and
           y >= bounds.y + offsetY and
           y <= bounds.y + bounds.h - offsetY
end

function DungeonState:spawnEnemySafe(createFn, x, y)
    -- Intentar posición dada, si está muy cerca del jugador o fuera de límites, buscar otra
    local spawnX, spawnY = x, y
    local attempts = 0
    local maxAttempts = 20

    while attempts < maxAttempts do
        -- Verificar si la posición actual es válida (segura Y dentro de límites)
        if self:isPositionSafeFromPlayer(spawnX, spawnY) and 
           self:isInsideWorldBounds(spawnX, spawnY) then
            break
        end
        
        -- Elegir posición aleatoria dentro de una habitación
        -- Por ahora, usar posición de habitación de entrada
        local entrance = self.floor:getEntrance()
        if entrance then
            local center = entrance:getCenter()
            spawnX = center.x * 40 + math.random(-50, 50)
            spawnY = center.y * 40 + math.random(-50, 50)
        end
        attempts = attempts + 1
    end

    local enemy = createFn(spawnX, spawnY)
    self.combatSystem:addEnemy(enemy)
    self.world:add(enemy, enemy.transform.x, enemy.transform.y, enemy.collider.w, enemy.collider.h)
    return enemy
end

function DungeonState:spawnEnemiesInRooms()
    -- Spawnear enemigos en habitaciones de combate
    for _, room in ipairs(self.floor.rooms) do
      -- Determinar tipo de contenido si no está asignado
      if not room.contentType or room.contentType == 'empty' then
        if room.isEntrance or room.isExit then
          room:setContentType('empty')
        elseif math.random() < 0.2 then
          room:setContentType('treasure')
        elseif math.random() < 0.15 then
          room:setContentType('boss')
        else
          room:setContentType('combat')
        end
      end
      
      -- Spawnear enemigos según tipo
      if room.contentType == 'combat' then
        self:spawnEnemiesInRoom(room, math.random(2, 4))
      elseif room.contentType == 'boss' then
        self:spawnEnemiesInRoom(room, 1, true)  -- 1 enemigo fuerte
      elseif room.contentType == 'treasure' then
        -- No enemigos, solo loot
      end
    end
end

function DungeonState:spawnEnemiesInRoom(room, count, isBoss)
    local spawnPoints = self.roomRenderer:getEnemySpawnPoints(room, self.roomTiles[room])
    
    -- Mezclar spawn points
    for i = #spawnPoints, 2, -1 do
        local j = math.random(i)
        spawnPoints[i], spawnPoints[j] = spawnPoints[j], spawnPoints[i]
    end
    
    -- Spawnear enemigos
    for i = 1, math.min(count, #spawnPoints) do
        local point = spawnPoints[i]
        local enemy
        
        if isBoss then
            enemy = EnemyFactory:createGolem(point.x, point.y)
        else
            enemy = EnemyFactory:createBat(point.x, point.y)
        end
        
        self.combatSystem:addEnemy(enemy)
        self.world:add(enemy, enemy.transform.x, enemy.transform.y, enemy.collider.w, enemy.collider.h)
    end
end

function DungeonState:updateEnemies(dt)
    for _, enemy in ipairs(self.combatSystem.enemies) do
        if not enemy.dead and enemy.behavior then
            -- Calcular nueva posición deseada
            local oldX, oldY = enemy.transform.x, enemy.transform.y
            enemy.behavior:update(enemy, self.player, dt)

            -- Mover con colisiones (respetar paredes)
            local newX, newY = enemy.transform.x, enemy.transform.y
            enemy.transform.x, enemy.transform.y = oldX, oldY -- Reset para bump

            -- Clamp a límites del mundo
            newX, newY = self:clampToWorldBounds(newX, newY, enemy.collider.w, enemy.collider.h)

            local actualX, actualY, cols, len = self.world:move(enemy, newX, newY, function(item, other)
                -- Enemigos colisionan con paredes y jugador
                if other == self.player then
                    return 'touch'
                end
                -- Ignorar otros enemigos
                if other.transform then
                    return 'cross'
                end
                return 'touch' -- Paredes
            end)

            enemy.transform.x = actualX
            enemy.transform.y = actualY

            -- Verificar colisión con jugador (daño)
            for _, col in ipairs(cols) do
                if col.other == self.player then
                    self:handlePlayerHitByEnemy(enemy)
                    break
                end
            end
        end
    end
end

function DungeonState:handlePlayerHitByEnemy(enemy)
    -- Cooldown de daño simple (0.5 segundos entre hits)
    if not self.player._damageCooldown or self.player._damageCooldown <= 0 then
        self.player.hp = math.max(0, self.player.hp - enemy.damage)
        self.player._damageCooldown = 0.5

        -- Feedback visual: flash de daño
        self.damageFlash = 0.3

        -- Emitir evento
        local eventBus = _G.Registry:get('event_bus')
        eventBus:emit('player:damage', {
            amount = enemy.damage,
            source = enemy.type,
            hp = self.player.hp
        })

        if self.player.hp <= 0 then
            self:triggerGameOver()
        end
    end
end

function DungeonState:triggerGameOver()
    self.gameOver = true
    self.gameOverTimer = 3.0 -- 3 segundos antes de volver al hub

    local eventBus = _G.Registry:get('event_bus')
    eventBus:emit('player:died', {})
end

function DungeonState:handleKilledEnemies(killed)
    for _, enemy in ipairs(killed) do
        -- Remove from collision world immediately (safe remove)
        local ok, err = pcall(function() self.world:remove(enemy) end)
        
        -- Create death particles
        self:createImpactParticles(
            enemy.transform.x + enemy.collider.w / 2,
            enemy.transform.y + enemy.collider.h / 2,
            {0.8, 0.2, 0.2}
        )

        -- Emit event for potential rewards
        local eventBus = _G.Registry:get('event_bus')
        eventBus:emit('enemy:killed', {
            type = enemy.type,
            x = enemy.transform.x,
            y = enemy.transform.y
        })
    end
end

function DungeonState:exit()
    print("DungeonState: exit")
end

function DungeonState:createImpactParticles(x, y, color)
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local speed = math.random(50, 150)
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            lifetime = 0.3,
            color = color or {1, 0.8, 0.2},
            size = math.random(2, 4)
        })
    end
end

function DungeonState:updateParticles(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.lifetime = p.lifetime - dt
        if p.lifetime <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function DungeonState:update(dt)
    -- Si hay game over, solo manejar el timer
    if self.gameOver then
        self.gameOverTimer = self.gameOverTimer - dt
        if self.gameOverTimer <= 0 then
            local stateManager = _G.Registry:get('state_manager')
            stateManager:switch('hub')
        end
        return
    end

    local input = _G.Registry:get('input')

    -- Actualizar SpellCaster (cooldowns)
    self.player.spellCaster:update(dt)

    -- Actualizar cooldown de daño al jugador
    if self.player._damageCooldown and self.player._damageCooldown > 0 then
        self.player._damageCooldown = self.player._damageCooldown - dt
    end

    -- Actualizar damage flash
    if self.damageFlash > 0 then
        self.damageFlash = self.damageFlash - dt
    end

    -- Actualizar partículas
    self:updateParticles(dt)

    -- Cambiar slot de hechizo
    if input:pressed('spell_1') then self.selectedSlot = 1 end
    if input:pressed('spell_2') then self.selectedSlot = 2 end
    if input:pressed('spell_3') then self.selectedSlot = 3 end

    -- Movimiento del jugador
    self:updatePlayerMovement(dt, input)

    -- Castear hechizo (autofire con cooldown de 0.1s entre disparos)
    if input:isDown('cast_spell') then
        if not self.player._castCooldown or self.player._castCooldown <= 0 then
            self:castSpell()
            self.player._castCooldown = 0.1 -- Mínimo 0.1s entre disparos
        end
    end
    if self.player._castCooldown and self.player._castCooldown > 0 then
        self.player._castCooldown = self.player._castCooldown - dt
    end

    -- Actualizar enemigos
    self:updateEnemies(dt)

    -- Actualizar proyectiles
    self:updateProjectiles(dt)

    -- Actualizar combate
    local killed = self.combatSystem:update(dt)
    self:handleKilledEnemies(killed)

    -- Limpiar enemigos muertos
    self.combatSystem:removeDeadEntities()

    -- Actualizar cámara
    self.cameraX = self.player.x - love.graphics.getWidth() / 2
    self.cameraY = self.player.y - love.graphics.getHeight() / 2
end

function DungeonState:calculateWorldBounds()
    -- Calcular bounds basado en las habitaciones generadas
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local tileSize = 40
    
    for _, room in ipairs(self.floor.rooms) do
        minX = math.min(minX, room.x * tileSize)
        minY = math.min(minY, room.y * tileSize)
        maxX = math.max(maxX, (room.x + room.width) * tileSize)
        maxY = math.max(maxY, (room.y + room.height) * tileSize)
    end
    
    -- Agregar margen
    local margin = 100
    return {
        x = minX - margin,
        y = minY - margin,
        w = (maxX - minX) + margin * 2,
        h = (maxY - minY) + margin * 2
    }
end

function DungeonState:clampToWorldBounds(x, y, w, h)
    local bounds = self:calculateWorldBounds()
    local clampedX = math.max(bounds.x, math.min(x, bounds.x + bounds.w - w))
    local clampedY = math.max(bounds.y, math.min(y, bounds.y + bounds.h - h))
    return clampedX, clampedY
end

function DungeonState:updatePlayerMovement(dt, input)
    local moveX, moveY = input:getMovementVector()

    -- Calcular nueva posición
    local newX = self.player.x + moveX * self.player.speed * dt
    local newY = self.player.y + moveY * self.player.speed * dt

    -- Clamp a límites del mundo antes de colisiones
    newX, newY = self:clampToWorldBounds(newX, newY, self.player.w, self.player.h)

    -- Mover con resolución de colisiones (bump)
    local actualX, actualY, cols, len = self.world:move(self.player, newX, newY)

    self.player.x = actualX
    self.player.y = actualY
end

function DungeonState:findNearestEnemy()
    local nearest = nil
    local minDist = math.huge
    local px = self.player.x + self.player.w / 2
    local py = self.player.y + self.player.h / 2
    
    for _, enemy in ipairs(self.combatSystem.enemies) do
        -- Skip dead enemies and enemies without transform
        if not enemy.dead and enemy.transform and enemy.health and enemy.health.current > 0 then
            local ex = enemy.transform.x + (enemy.collider and enemy.collider.offsetX or 0) + enemy.collider.w / 2
            local ey = enemy.transform.y + (enemy.collider and enemy.collider.offsetY or 0) + enemy.collider.h / 2
            local dx = ex - px
            local dy = ey - py
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist < minDist then
                minDist = dist
                nearest = enemy
            end
        end
    end
    
    return nearest
end

function DungeonState:getAimDirectionWithAutoaim()
    local input = _G.Registry:get('input')
    
    -- Try to get analog aim from right stick first
    local aimX, aimY = input:getAnalogAim(
        self.player.x - self.cameraX,
        self.player.y - self.cameraY
    )
    
    -- If right stick is active, use it
    if math.abs(aimX) > 0.2 or math.abs(aimY) > 0.2 then
        return aimX, aimY, false -- false = not autoaim
    end
    
    -- If gamepad is connected but stick is inactive, use autoaim
    if input:isGamepadConnected() then
        local nearest = self:findNearestEnemy()
        if nearest then
            local px = self.player.x + self.player.w / 2
            local py = self.player.y + self.player.h / 2
            local ex = nearest.transform.x + (nearest.collider and nearest.collider.offsetX or 0) + nearest.collider.w / 2
            local ey = nearest.transform.y + (nearest.collider and nearest.collider.offsetY or 0) + nearest.collider.h / 2
            
            local dx = ex - px
            local dy = ey - py
            local length = math.sqrt(dx * dx + dy * dy)
            
            if length > 0 then
                return dx / length, dy / length, true -- true = autoaim
            end
        end
    end
    
    -- Fallback to default direction (right)
    return 1, 0, false
end

function DungeonState:castSpell()
    local input = _G.Registry:get('input')
    local aimX, aimY, isAutoaim = self:getAimDirectionWithAutoaim()

    -- Calcular centro del jugador
    local centerX = self.player.x + self.player.w / 2
    local centerY = self.player.y + self.player.h / 2

    -- Spawnear proyectil en la punta del marcador de dirección (40px desde el centro)
    local spawnDistance = 40
    local spawnX = centerX + aimX * spawnDistance - 5
    local spawnY = centerY + aimY * spawnDistance - 5
    
    local projectile = self.player.spellCaster:cast(self.selectedSlot, spawnX, spawnY, aimX, aimY)

    if not projectile then
        return -- Cooldown activo o slot vacío
    end

    -- Agregar dimensiones para colisiones (solo para CombatSystem, NO para bump)
    projectile.w = 10
    projectile.h = 10

    -- Agregar al sistema de combate (colisiones lógicas con enemigos)
    self.combatSystem:addProjectile(projectile)
    
    -- NOTA: Los proyectiles NO se registran en bump
    -- - Colisión con enemigos: CombatSystem (lógica)
    -- - Colisión con paredes: updateProjectiles verifica manualmente

    -- Emitir evento
    local eventBus = _G.Registry:get('event_bus')
    eventBus:emit('spell:cast', {
        type = projectile.spellId,
        x = projectile.x,
        y = projectile.y,
        direction = {x = aimX, y = aimY}
    })
end

function DungeonState:updateProjectiles(dt)
    for i = #self.combatSystem.projectiles, 1, -1 do
        local p = self.combatSystem.projectiles[i]

        -- Mover proyectil (actualización puramente manual)
        local newX = p.x + p.vx * dt
        local newY = p.y + p.vy * dt

        -- Verificar colisión con paredes usando AABB simple contra self.walls
        local hitWall = false
        for _, wall in ipairs(self.walls) do
            if newX < wall.x + wall.w and
               newX + p.w > wall.x and
               newY < wall.y + wall.h and
               newY + p.h > wall.y then
                hitWall = true
                break
            end
        end
        
        -- También verificar límites del mundo (basado en habitaciones)
        local bounds = self:calculateWorldBounds()
        if newX < bounds.x or 
           newX + p.w > bounds.x + bounds.w or
           newY < bounds.y or 
           newY + p.h > bounds.y + bounds.h then
            hitWall = true
        end

        if hitWall then
            -- Crear partículas de impacto
            local spellDef = SpellRegistry:get(p.spellId)
            self:createImpactParticles(p.x + p.w/2, p.y + p.h/2, spellDef and spellDef.color)

            -- Remover de la lista
            table.remove(self.combatSystem.projectiles, i)

            -- Emitir evento de impacto
            local eventBus = _G.Registry:get('event_bus')
            eventBus:emit('spell:impact', {
                x = p.x,
                y = p.y,
                target = 'wall'
            })
        else
            -- Actualizar posición del proyectil
            p.x = newX
            p.y = newY
            
            -- Actualizar lifetime
            p.lifetime = p.lifetime - dt
            if p.lifetime <= 0 then
                table.remove(self.combatSystem.projectiles, i)
            end
        end
    end
end

function DungeonState:draw()
    -- Si hay game over, dibujar pantalla oscura
    if self.gameOver then
        love.graphics.setBackgroundColor(0, 0, 0)
        love.graphics.clear()

        love.graphics.setColor(0.8, 0.2, 0.2)
        local text = "HAS MUERTO"
        local textW = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, love.graphics.getWidth()/2 - textW/2, love.graphics.getHeight()/2 - 50)

        love.graphics.setColor(0.7, 0.7, 0.7)
        local subText = "Volviendo al Hub en " .. math.ceil(self.gameOverTimer) .. "..."
        local subTextW = love.graphics.getFont():getWidth(subText)
        love.graphics.print(subText, love.graphics.getWidth()/2 - subTextW/2, love.graphics.getHeight()/2 + 20)
        return
    end

    love.graphics.setBackgroundColor(0.05, 0.05, 0.08)

    -- Aplicar cámara
    love.graphics.push()
    love.graphics.translate(-self.cameraX, -self.cameraY)

    -- Dibujar habitaciones generadas proceduralmente
    -- Nota: la cámara ya se aplicó con translate, pasamos 0,0
    if self.floor and self.roomRenderer then
        for _, room in ipairs(self.floor.rooms) do
            if self.roomTiles[room] then
                self.roomRenderer:draw(room, self.roomTiles[room], 0, 0)
            end
        end
    end

    -- Dibujar proyectiles
    for _, p in ipairs(self.combatSystem.projectiles) do
        -- Obtener color del hechizo
        local spellDef = SpellRegistry:get(p.spellId)
        local color = spellDef and spellDef.color or {1, 0.8, 0.2}

        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.circle('fill', p.x + p.w/2, p.y + p.h/2, p.w/2)

        -- Glow
        love.graphics.setColor(color[1], color[2], color[3], 0.3)
        love.graphics.circle('fill', p.x + p.w/2, p.y + p.h/2, p.w)
    end

    -- Dibujar partículas
    for _, p in ipairs(self.particles) do
        local alpha = p.lifetime / 0.3 -- Fade out
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle('fill', p.x, p.y, p.size)
    end

    -- Dibujar enemigos
    for _, enemy in ipairs(self.combatSystem.enemies) do
        if not enemy.dead then
            local ex = enemy.transform.x + (enemy.collider.offsetX or 0)
            local ey = enemy.transform.y + (enemy.collider.offsetY or 0)

            -- Color según tipo
            if enemy.type == 'bat' then
                love.graphics.setColor(0.6, 0.2, 0.8) -- Morado
            elseif enemy.type == 'golem' then
                love.graphics.setColor(0.5, 0.5, 0.5) -- Gris
            else
                love.graphics.setColor(0.8, 0.2, 0.2) -- Rojo default
            end

            love.graphics.rectangle('fill', ex, ey, enemy.collider.w, enemy.collider.h)

            -- Borde
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle('line', ex, ey, enemy.collider.w, enemy.collider.h)

            -- Barra de HP
            local hpPercent = enemy.health.current / enemy.health.max
            local barW = enemy.collider.w
            local barH = 4
            local barY = ey - 8

            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle('fill', ex, barY, barW, barH)

            love.graphics.setColor(0.9, 0.2, 0.2)
            love.graphics.rectangle('fill', ex, barY, barW * hpPercent, barH)
        end
    end

    -- Dibujar jugador
    love.graphics.setColor(0.6, 0.4, 0.9)
    love.graphics.rectangle('fill', self.player.x, self.player.y, self.player.w, self.player.h)

    -- Indicador de dirección (con autoaim)
    local aimX, aimY, isAutoaim = self:getAimDirectionWithAutoaim()
    if aimX ~= 0 or aimY ~= 0 then
        -- Color diferente para autoaim (amarillo) vs manual (morado)
        if isAutoaim then
            love.graphics.setColor(1, 0.8, 0.2) -- Amarillo = autoaim activo
        else
            love.graphics.setColor(0.8, 0.6, 1) -- Morado = aim manual
        end
        love.graphics.line(
            self.player.x + self.player.w/2,
            self.player.y + self.player.h/2,
            self.player.x + self.player.w/2 + aimX * 40,
            self.player.y + self.player.h/2 + aimY * 40
        )
        
        -- Punto en la punta del indicador
        if isAutoaim then
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.circle('fill', 
                self.player.x + self.player.w/2 + aimX * 40,
                self.player.y + self.player.h/2 + aimY * 40, 
                4
            )
        end
    end

    love.graphics.pop()

    -- Flash de daño (pantalla completa)
    if self.damageFlash > 0 then
        local alpha = math.min(0.5, self.damageFlash)
        love.graphics.setColor(1, 0, 0, alpha)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

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

    -- Slots de hechizos
    local slotSize = 50
    local slotGap = 10
    local startX = love.graphics.getWidth() / 2 - ((3 * slotSize + 2 * slotGap) / 2)
    local slotY = love.graphics.getHeight() - 80

    for slot = 1, 3 do
        local slotX = startX + (slot - 1) * (slotSize + slotGap)
        local spellId = self.player.spellCaster.slots[slot]
        local spellDef = spellId and SpellRegistry:get(spellId)
        local cooldownPercent = self.player.spellCaster:getCooldownPercent(slot)

        -- Fondo del slot
        if slot == self.selectedSlot then
            love.graphics.setColor(0.9, 0.8, 0.3) -- Dorado para seleccionado
            love.graphics.rectangle('fill', slotX - 3, slotY - 3, slotSize + 6, slotSize + 6)
        end

        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle('fill', slotX, slotY, slotSize, slotSize)

        -- Icono del hechizo (color)
        if spellDef then
            love.graphics.setColor(spellDef.color[1], spellDef.color[2], spellDef.color[3])
            love.graphics.rectangle('fill', slotX + 5, slotY + 5, slotSize - 10, slotSize - 10)
        end

        -- Cooldown overlay
        if cooldownPercent > 0 then
            love.graphics.setColor(0, 0, 0, 0.6)
            local cooldownHeight = slotSize * cooldownPercent
            love.graphics.rectangle('fill', slotX, slotY, slotSize, cooldownHeight)
        end

        -- Borde
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle('line', slotX, slotY, slotSize, slotSize)

        -- Número del slot
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tostring(slot), slotX + 4, slotY + 2)

        -- Nombre del hechizo
        if spellDef then
            love.graphics.setColor(0.8, 0.8, 0.9)
            local name = spellDef.name:sub(1, 6) -- Acortar si es largo
            love.graphics.print(name, slotX, slotY + slotSize + 4)
        end
    end

    -- Instrucciones
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.print("WASD: Mover | MOUSE: Apuntar | CLICK/ESPACIO: Disparar | 1-2-3: Cambiar Hechizo", 20, love.graphics.getHeight() - 30)
    love.graphics.print("ESC: Volver al Hub", 20, love.graphics.getHeight() - 50)
end

function DungeonState:keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        local stateManager = _G.Registry:get('state_manager')
        stateManager:switch('hub')
    end
end

return DungeonState
