-- spec/dungeon/room_state_spec.lua
-- Tests para sistema de estados de habitaciones

local Room = require('src.dungeon.room')

describe('Room State System', function()
  it('should initialize with idle state', function()
    local room = Room:new('1x1', 0, 0)
    assert.are.equal('idle', room.state)
  end)
  
  it('should initialize enemiesSpawned as false', function()
    local room = Room:new('1x1', 0, 0)
    assert.is_false(room.enemiesSpawned)
  end)
  
  it('should change state to active', function()
    local room = Room:new('1x1', 0, 0)
    room:setState('active')
    assert.are.equal('active', room.state)
  end)
  
  it('should change state to clear', function()
    local room = Room:new('1x1', 0, 0)
    room:setState('clear')
    assert.are.equal('clear', room.state)
  end)
  
  it('should not change to invalid state', function()
    local room = Room:new('1x1', 0, 0)
    room:setState('invalid_state')
    assert.are.equal('idle', room.state)  -- Debe mantener el estado anterior
  end)
  
  it('should allow spawning when idle and not spawned', function()
    local room = Room:new('1x1', 0, 0)
    assert.is_true(room:canSpawnEnemies())
  end)
  
  it('should not allow spawning when not idle', function()
    local room = Room:new('1x1', 0, 0)
    room:setState('active')
    assert.is_false(room:canSpawnEnemies())
  end)
  
  it('should not allow spawning when already spawned', function()
    local room = Room:new('1x1', 0, 0)
    room:markEnemiesSpawned()
    assert.is_false(room:canSpawnEnemies())
  end)
  
  it('should mark enemies as spawned', function()
    local room = Room:new('1x1', 0, 0)
    room:markEnemiesSpawned()
    assert.is_true(room.enemiesSpawned)
  end)
  
  it('should return true for all enemies dead when no enemies', function()
    local room = Room:new('1x1', 0, 0)
    assert.is_true(room:areAllEnemiesDead())
  end)
  
  it('should return false when enemies are alive', function()
    local room = Room:new('1x1', 0, 0)
    room.enemies = {
      { dead = false },
      { dead = false }
    }
    assert.is_false(room:areAllEnemiesDead())
  end)
  
  it('should return true when all enemies are dead', function()
    local room = Room:new('1x1', 0, 0)
    room.enemies = {
      { dead = true },
      { dead = true }
    }
    assert.is_true(room:areAllEnemiesDead())
  end)
  
  it('should return false when some enemies are alive', function()
    local room = Room:new('1x1', 0, 0)
    room.enemies = {
      { dead = true },
      { dead = false }
    }
    assert.is_false(room:areAllEnemiesDead())
  end)
end)
