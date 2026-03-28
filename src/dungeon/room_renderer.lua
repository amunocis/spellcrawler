-- src/dungeon/room_renderer.lua
-- Renderiza una habitación como tiles visibles

local RoomRenderer = {}
RoomRenderer.__index = RoomRenderer

-- Tamaño de tile en píxeles
local TILE_SIZE = 40

function RoomRenderer:new()
  local instance = {}
  setmetatable(instance, self)
  return instance
end

-- Generar grid de tiles para una habitación
function RoomRenderer:generateTiles(room, theme)
  theme = theme or 'cavern'
  
  local tiles = {}
  local gridWidth = room.width
  local gridHeight = room.height
  
  -- Inicializar todo como suelo
  for y = 1, gridHeight do
    tiles[y] = {}
    for x = 1, gridWidth do
      tiles[y][x] = 'floor'
    end
  end
  
  -- Crear paredes en los bordes
  for y = 1, gridHeight do
    for x = 1, gridWidth do
      -- Es borde?
      local isBorder = (x == 1 or x == gridWidth or y == 1 or y == gridHeight)
      
      if isBorder then
        -- Verificar si es una conexión (puerta)
        local isConnection = self:isConnectionPoint(room, x, y)
        
        if isConnection then
          tiles[y][x] = 'door'
        else
          tiles[y][x] = 'wall'
        end
      end
    end
  end
  
  -- Agregar obstáculos decorativos (procedural ligero)
  self:addObstacles(tiles, gridWidth, gridHeight, theme)
  
  return tiles
end

-- Verificar si una posición es punto de conexión real (conectada a otra habitación)
function RoomRenderer:isConnectionPoint(room, x, y)
  -- Convertir coordenadas locales a coordenadas de mundo
  local worldX = room.x + (x - 1)  -- x es 1-based local
  local worldY = room.y + (y - 1)  -- y es 1-based local
  
  -- Revisar conexiones REALES de la habitación (no potenciales)
  for _, conn in ipairs(room.connections) do
    local px = conn.myPoint.x
    local py = conn.myPoint.y
    
    -- Puerta de 2 tiles de ancho (tolerancia de 1 tile en cada dirección)
    if math.abs(worldX - px) <= 1 and math.abs(worldY - py) <= 1 then
      return true
    end
  end
  
  return false
end

-- Agregar obstáculos decorativos
function RoomRenderer:addObstacles(tiles, width, height, theme)
  math.randomseed(os.time())
  
  -- Cantidad de obstáculos según tema
  local obstacleCount = math.random(2, 5)
  
  for i = 1, obstacleCount do
    -- Posición aleatoria (no en bordes)
    local x = math.random(3, width - 2)
    local y = math.random(3, height - 2)
    
    -- Tipo de obstáculo
    local obstacleType = math.random() < 0.7 and 'rock' or 'pillar'
    
    -- Colocar obstáculo (1x1 o 2x2)
    if obstacleType == 'rock' then
      tiles[y][x] = 'rock'
    else
      -- Pilar 2x2 si cabe
      if x < width - 2 and y < height - 2 then
        tiles[y][x] = 'pillar'
        tiles[y][x+1] = 'pillar'
        tiles[y+1][x] = 'pillar'
        tiles[y+1][x+1] = 'pillar'
      else
        tiles[y][x] = 'pillar'
      end
    end
  end
end

-- Convertir tiles a objetos de colisión para bump
function RoomRenderer:createCollisionObjects(room, tiles)
  local objects = {}
  local tileSize = TILE_SIZE
  
  for y = 1, #tiles do
    for x = 1, #tiles[1] do
      local tile = tiles[y][x]
      
      if tile == 'wall' or tile == 'rock' or tile == 'pillar' then
        table.insert(objects, {
          x = room.x * tileSize + (x - 1) * tileSize,
          y = room.y * tileSize + (y - 1) * tileSize,
          w = tileSize,
          h = tileSize,
          type = tile
        })
      end
    end
  end
  
  return objects
end

-- Dibujar una habitación
function RoomRenderer:draw(room, tiles, cameraX, cameraY)
  local tileSize = TILE_SIZE
  
  for y = 1, #tiles do
    for x = 1, #tiles[1] do
      local tile = tiles[y][x]
      local screenX = room.x * tileSize + (x - 1) * tileSize - cameraX
      local screenY = room.y * tileSize + (y - 1) * tileSize - cameraY
      
      -- Color según tipo de tile
      if tile == 'floor' then
        love.graphics.setColor(0.2, 0.2, 0.25)
      elseif tile == 'wall' then
        love.graphics.setColor(0.4, 0.35, 0.3)
      elseif tile == 'door' then
        love.graphics.setColor(0.6, 0.4, 0.2)
      elseif tile == 'rock' then
        love.graphics.setColor(0.35, 0.3, 0.25)
      elseif tile == 'pillar' then
        love.graphics.setColor(0.5, 0.45, 0.4)
      end
      
      love.graphics.rectangle('fill', screenX, screenY, tileSize, tileSize)
      
      -- Borde sutil
      love.graphics.setColor(0.15, 0.15, 0.2)
      love.graphics.rectangle('line', screenX, screenY, tileSize, tileSize)
    end
  end
end

-- Obtener posición de spawn del jugador (centro de habitación de entrada)
function RoomRenderer:getPlayerSpawn(room)
  local tileSize = TILE_SIZE
  local center = room:getCenter()
  
  return {
    x = center.x * tileSize,
    y = center.y * tileSize
  }
end

-- Obtener posiciones válidas para spawn de enemigos
function RoomRenderer:getEnemySpawnPoints(room, tiles)
  local points = {}
  local tileSize = TILE_SIZE
  
  for y = 3, #tiles - 2 do  -- Evitar bordes
    for x = 3, #tiles[1] - 2 do
      if tiles[y][x] == 'floor' then
        table.insert(points, {
          x = room.x * tileSize + (x - 1) * tileSize + tileSize / 2,
          y = room.y * tileSize + (y - 1) * tileSize + tileSize / 2
        })
      end
    end
  end
  
  return points
end

return RoomRenderer
