-- spec/dungeon/confinement_spec.lua
-- Tests para sistema de confinamiento de habitaciones

local Room = require('src.dungeon.room')

describe('Room Confinement', function()
  it('should have confinement flag initialized to false', function()
    local room = Room:new('1x1', 0, 0)
    assert.is_false(room.isConfinementActive)
  end)
  
  it('should track enemies list', function()
    local room = Room:new('1x1', 0, 0)
    assert.is_nil(room.enemies)
    
    room.enemies = {}
    assert.is_table(room.enemies)
  end)
  
  it('should track confinement blocks', function()
    local room = Room:new('1x1', 0, 0)
    assert.is_nil(room.confinementBlocks)
    
    room.confinementBlocks = {}
    assert.is_table(room.confinementBlocks)
  end)
  
  it('should identify combat rooms', function()
    local room = Room:new('1x1', 0, 0)
    room:setContentType('combat')
    assert.are.equal('combat', room.contentType)
  end)
  
  it('should identify boss rooms', function()
    local room = Room:new('1x1', 0, 0)
    room:setContentType('boss')
    assert.are.equal('boss', room.contentType)
  end)
  
  it('should not confine empty rooms', function()
    local room = Room:new('1x1', 0, 0)
    room:setContentType('empty')
    assert.are.equal('empty', room.contentType)
  end)
  
  it('should not confine treasure rooms', function()
    local room = Room:new('1x1', 0, 0)
    room:setContentType('treasure')
    assert.are.equal('treasure', room.contentType)
  end)
end)
