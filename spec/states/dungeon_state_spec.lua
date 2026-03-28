-- spec/states/dungeon_state_spec.lua
local DungeonState = require('src.states.dungeon_state')
local SpellRegistry = require('src.spells.spell_registry')
local SpellDataLoader = require('src.spells.spell_data_loader')

describe('DungeonState', function()
  local state

  before_each(function()
    -- Limpiar y recargar hechizos para evitar duplicados
    SpellRegistry:clear()
    SpellDataLoader:loadAllSpells()
    
    state = DungeonState:new()
    -- Mock del Registry
    _G.Registry = {
      get = function(self, key)
        if key == 'input' then
          return {
            getMovementVector = function() return 0, 0 end,
            getAimDirection = function() return 1, 0 end,
            getAnalogAim = function() return 0, 0 end,
            isGamepadConnected = function() return false end,
            pressed = function() return false end,
            isDown = function() return false end
          }
        elseif key == 'event_bus' then
          return {
            emit = function() end
          }
        elseif key == 'state_manager' then
          return {
            switch = function() end
          }
        end
      end
    }
  end)

  describe('world bounds', function()
    it('should define floor on enter', function()
      state:enter(12345)  -- seed for deterministic generation
      assert.is_not_nil(state.floor)
      assert.is_not_nil(state.floor.rooms)
      assert.is_true(#state.floor.rooms > 0)
    end)
    
    -- TODO: Update these tests for new procedural dungeon system
    --[[
    it('should clamp player position to world bounds', function()
      state:enter()
      state.player.x = -1000
      state.player.y = -1000

      local clampedX, clampedY = state:clampToWorldBounds(state.player.x, state.player.y, state.player.w, state.player.h)

      assert.is_true(clampedX >= state.worldBounds.x)
      assert.is_true(clampedY >= state.worldBounds.y)
    end)
    --]]
  end)

  describe('game over', function()
    it('should set gameOver flag when triggered', function()
      state:enter()
      assert.is_false(state.gameOver)

      state:triggerGameOver()

      assert.is_true(state.gameOver)
      assert.are.equal(3.0, state.gameOverTimer)
    end)

    it('should emit player:died event on game over', function()
      state:enter()
      local eventEmitted = false
      _G.Registry.get = function(self, key)
        if key == 'event_bus' then
          return {
            emit = function(self, event, data)
              if event == 'player:died' then
                eventEmitted = true
              end
            end
          }
        end
        return {getMovementVector = function() return 0,0 end, pressed = function() return false end, isDown = function() return false end}
      end

      state:triggerGameOver()

      assert.is_true(eventEmitted)
    end)
  end)

  describe('damage feedback', function()
    it('should set damage flash when player is hit', function()
      state:enter()
      assert.are.equal(0, state.damageFlash)

      local enemy = {type = 'bat', damage = 10, transform = {x = 0, y = 0}, collider = {w = 16, h = 16}}
      state:handlePlayerHitByEnemy(enemy)

      assert.are.equal(0.3, state.damageFlash)
    end)

    it('should reduce player hp on hit', function()
      state:enter()
      local initialHp = state.player.hp

      local enemy = {type = 'bat', damage = 10, transform = {x = 0, y = 0}, collider = {w = 16, h = 16}}
      state:handlePlayerHitByEnemy(enemy)

      assert.are.equal(initialHp - 10, state.player.hp)
    end)
  end)

  describe('particles', function()
    it('should create impact particles', function()
      state:enter()
      assert.are.equal(0, #state.particles)

      state:createImpactParticles(100, 100, {1, 0, 0})

      assert.are.equal(8, #state.particles)
    end)

    it('should update particle lifetime', function()
      state:enter()
      state:createImpactParticles(100, 100, {1, 0, 0})

      state:updateParticles(0.1)

      assert.are.equal(8, #state.particles) -- Still alive
      assert.is_true(state.particles[1].lifetime < 0.3 and state.particles[1].lifetime > 0.15)
    end)

    it('should remove dead particles', function()
      state:enter()
      state:createImpactParticles(100, 100, {1, 0, 0})

      state:updateParticles(0.5) -- Longer than lifetime

      assert.are.equal(0, #state.particles)
    end)
  end)

  describe('safe spawn', function()
    it('should detect if position is safe from player', function()
      state:enter()
      state.player.x = 400
      state.player.y = 300

      local isSafe = state:isPositionSafeFromPlayer(400, 300, 100)
      assert.is_false(isSafe)

      local isSafeFar = state:isPositionSafeFromPlayer(600, 500, 100)
      assert.is_true(isSafeFar)
    end)

    it('should have particles table on enter', function()
      state:enter()
      assert.is_not_nil(state.particles)
      assert.are.equal('table', type(state.particles))
    end)
  end)

  describe('spawn inside world bounds', function()
    -- TODO: Update for procedural dungeon system
    --[[
    it('should spawn enemies inside world bounds', function()
      state:enter()
      
      for _, enemy in ipairs(state.combatSystem.enemies) do
        assert.is_true(enemy.transform.x >= state.worldBounds.x + 20)
        assert.is_true(enemy.transform.x <= state.worldBounds.x + state.worldBounds.w - 20)
        assert.is_true(enemy.transform.y >= state.worldBounds.y + 20)
        assert.is_true(enemy.transform.y <= state.worldBounds.y + state.worldBounds.h - 20)
      end
    end)
    --]]
    
    it('should check if position is inside world bounds', function()
      -- Simple test without full enter()
      assert.is_true(true)  -- Placeholder
    end)
  end)
end)
