-- spec/enemies/behaviors/chase_behavior_focus_spec.lua
-- Tests para sistema de detección en dos etapas (detection + focus)

local ChaseBehavior = require('src.enemies.behaviors.chase_behavior')

describe('ChaseBehavior Focus System', function()
  describe('detection phases', function()
    it('should not chase when target is outside detection radius and not focused', function()
      local behavior = ChaseBehavior:new(150, 30, 400) -- detect=150, focus=400
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      local target = { x = 200, y = 0 } -- Outside detection (200 > 150)
      local dt = 0.1

      behavior:update(enemy, target, dt)

      -- Should not have moved
      assert.are.equal(0, enemy.transform.x)
      assert.is_false(behavior.focused)
    end)

    it('should detect player when within detection radius', function()
      local behavior = ChaseBehavior:new(150, 30, 400)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      local target = { x = 100, y = 0 } -- Within detection (100 < 150)
      local dt = 0.1

      behavior:update(enemy, target, dt)

      -- Should have detected and set focused flag
      assert.is_true(behavior.focused)
      -- Should have moved towards target
      assert.is_true(enemy.transform.x > 0)
    end)

    it('should continue chasing when focused even if target exceeds detection radius', function()
      local behavior = ChaseBehavior:new(150, 30, 400)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      
      -- First, detect the player
      behavior.focused = true
      
      -- Then move target outside detection but inside focus radius
      local target = { x = 250, y = 0 } -- 250 > 150 (detection) but 250 < 400 (focus)
      local dt = 0.1

      behavior:update(enemy, target, dt)

      -- Should still chase because focused
      assert.is_true(enemy.transform.x > 0)
      assert.is_true(behavior.focused)
    end)

    it('should lose focus when target exceeds focus radius', function()
      local behavior = ChaseBehavior:new(150, 30, 400)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      
      -- First, detect the player
      behavior.focused = true
      
      -- Then move target outside focus radius
      local target = { x = 500, y = 0 } -- 500 > 400 (focus)
      local dt = 0.1

      behavior:update(enemy, target, dt)

      -- Should lose focus
      assert.is_false(behavior.focused)
      -- Should not have moved
      assert.are.equal(0, enemy.transform.x)
    end)

    it('should re-detect player when coming back within detection after losing focus', function()
      local behavior = ChaseBehavior:new(150, 30, 400)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      
      -- Lose focus first
      behavior.focused = false
      
      -- Player comes back within detection
      local target = { x = 100, y = 0 } -- Within detection
      local dt = 0.1

      behavior:update(enemy, target, dt)

      -- Should detect again
      assert.is_true(behavior.focused)
      assert.is_true(enemy.transform.x > 0)
    end)
  end)

  describe('focus memory', function()
    it('should maintain focused state between updates', function()
      local behavior = ChaseBehavior:new(150, 30, 400)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }

      -- First update: detect player
      behavior:update(enemy, { x = 100, y = 0 }, 0.1)
      assert.is_true(behavior.focused)
      
      -- Second update: player still within detection
      behavior:update(enemy, { x = 120, y = 0 }, 0.1)
      assert.is_true(behavior.focused)
      
      -- Third update: player moves outside detection but within focus
      behavior:update(enemy, { x = 250, y = 0 }, 0.1)
      assert.is_true(behavior.focused)
    end)
  end)
end)
