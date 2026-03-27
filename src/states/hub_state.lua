-- src/states/hub_state.lua
-- Estado del pueblo/hub: NPCs, misiones, gestión del grimorio

local HubState = {}
HubState.__index = HubState

function HubState:new()
    local instance = {}
    setmetatable(instance, self)
    return instance
end

function HubState:enter()
    print("HubState: enter")

    -- Posición del jugador en el hub
    self.playerX = 400
    self.playerY = 300
    self.playerSpeed = 200

    -- NPCs de prueba
    self.npcs = {
        {x = 200, y = 200, name = "Sastre Elena", questAvailable = true, dialogue = "¡Necesito que alguien limpie el vestido de mi hija!"},
        {x = 600, y = 250, name = "Guardián Boris", questAvailable = false, dialogue = "La mazmorra del norte es peligrosa, pero ahí encontrarás grimorios útiles."},
    }

    -- Cámara simple
    self.cameraX = 0
    self.cameraY = 0
end

function HubState:exit()
    print("HubState: exit")
end

function HubState:update(dt)
    local input = _G.Registry:get('input')

    -- Movimiento del jugador
    local moveX, moveY = input:getMovementVector()
    self.playerX = self.playerX + moveX * self.playerSpeed * dt
    self.playerY = self.playerY + moveY * self.playerSpeed * dt

    -- Limitar al área del hub
    self.playerX = math.max(50, math.min(love.graphics.getWidth() - 50, self.playerX))
    self.playerY = math.max(50, math.min(love.graphics.getHeight() - 50, self.playerY))

    -- Interacción
    if input:pressed('interact') then
        self:checkNPCInteraction()
    end

    -- Entrar a dungeon (temporal - para testing)
    if input:pressed('cast_spell') then
        local stateManager = _G.Registry:get('state_manager')
        stateManager:switch('dungeon')
    end

    -- Actualizar cámara para seguir al jugador
    self.cameraX = self.playerX - love.graphics.getWidth() / 2
    self.cameraY = self.playerY - love.graphics.getHeight() / 2
end

function HubState:checkNPCInteraction()
    local interactRadius = 60

    for _, npc in ipairs(self.npcs) do
        local dx = self.playerX - npc.x
        local dy = self.playerY - npc.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < interactRadius then
            print("Hablando con: " .. npc.name)
            print("Dialogo: " .. npc.dialogue)
            -- Aquí se abriría el sistema de diálogo
            break
        end
    end
end

function HubState:draw()
    love.graphics.setBackgroundColor(0.15, 0.18, 0.12)

    -- Aplicar cámara
    love.graphics.push()
    love.graphics.translate(-self.cameraX, -self.cameraY)

    -- Dibujar suelo (grid simple)
    love.graphics.setColor(0.2, 0.25, 0.2)
    for x = 0, 800, 50 do
        love.graphics.line(x, 0, x, 600)
    end
    for y = 0, 600, 50 do
        love.graphics.line(0, y, 800, y)
    end

    -- Dibujar NPCs
    for _, npc in ipairs(self.npcs) do
        -- Indicador de quest disponible
        if npc.questAvailable then
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle('fill', npc.x, npc.y - 40, 5)
        end

        -- Cuerpo del NPC
        love.graphics.setColor(0.5, 0.7, 0.9)
        love.graphics.circle('fill', npc.x, npc.y, 25)

        -- Nombre
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(npc.name, npc.x - 50, npc.y - 50, 100, 'center')
    end

    -- Dibujar jugador
    love.graphics.setColor(0.8, 0.4, 0.8)
    love.graphics.circle('fill', self.playerX, self.playerY, 20)

    -- Indicador de dirección
    local input = _G.Registry:get('input')
    local aimX, aimY = input:getAimDirection(self.playerX + self.cameraX, self.playerY + self.cameraY)
    love.graphics.setColor(1, 0.8, 1)
    love.graphics.line(
        self.playerX, self.playerY,
        self.playerX + aimX * 30, self.playerY + aimY * 30
    )

    love.graphics.pop()

    -- UI (sin cámara)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HUB - Pueblo", 10, 10)
    love.graphics.print("Presiona ESPACIO para ir al Dungeon (temporal)", 10, 30)
    love.graphics.print("Presiona E para interactuar con NPCs", 10, 50)
    love.graphics.print("WASD para moverte", 10, 70)
end

function HubState:keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        local stateManager = _G.Registry:get('state_manager')
        stateManager:switch('menu')
    end
end

return HubState
