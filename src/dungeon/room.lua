-- src/dungeon/room.lua
-- Clase Room: representa una habitación en el dungeon

local Room = {}
Room.__index = Room

-- Dimensiones en tiles para cada tipo de habitación
local ROOM_DIMENSIONS = {
  ['1x1'] = {width = 10, height = 10},
  ['2x1'] = {width = 20, height = 10},
  ['1x2'] = {width = 10, height = 20},
  ['2x2'] = {width = 20, height = 20},
}

function Room:new(roomType, x, y)
  local dims = ROOM_DIMENSIONS[roomType]
  if not dims then
    error("Invalid room type: " .. tostring(roomType))
  end
  
  local instance = {
    type = roomType,
    x = x or 0,
    y = y or 0,
    width = dims.width,
    height = dims.height,
    isEntrance = false,
    isExit = false,
    contentType = 'empty',
    connections = {},  -- Conexiones a otras habitaciones
    usedConnectionPoints = {},  -- Puntos de conexión ya utilizados
    isConfinementActive = false,
    state = 'idle',  -- Estados: 'idle', 'active', 'clear'
    enemiesSpawned = false,  -- Para evitar spawn múltiple
  }
  
  setmetatable(instance, self)
  return instance
end

-- Obtener puntos de conexión disponibles en los bordes
function Room:getConnectionPoints()
  local points = {}
  local tileSize = 10  -- 1 unidad = 10 tiles
  
  if self.type == '1x1' then
    -- 4 puntos: centro de cada lado
    table.insert(points, {x = self.x, y = self.y + self.height/2, dir = 'west'})
    table.insert(points, {x = self.x + self.width, y = self.y + self.height/2, dir = 'east'})
    table.insert(points, {x = self.x + self.width/2, y = self.y, dir = 'north'})
    table.insert(points, {x = self.x + self.width/2, y = self.y + self.height, dir = 'south'})
    
  elseif self.type == '2x1' then
    -- 6 puntos: 2 en cada largo, 1 en cada corto
    table.insert(points, {x = self.x, y = self.y + self.height/2, dir = 'west'})
    table.insert(points, {x = self.x + self.width, y = self.y + self.height/2, dir = 'east'})
    table.insert(points, {x = self.x + self.width/4, y = self.y, dir = 'north'})
    table.insert(points, {x = self.x + 3*self.width/4, y = self.y, dir = 'north'})
    table.insert(points, {x = self.x + self.width/4, y = self.y + self.height, dir = 'south'})
    table.insert(points, {x = self.x + 3*self.width/4, y = self.y + self.height, dir = 'south'})
    
  elseif self.type == '1x2' then
    -- 6 puntos: 1 en cada corto, 2 en cada largo
    table.insert(points, {x = self.x, y = self.y + self.height/4, dir = 'west'})
    table.insert(points, {x = self.x, y = self.y + 3*self.height/4, dir = 'west'})
    table.insert(points, {x = self.x + self.width, y = self.y + self.height/4, dir = 'east'})
    table.insert(points, {x = self.x + self.width, y = self.y + 3*self.height/4, dir = 'east'})
    table.insert(points, {x = self.x + self.width/2, y = self.y, dir = 'north'})
    table.insert(points, {x = self.x + self.width/2, y = self.y + self.height, dir = 'south'})
    
  elseif self.type == '2x2' then
    -- 8 puntos: 2 en cada lado
    table.insert(points, {x = self.x, y = self.y + self.height/4, dir = 'west'})
    table.insert(points, {x = self.x, y = self.y + 3*self.height/4, dir = 'west'})
    table.insert(points, {x = self.x + self.width, y = self.y + self.height/4, dir = 'east'})
    table.insert(points, {x = self.x + self.width, y = self.y + 3*self.height/4, dir = 'east'})
    table.insert(points, {x = self.x + self.width/4, y = self.y, dir = 'north'})
    table.insert(points, {x = self.x + 3*self.width/4, y = self.y, dir = 'north'})
    table.insert(points, {x = self.x + self.width/4, y = self.y + self.height, dir = 'south'})
    table.insert(points, {x = self.x + 3*self.width/4, y = self.y + self.height, dir = 'south'})
  end
  
  return points
end

-- Verificar colisión AABB con otra habitación
function Room:collidesWith(other)
  return self.x < other.x + other.width and
         self.x + self.width > other.x and
         self.y < other.y + other.height and
         self.y + self.height > other.y
end

-- Marcar como entrada
function Room:setAsEntrance()
  self.isEntrance = true
  self.isExit = false
