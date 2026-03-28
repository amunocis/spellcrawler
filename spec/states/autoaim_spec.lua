-- spec/states/autoaim_spec.lua
-- Tests para sistema de autoaim con gamepad

local DungeonState = require('src.states.dungeon_state')

describe('Autoaim System', function()
  local state
  local mockEnemies

  before_each(function()
    state = DungeonState:new()
    state.player = {x = 400, y = 300, w = 20, h = 20}
    state.cameraX = 0
    state.cameraY = 0
    
    -- Mock combatSystem con enemigos (con health)
    mockEnemies = {
      {transform = {x = 500, y = 300}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}, -- derecha, dist ~100
      {transform = {x = 300, y = 300}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}, -- izquierda, dist ~100
      {transform = {x = 400, y = 100}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}, -- arriba, dist ~200
    }
    state.combatSystem = {enemies = mockEnemies}
  end)

  describe('findNearestEnemy', function()
    it('should return nil when no enemies', function()
      state.combatSystem.enemies = {}
      local nearest = state:findNearestEnemy()
      assert.is_nil(nearest)
    end)

    it('should return nil when all enemies are dead', function()
      state.combatSystem.enemies = {
        {transform = {x = 500, y = 300}, dead = true, collider = {w = 16, h = 16}, health = {current = 0, max = 20}},
      }
      local nearest = state:findNearestEnemy()
      assert.is_nil(nearest)
    end)

    it('should find nearest enemy to the right', function()
      state.combatSystem.enemies = {
        {transform = {x = 500, y = 300}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}, -- dist ~100
        {transform = {x = 600, y = 300}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}, -- dist ~200
      }
      local nearest = state:findNearestEnemy()
      assert.are.equal(500, nearest.transform.x)
    end)

    it('should find nearest enemy above', function()
      state.combatSystem.enemies = {
        {transform = {x = 400, y = 100}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}, -- dist ~200
        {transform = {x = 400, y = 250}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}, -- dist ~50
      }
      local nearest = state:findNearestEnemy()
      assert.are.equal(400, nearest.transform.x)
      assert.are.equal(250, nearest.transform.y)
    end)

    it('should ignore dead enemies', function()
      state.combatSystem.enemies = {
        {transform = {x = 420, y = 300}, dead = true, collider = {w = 16, h = 16}, health = {current = 0, max = 20}},  -- closest but dead
        {transform = {x = 500, y = 300}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}, -- should find this
      }
      local nearest = state:findNearestEnemy()
      assert.are.equal(500, nearest.transform.x)
    end)
  end)

  describe('getAimDirectionWithAutoaim', function()
    it('should use right stick when active', function()
      local mockInput = {
        getAnalogAim = function() return 0.8, 0 end,
        isGamepadConnected = function() return true end
      }
      
      -- Mock the registry
      local originalRegistry = _G.Registry
      _G.Registry = {
        get = function() return mockInput end
      }
      
      local aimX, aimY, isAutoaim = state:getAimDirectionWithAutoaim()
      
      assert.are.equal(0.8, aimX)
      assert.are.equal(0, aimY)
      assert.is_false(isAutoaim)
      
      _G.Registry = originalRegistry
    end)

    it('should use autoaim when right stick inactive and gamepad connected', function()
      -- Asegurar que hay enemigos cerca (con health)
      state.combatSystem.enemies = {
        {transform = {x = 500, y = 300}, dead = false, collider = {w = 16, h = 16, offsetX = 8, offsetY = 8}, health = {current = 20, max = 20}}
      }
      
      local mockInput = {
        getAnalogAim = function() return 0, 0 end,
        isGamepadConnected = function() return true end
      }
      
      local originalRegistry = _G.Registry
      _G.Registry = {
        get = function() return mockInput end
      }
      
      local aimX, aimY, isAutoaim = state:getAimDirectionWithAutoaim()
      
      -- Should aim at nearest enemy (to the right at x=500)
      assert.is_true(aimX > 0, "aimX should be positive, got: " .. tostring(aimX))
      assert.is_true(isAutoaim, "isAutoaim should be true")
      
      _G.Registry = originalRegistry
    end)

    it('should default to right when no enemies and no stick input', function()
      state.combatSystem.enemies = {}
      
      local mockInput = {
        getAnalogAim = function() return 0, 0 end,
        isGamepadConnected = function() return true end
      }
      
      local originalRegistry = _G.Registry
      _G.Registry = {
        get = function() return mockInput end
      }
      
      local aimX, aimY, isAutoaim = state:getAimDirectionWithAutoaim()
      
      assert.are.equal(1, aimX)
      assert.are.equal(0, aimY)
      assert.is_false(isAutoaim)
      
      _G.Registry = originalRegistry
    end)

    it('should not use autoaim when no gamepad connected', function()
      local mockInput = {
        getAnalogAim = function() return 0, 0 end,
        isGamepadConnected = function() return false end
      }
      
      local originalRegistry = _G.Registry
      _G.Registry = {
        get = function() return mockInput end
      }
      
      local aimX, aimY, isAutoaim = state:getAimDirectionWithAutoaim()
      
      -- Without gamepad, should default to right
      assert.are.equal(1, aimX)
      assert.are.equal(0, aimY)
      assert.is_false(isAutoaim)
      
      _G.Registry = originalRegistry
    end)
  end)
end)
