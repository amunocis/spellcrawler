-- spec/dungeon/room_spec.lua
-- Tests para la clase Room

local Room = require('src.dungeon.room')

describe('Room', function()
  describe('creation', function()
    it('should create a 1x1 room', function()
      local room = Room:new('1x1', 0, 0)
      
      assert.are.equal('1x1', room.type)
      assert.are.equal(0, room.x)
      assert.are.equal(0, room.y)
      assert.are.equal(10, room.width)   -- 1x1 = 10 tiles
      assert.are.equal(10, room.height)
    end)
    
    it('should create a 2x1 room', function()
      local room = Room:new('2x1', 0, 0)
      
      assert.are.equal('2x1', room.type)
      assert.are.equal(20, room.width)   -- 2x1 = 20x10 tiles
      assert.are.equal(10, room.height)
    end)
    
    it('should create a 1x2 room', function()
      local room = Room:new('1x2', 0, 0)
      
      assert.are.equal('1x2', room.type)
      assert.are.equal(10, room.width)   -- 1x2 = 10x20 tiles
      assert.are.equal(20, room.height)
    end)
    
    it('should create a 2x2 room', function()
      local room = Room:new('2x2', 0, 0)
      
      assert.are.equal('2x2', room.type)
      assert.are.equal(20, room.width)   -- 2x2 = 20x20 tiles
      assert.are.equal(20, room.height)
    end)
  end)
  
  describe('connection points', function()
    it('1x1 should have 4 connection points', function()
      local room = Room:new('1x1', 0, 0)
      local connections = room:getConnectionPoints()
      
      assert.are.equal(4, #connections)
    end)
    
    it('2x1 should have 6 connection points', function()
      local room = Room:new('2x1', 0, 0)
      local connections = room:getConnectionPoints()
      
      assert.are.equal(6, #connections)
    end)
    
    it('2x2 should have 8 connection points', function()
      local room = Room:new('2x2', 0, 0)
      local connections = room:getConnectionPoints()
      
      assert.are.equal(8, #connections)
    end)
    
    it('connection points should be on edges', function()
      local room = Room:new('1x1', 10, 10)
      local connections = room:getConnectionPoints()
      
      -- Check that points are on the edges
      for _, conn in ipairs(connections) do
        local onEdge = (conn.x == 10 or conn.x == 20 or 
                       conn.y == 10 or conn.y == 20)
        assert.is_true(onEdge)
      end
    end)
  end)
  
  describe('collision detection', function()
    it('should detect collision with another room', function()
      local room1 = Room:new('1x1', 0, 0)
      local room2 = Room:new('1x1', 5, 5)  -- Overlapping
      
      assert.is_true(room1:collidesWith(room2))
    end)
    
    it('should not detect collision when rooms are separate', function()
      local room1 = Room:new('1x1', 0, 0)
      local room2 = Room:new('1x1', 20, 20)  -- Far apart
      
      assert.is_false(room1:collidesWith(room2))
    end)
    
    it('should not detect collision when rooms are adjacent', function()
      local room1 = Room:new('1x1', 0, 0)
      local room2 = Room:new('1x1', 10, 0)  -- Adjacent, not overlapping
      
      assert.is_false(room1:collidesWith(room2))
    end)
  end)
  
  describe('entrance/exit marking', function()
    it('should mark room as entrance', function()
      local room = Room:new('1x1', 0, 0)
      room:setAsEntrance()
      
      assert.is_true(room.isEntrance)
      assert.is_false(room.isExit)
    end)
    
    it('should mark room as exit', function()
      local room = Room:new('1x1', 0, 0)
      room:setAsExit()
      
      assert.is_true(room.isExit)
      assert.is_false(room.isEntrance)
    end)
  end)
  
  describe('content type', function()
    it('should set content type', function()
      local room = Room:new('1x1', 0, 0)
      room:setContentType('combat')
      
      assert.are.equal('combat', room.contentType)
    end)
    
    it('should accept valid content types', function()
      local room = Room:new('1x1', 0, 0)
      local validTypes = {'combat', 'puzzle', 'treasure', 'boss', 'empty'}
      
      for _, type in ipairs(validTypes) do
        room:setContentType(type)
        assert.are.equal(type, room.contentType)
      end
    end)
  end)
end)
