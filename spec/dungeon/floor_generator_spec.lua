-- spec/dungeon/floor_generator_spec.lua
-- Tests para FloorGenerator

local FloorGenerator = require('src.dungeon.floor_generator')
local Room = require('src.dungeon.room')

describe('FloorGenerator', function()
  describe('basic generation', function()
    it('should generate floor with entrance room', function()
      local generator = FloorGenerator:new()
      local floor = generator:generate(8)  -- 8 rooms
      
      -- Find entrance room
      local entrance = nil
      for _, room in ipairs(floor.rooms) do
        if room.isEntrance then
          entrance = room
          break
        end
      end
      
      assert.is_not_nil(entrance)
      assert.are.equal('1x1', entrance.type)
    end)
    
    it('should generate floor with exit room', function()
      local generator = FloorGenerator:new()
      local floor = generator:generate(8)
      
      local exitRoom = nil
      for _, room in ipairs(floor.rooms) do
        if room.isExit then
          exitRoom = room
          break
        end
      end
      
      assert.is_not_nil(exitRoom)
      assert.are.equal('1x1', exitRoom.type)
    end)
    
    it('should generate correct number of rooms', function()
      local generator = FloorGenerator:new()
      local roomCount = 8
      local floor = generator:generate(roomCount)
      
      assert.are.equal(roomCount, #floor.rooms)
    end)
    
    it('second room should be 1x1 or 2x1', function()
      local generator = FloorGenerator:new()
      local floor = generator:generate(8)
      
      -- Find entrance and its connected room
      local entrance = floor:getEntrance()
      local secondRoom = nil
      
      for _, conn in ipairs(entrance.connections) do
        secondRoom = conn.targetRoom
        break
      end
      
      assert.is_not_nil(secondRoom)
      assert.is_true(secondRoom.type == '1x1' or secondRoom.type == '2x1')
    end)
  end)
  
  describe('room placement', function()
    it('should not have overlapping rooms', function()
      local generator = FloorGenerator:new()
      local floor = generator:generate(8)
      
      for i = 1, #floor.rooms do
        for j = i + 1, #floor.rooms do
          assert.is_false(floor.rooms[i]:collidesWith(floor.rooms[j]))
        end
      end
    end)
    
    it('should have all rooms connected', function()
      local generator = FloorGenerator:new()
      local floor = generator:generate(8)
      
      -- Check that every room (except entrance) has at least one connection
      for _, room in ipairs(floor.rooms) do
        if not room.isEntrance then
          assert.is_true(#room.connections > 0 or room.isExit)
        end
      end
    end)
  end)
  
  describe('exit placement', function()
    it('exit should be far from entrance', function()
      local generator = FloorGenerator:new()
      local floor = generator:generate(10)  -- More rooms for better distribution
      
      local entrance = floor:getEntrance()
      local exitRoom = floor:getExit()
      
      local distance = entrance:distanceTo(exitRoom)
      
      -- Exit should be reasonably far from entrance
      assert.is_true(distance > 20)  -- At least 2 rooms away
    end)
  end)
  
  describe('determinism', function()
    it('should generate same floor with same seed', function()
      local generator1 = FloorGenerator:new(12345)
      local floor1 = generator1:generate(8)
      
      local generator2 = FloorGenerator:new(12345)
      local floor2 = generator2:generate(8)
      
      -- Same number of rooms
      assert.are.equal(#floor1.rooms, #floor2.rooms)
      
      -- Same room types in same order
      for i = 1, #floor1.rooms do
        assert.are.equal(floor1.rooms[i].type, floor2.rooms[i].type)
      end
    end)
  end)
  
  describe('multiple connections', function()
    it('rooms can have multiple connections', function()
      local generator = FloorGenerator:new()
      local floor = generator:generate(10)  -- More rooms = more chance of multiple connections
      
      -- Find at least one room with multiple connections
      local multiConnectionRoom = nil
      for _, room in ipairs(floor.rooms) do
        if #room.connections >= 2 then
          multiConnectionRoom = room
          break
        end
      end
      
      -- With 10 rooms and nearby connection logic, we should have rooms with 2+ connections
      assert.is_not_nil(multiConnectionRoom, "Should have at least one room with multiple connections")
    end)
    
    it('every room should have at least one door', function()
      local generator = FloorGenerator:new()
      local floor = generator:generate(8)
      
      -- Every room should have at least one connection (door)
      for _, room in ipairs(floor.rooms) do
        assert.is_true(#room.connections >= 1, 
          "Room at (" .. room.x .. "," .. room.y .. ") should have at least one connection")
      end
    end)
    
    it('every room must have at least 1 connection - no isolated rooms', function()
      -- Test exhaustivo: verificar 100 generaciones con diferentes tamaños
      for seed = 1, 100 do
        for roomCount = 5, 12 do
          local generator = FloorGenerator:new(seed * 997 + roomCount)
          local floor = generator:generate(roomCount)
          
          -- Verificar que se generaron todas las habitaciones
          assert.are.equal(roomCount, #floor.rooms, 
            string.format("Expected %d rooms but got %d (seed=%d)", roomCount, #floor.rooms, seed))
          
          -- Verificar que cada habitación tiene al menos 1 conexión
          for _, room in ipairs(floor.rooms) do
            if #room.connections == 0 then
              error(string.format(
                "Room without doors! Type: %s, Pos: (%d, %d), Rooms: %d, Seed: %d",
                room.type, room.x, room.y, roomCount, seed * 997 + roomCount
              ))
            end
          end
        end
      end
    end)
  end)
end)
