-- src/ui/minimap.lua
-- Minimapa del dungeon procedural

local Minimap = {}
Minimap.__index = Minimap

function Minimap:new()
    local instance = {
        -- Configuración visual
        width = 200,
        height = 150,
        padding = 10,
        roomSize = 8,  -- Tamaño de cada habitación en el minimapa
        passageWidth = 2,
        
        -- Estado
        exploredRooms = {},  -- Set de habitaciones descubiertas
        currentRoom = nil,
        
        -- Posición en pantalla (esquina superior derecha)
        screenX = nil,  -- Se calcula en draw
        screenY = 10,
    }
    setmetatable(instance, self)
    return instance
end

-- Actualizar habitación actual
function Minimap:setCurrentRoom(room)
    if room then
        self.currentRoom = room
        self.exploredRooms[room] = true
    end
end

-- Marcar habitación como explorada
function Minimap:exploreRoom(room)
    if room then
        self.exploredRooms[room] = true
    end
end

-- Calcular bounds de todas las habitaciones para centrar el minimapa
function Minimap:calculateBounds(floor)
    if not floor or not floor.rooms or #floor.rooms == 0 then
        return 0, 0, 1, 1
    end
    
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    
    for _, room in ipairs(floor.rooms) do
        minX = math.min(minX, room.x)
        minY = math.min(minY, room.y)
        maxX = math.max(maxX, room.x + room.width)
        maxY = math.max(maxY, room.y + room.height)
    end
    
    return minX, minY, maxX, maxY
end

-- Dibujar el minimapa
function Minimap:draw(floor)
    if not floor then return end
    
    -- Calcular posición en pantalla (esquina superior derecha)
    local screenW = love.graphics.getWidth()
    self.screenX = screenW - self.width - self.padding
    
    -- Fondo del minimapa
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle('fill', self.screenX, self.screenY, self.width, self.height)
    
    -- Borde
    love.graphics.setColor(0.4, 0.4, 0.5, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', self.screenX, self.screenY, self.width, self.height)
    
    -- Título
    love.graphics.setColor(0.8, 0.8, 0.9, 1)
    love.graphics.print("MAP", self.screenX + 5, self.screenY + 2)
    
    -- Calcular bounds y escala
    local minX, minY, maxX, maxY = self:calculateBounds(floor)
    local dungeonW = maxX - minX
    local dungeonH = maxY - minY
    
    -- Determinar escala para que quepa todo
    local scaleX = (self.width - 20) / math.max(dungeonW, 20)
    local scaleY = (self.height - 30) / math.max(dungeonH, 20)
    local scale = math.min(scaleX, scaleY, self.roomSize)
    
    -- Offset para centrar
    local mapOffsetX = self.screenX + 10
    local mapOffsetY = self.screenY + 25
    
    -- Función para convertir coordenadas del mundo a minimapa
    local function worldToMinimap(x, y)
        return mapOffsetX + (x - minX) * scale,
               mapOffsetY + (y - minY) * scale
    end
    
    -- Dibujar conexiones (pasillos) entre habitaciones exploradas
    love.graphics.setLineWidth(self.passageWidth)
    for room, _ in pairs(self.exploredRooms) do
        for _, conn in ipairs(room.connections) do
            local targetRoom = conn.targetRoom
            if self.exploredRooms[targetRoom] then
                local x1, y1 = worldToMinimap(
                    room.x + room.width / 2,
                    room.y + room.height / 2
                )
                local x2, y2 = worldToMinimap(
                    targetRoom.x + targetRoom.width / 2,
                    targetRoom.y + targetRoom.height / 2
                )
                -- Color diferente si es la conexión actual
                if room == self.currentRoom or targetRoom == self.currentRoom then
                    love.graphics.setColor(0.6, 0.6, 0.7, 0.8)
                else
                    love.graphics.setColor(0.3, 0.3, 0.4, 0.6)
                end
                love.graphics.line(x1, y1, x2, y2)
            end
        end
    end
    
    -- Dibujar habitaciones
    for room, _ in pairs(self.exploredRooms) do
        local x, y = worldToMinimap(room.x, room.y)
        local w = room.width * scale
        local h = room.height * scale
        
        -- Color según tipo
        if room == self.currentRoom then
            -- Habitación actual (jugador) - brillante
            love.graphics.setColor(0.2, 0.8, 0.3, 1)
        elseif room.isEntrance then
            -- Entrada - azul
            love.graphics.setColor(0.3, 0.5, 0.9, 0.9)
        elseif room.isExit then
            -- Salida - rojo
            love.graphics.setColor(0.9, 0.3, 0.2, 0.9)
        elseif room.contentType == 'combat' then
            -- Combate - naranja
            love.graphics.setColor(0.8, 0.5, 0.2, 0.8)
        elseif room.contentType == 'treasure' then
            -- Tesoro - dorado
            love.graphics.setColor(0.9, 0.8, 0.2, 0.8)
        elseif room.contentType == 'boss' then
            -- Jefe - púrpura
            love.graphics.setColor(0.8, 0.2, 0.8, 0.9)
        else
            -- Vacía/otras - gris
            love.graphics.setColor(0.5, 0.5, 0.6, 0.7)
        end
        
        -- Dibujar habitación
        love.graphics.rectangle('fill', x, y, math.max(w, 4), math.max(h, 4))
        
        -- Borde
        love.graphics.setColor(0.2, 0.2, 0.25, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle('line', x, y, math.max(w, 4), math.max(h, 4))
        
        -- Dibujar puertas (entradas/salidas) en los bordes
        for _, conn in ipairs(room.connections) do
            local doorX, doorY = worldToMinimap(conn.myPoint.x, conn.myPoint.y)
            
            -- Determinar en qué borde está la puerta y dibujarla
            local doorSize = math.max(2, scale)
            
            -- La puerta está justo en el borde de la habitación
            -- Ajustar para que se vea en el borde del rectángulo
            local bx, by = doorX, doorY
            
            -- Color blanco para las puertas
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.rectangle('fill', bx - doorSize/2, by - doorSize/2, doorSize, doorSize)
        end
    end
    
    -- Leyenda
    love.graphics.setColor(0.7, 0.7, 0.8, 1)
    love.graphics.print("You", self.screenX + 5, self.screenY + self.height - 15)
    love.graphics.setColor(0.2, 0.8, 0.3, 1)
    love.graphics.rectangle('fill', self.screenX + 30, self.screenY + self.height - 13, 6, 6)
end

return Minimap