end

-- Marcar como salida
function Room:setAsExit()
  self.isExit = true
  self.isEntrance = false
end

-- Establecer tipo de contenido
function Room:setContentType(contentType)
  local validTypes = {combat = true, puzzle = true, treasure = true, boss = true, empty = true}
  if not validTypes[contentType] then
    error("Invalid content type: " .. tostring(contentType))
  end
  self.contentType = contentType
end

-- Conectar con otra habitación
function Room:connectTo(otherRoom, myConnectionPoint, otherConnectionPoint)
  table.insert(self.connections, {
    targetRoom = otherRoom,
    myPoint = myConnectionPoint,
    otherPoint = otherConnectionPoint
  })
  -- Marcar el punto de conexión como usado
  self:markConnectionPointUsed(myConnectionPoint)
end

-- Marcar un punto de conexión como usado
function Room:markConnectionPointUsed(point)
  -- Usar una clave única basada en coordenadas (redondeadas para evitar problemas de precisión)
  local key = string.format("%.1f,%.1f", point.x, point.y)
  self.usedConnectionPoints[key] = true
end

-- Verificar si un punto de conexión ya fue usado
function Room:isConnectionPointUsed(point)
  local key = string.format("%.1f,%.1f", point.x, point.y)
  return self.usedConnectionPoints[key] == true
end

-- Obtener puntos de conexión disponibles (no usados)
function Room:getAvailableConnectionPoints()
  local allPoints = self:getConnectionPoints()
  local available = {}
  
  for _, point in ipairs(allPoints) do
    if not self:isConnectionPointUsed(point) then
      table.insert(available, point)
    end
  end
  
  return available
end

-- Verificar si dos habitaciones están lo suficientemente cerca para conectarse
-- Retorna el punto de conexión en esta habitación si están alineadas
function Room:canConnectTo(otherRoom, passageWidth)
  passageWidth = passageWidth or 2
  local tolerance = 2  -- Tolerancia de alineación en tiles
  
  local myPoints = self:getAvailableConnectionPoints()
  local otherPoints = otherRoom:getAvailableConnectionPoints()
  
  for _, myPoint in ipairs(myPoints) do
    for _, otherPoint in ipairs(otherPoints) do
      -- Verificar si los puntos están en direcciones opuestas
      local oppositeDirs = {
        north = 'south',
        south = 'north',
        east = 'west',
        west = 'east'
      }
      
      if oppositeDirs[myPoint.dir] == otherPoint.dir then
        -- Verificar si están alineados y cercanos
        local expectedDist = passageWidth
        local dx = math.abs(myPoint.x - otherPoint.x)
        local dy = math.abs(myPoint.y - otherPoint.y)
        
        -- Dependiendo de la dirección, verificar alineación
        local aligned = false
        if myPoint.dir == 'north' or myPoint.dir == 'south' then
          -- Alineación horizontal (misma X)
          aligned = dx <= tolerance and math.abs(dy - expectedDist) <= tolerance
        else
          -- Alineación vertical (misma Y)
          aligned = dy <= tolerance and math.abs(dx - expectedDist) <= tolerance
        end
        
        if aligned then
          return myPoint, otherPoint
        end
      end
    end
  end
  
  return nil, nil
end

-- Obtener centro de la habitación
function Room:getCenter()
  return {
    x = self.x + self.width / 2,
    y = self.y + self.height / 2
  }
end

-- Calcular distancia a otra habitación (centro a centro)
function Room:distanceTo(other)
  local c1 = self:getCenter()
  local c2 = other:getCenter()
  local dx = c2.x - c1.x
  local dy = c2.y - c1.y
  return math.sqrt(dx * dx + dy * dy)
end

-- Establecer estado de la habitación
function Room:setState(newState)
  if newState == 'idle' or newState == 'active' or newState == 'clear' then
    self.state = newState
  end
end

-- Verificar si la habitación puede spawnear enemigos
-- Solo spawnea si está en idle y no ha spawneado antes
function Room:canSpawnEnemies()
  return self.state == 'idle' and not self.enemiesSpawned
end

-- Marcar que los enemigos han sido spawneados
function Room:markEnemiesSpawned()
  self.enemiesSpawned = true
end

-- Verificar si todos los enemigos están muertos
function Room:areAllEnemiesDead()
  if not self.enemies or #self.enemies == 0 then
    return true
  end
  for _, enemy in ipairs(self.enemies) do
    if not enemy.dead then
      return false
    end
  end
  return true
end

return Room
