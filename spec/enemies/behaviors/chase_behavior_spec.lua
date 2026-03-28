-- spec/enemies/behaviors/chase_behavior_spec.lua
local ChaseBehavior = require('src.enemies.behaviors.chase_behavior')

describe('ChaseBehavior', function()
  it('should create with type chase', function()
    local behavior = ChaseBehavior:new()
    assert.are.equal('chase', behavior.type)
  end)

  it('should have detection radius', function()
    local behavior = ChaseBehavior:new(150)
    assert.are.equal(150, behavior.detectionRadius)
  end)

  it('should have default detection radius', function()
    local behavior = ChaseBehavior:new()
    assert.are.equal(150, behavior.detectionRadius)
  end)

  it('should have default focus radius', function()
    local behavior = ChaseBehavior:new()
    assert.are.equal(400, behavior.focusRadius)
  end)

  it('should not be focused initially', function()
    local behavior = ChaseBehavior:new()
    assert.is_false(behavior.focused)
  end)

  describe(':update()', function()
    it('should move towards target when in range', function()
      local behavior = ChaseBehavior:new(200)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      local target = { x = 100, y = 0 }
      local dt = 0.1

      behavior:update(enemy, target, dt)

      -- Should have moved towards target (positive x)
      assert.is_true(enemy.transform.x > 0)
    end)

    it('should not move when target is out of range', function()
      local behavior = ChaseBehavior:new(50)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      local target = { x = 200, y = 0 } -- Out of range
      local dt = 0.1

      behavior:update(enemy, target, dt)

      -- Should not have moved
      assert.are.equal(0, enemy.transform.x)
      assert.are.equal(0, enemy.transform.y)
    end)

    it('should circle around target when within attack range', function()
      local behavior = ChaseBehavior:new(200, 30)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      local target = { x = 20, y = 0 } -- Within attack range (20 < 30)
      local dt = 0.1

      behavior:update(enemy, target, dt)

      -- Should move (circling) when within attack range, not stay still
      -- The enemy should move perpendicular to the target direction
      assert.is_true(enemy.transform.x ~= 0 or enemy.transform.y ~= 0)
    end)
  end)
end)
