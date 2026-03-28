-- spec/ui/minimap_spec.lua
-- Tests para Minimap

local Minimap = require('src.ui.minimap')
local Room = require('src.dungeon.room')

describe('Minimap', function()
  it('should create with default settings', function()
    local minimap = Minimap:new()
    
    assert.are.equal(200, minimap.width)
    assert.are.equal(150, minimap.height)
    assert.are.equal(10, minimap.padding)
  end)
  
  it('should set current room', function()
    local minimap = Minimap:new()
    local room = Room:new('1x1', 0, 0)
    
    minimap:setCurrentRoom(room)
    
    assert.are.equal(room, minimap.currentRoom)
    assert.is_true(minimap.exploredRooms[room])
  end)
  
  it('should explore room', function()
    local minimap = Minimap:new()
    local room = Room:new('1x1', 0, 0)
    
    minimap:exploreRoom(room)
    
    assert.is_true(minimap.exploredRooms[room])
  end)
  
  it('should calculate bounds for single room', function()
    local minimap = Minimap:new()
    local floor = {
      rooms = {
        Room:new('1x1', 0, 0)
      }
    }
    
    local minX, minY, maxX, maxY = minimap:calculateBounds(floor)
    
    assert.are.equal(0, minX)
    assert.are.equal(0, minY)
    assert.are.equal(10, maxX)
    assert.are.equal(10, maxY)
  end)
  
  it('should calculate bounds for multiple rooms', function()
    local minimap = Minimap:new()
    local floor = {
      rooms = {
        Room:new('1x1', 0, 0),
        Room:new('1x1', 20, 30)
      }
    }
    
    local minX, minY, maxX, maxY = minimap:calculateBounds(floor)
    
    assert.are.equal(0, minX)
    assert.are.equal(0, minY)
    assert.are.equal(30, maxX)  -- 20 + 10
    assert.are.equal(40, maxY)  -- 30 + 10
  end)
  
  it('should handle nil floor', function()
    local minimap = Minimap:new()
    
    local minX, minY, maxX, maxY = minimap:calculateBounds(nil)
    
    assert.are.equal(0, minX)
    assert.are.equal(0, minY)
    assert.are.equal(1, maxX)
    assert.are.equal(1, maxY)
  end)
  
  it('should track multiple explored rooms', function()
    local minimap = Minimap:new()
    local room1 = Room:new('1x1', 0, 0)
    local room2 = Room:new('1x1', 20, 0)
    
    minimap:exploreRoom(room1)
    minimap:exploreRoom(room2)
    
    assert.is_true(minimap.exploredRooms[room1])
    assert.is_true(minimap.exploredRooms[room2])
  end)
  
  it('should update current room and mark as explored', function()
    local minimap = Minimap:new()
    local room1 = Room:new('1x1', 0, 0)
    local room2 = Room:new('1x1', 20, 0)
    
    minimap:setCurrentRoom(room1)
    assert.are.equal(room1, minimap.currentRoom)
    assert.is_true(minimap.exploredRooms[room1])
    
    minimap:setCurrentRoom(room2)
    assert.are.equal(room2, minimap.currentRoom)
    assert.is_true(minimap.exploredRooms[room2])
  end)
end)
