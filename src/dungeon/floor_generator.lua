-- src/dungeon/floor_generator.lua
-- Generador de pisos de dungeon usando grafo espacial de habitaciones

local Room = require('src.dungeon.room')

local FloorGenerator = {}
FloorGenerator.__index = FloorGenerator

function FloorGenerator:new(seed)
  local instance = {
    seed = seed or os.time(),
    rooms = {},
    placedRooms = {},
    availableConnections = {},
  }
  setmetatable(instance, self)
  
  -- Initialize random seed
  math.randomseed(instance.seed)
  
  return instance
end

-- Generar un piso completo
function FloorGenerator:generate(roomCount)
  self.rooms = {}
  self.placedRooms = {}
  self.availableConnections = {}
  
  -- Paso 1: Crear habitación de entrada (1x1 obligatoria)
  local entrance = Room:new('1x1', 0, 0)
  entrance:setAsEntrance()
  self:addRoom(entrance)
  
  -- Paso 2: Segunda habitación (1x1 o 2x1 obligatoria)
  local secondRoomType = math.random() < 0.5 and '1x1' or '2x1'
  self:placeConnectedRoom(secondRoomType)
  
  -- Paso 3: Generar resto de habitaciones
  local roomBudget = self:calculateRoomBudget(roomCount)
  
  while #self.placedRooms < roomCount and #self.availableConnections > 0 do
    local roomType = self:chooseRoomTypeFromBudget(roomBudget)
    if roomType then
      local success = self:placeConnectedRoom(roomType)
      if not success then
        -- Try a few more times with different connections
        local attempts = 0
        while not success and attempts < 5 and #self.availableConnections > 0 do
          roomType = self:chooseRoomTypeFromBudget(roomBudget)
          success = self:placeConnectedRoom(roomType)
          attempts = attempts + 1
        end
        
        if not success then
          break  -- No more valid placements
        end
      end
    else
      break  -- No more rooms in budget
    end
  end
  
  -- Paso 4: Marcar salida (1x1 más alejada de entrada)
  self:markExitRoom()
  
  -- Retornar objeto Floor
  return {
    rooms = self.placedRooms,
    entrance = entrance,
    seed = self.seed,
    
    getEntrance = function(self)
      for _, room in ipairs(self.rooms) do
        if room.isEntrance then return room end
      end
      return nil
    end,
    
    getExit = function(self)
      for _, room in ipairs(self.rooms) do
        if room.isExit then return room end
      end
      return nil
    end
  }
end

-- Calcular presupuesto de habitaciones por tipo
function FloorGenerator:calculateRoomBudget(totalRooms)
  -- Total = 1 (entrance) + 1 (second) + resto
  local remaining = totalRooms - 2
  
  return {
    ['2x2'] = 1,  -- Siempre una grande
    ['2x1'] = math.random(1, math.min(2, remaining)),
    ['1x2'] = math.random(1, math.min(2, remaining)),
    ['1x1'] = remaining,  -- El resto son 1x1
  }
end

-- Elegir tipo de habitación del presupuesto
function FloorGenerator:chooseRoomTypeFromBudget(budget)
  local availableTypes = {}
  
  for roomType, count in pairs(budget) do
    if count > 0 then
      table.insert(availableTypes, roomType)
    end
  end
  
  if #availableTypes == 0 then
    return nil
  end
  
  local chosen = availableTypes[math.random(1, #availableTypes)]
  budget[chosen] = budget[chosen] - 1
  
  return chosen
end

-- Agregar habitación al piso
function FloorGenerator:addRoom(room)
  table.insert(self.placedRooms, room)
  table.insert(self.rooms, room)
  
  -- Agregar sus puntos de conexión disponibles
  local connectionPoints = room:getConnectionPoints()
  for _, point in ipairs(connectionPoints) do
    table.insert(self.availableConnections, {
      room = room,
      point = point,
      used = false
    })
  end
end

-- Intentar colocar una habitación conectada
function FloorGenerator:placeConnectedRoom(roomType)
  if #self.availableConnections == 0 then
    return false
  end
  
  -- Elegir una conexión disponible al azar
  local connIndex = math.random(1, #self.availableConnections)
  local connection = self.availableConnections[connIndex]
  
  if connection.used then
    table.remove(self.availableConnections, connIndex)
    return self:placeConnectedRoom(roomType)
  end
  
  -- Calcular posición para la nueva habitación
  local parentRoom = connection.room
  local parentPoint = connection.point
  
  -- Calcular offset basado en dirección
  local offset = self:calculateOffset(parentPoint.dir, roomType)
  local newX = parentPoint.x + offset.x
  local newY = parentPoint.y + offset.y
  
  -- Crear nueva habitación
  local newRoom = Room:new(roomType, newX, newY)
  
  -- Verificar que no colisione
  for _, existingRoom in ipairs(self.placedRooms) do
    if newRoom:collidesWith(existingRoom) then
      -- Marcar esta conexión como bloqueada y reintentar
      connection.used = true
      return self:placeConnectedRoom(roomType)
    end
  end
  
  -- Colocar habitación
  self:addRoom(newRoom)
  
  -- Conectar las habitaciones (bidireccional)
  parentRoom:connectTo(newRoom, parentPoint, {x = newX, y = newY})
  newRoom:connectTo(parentRoom, {x = newX, y = newY}, parentPoint)
  
  -- Marcar conexión como usada
  connection.used = true
  table.remove(self.availableConnections, connIndex)
  
  return true
end

-- Calcular offset basado en dirección
function FloorGenerator:calculateOffset(direction, roomType)
  local offsets = {
    north = {x = 0, y = -10},
    south = {x = 0, y = 10},
    east = {x = 10, y = 0},
    west = {x = -10, y = 0},
  }
  
  -- Ajustar según tamaño de la habitación nueva
  local roomDims = {
    ['1x1'] = {w = 10, h = 10},
    ['2x1'] = {w = 20, h = 10},
    ['1x2'] = {w = 10, h = 20},
    ['2x2'] = {w = 20, h = 20},
  }
  
  local dims = roomDims[roomType]
  local baseOffset = offsets[direction] or {x = 0, y = 0}
  
  -- Ajustar para que las habitaciones queden alineadas
  if direction == 'north' then
    return {x = -dims.w/2, y = -dims.h}
  elseif direction == 'south' then
    return {x = -dims.w/2, y = 0}
  elseif direction == 'east' then
    return {x = 0, y = -dims.h/2}
  elseif direction == 'west' then
    return {x = -dims.w, y = -dims.h/2}
  end
  
  return {x = 0, y = 0}
end

-- Marcar habitación de salida
function FloorGenerator:markExitRoom()
  local entrance = nil
  local candidates = {}
  
  -- Encontrar entrada y candidatos (1x1 que no sean entrada)
  for _, room in ipairs(self.placedRooms) do
    if room.isEntrance then
      entrance = room
    elseif room.type == '1x1' and not room.isEntrance then
      table.insert(candidates, room)
    end
  end
  
  if #candidates == 0 then
    -- Si no hay candidatos, usar cualquier 1x1
    for _, room in ipairs(self.placedRooms) do
      if room.type == '1x1' then
        room:setAsExit()
        return
      end
    end
    return
  end
  
  -- Elegir la más alejada de la entrada
  local farthest = candidates[1]
  local maxDistance = entrance:distanceTo(farthest)
  
  for i = 2, #candidates do
    local distance = entrance:distanceTo(candidates[i])
    if distance > maxDistance then
      maxDistance = distance
      farthest = candidates[i]
    end
  end
  
  farthest:setAsExit()
end

return FloorGenerator
