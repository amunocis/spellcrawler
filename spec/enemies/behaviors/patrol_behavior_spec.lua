-- spec/enemies/behaviors/patrol_behavior_spec.lua
local PatrolBehavior = require('src.enemies.behaviors.patrol_behavior')

describe('PatrolBehavior', function()
  it('should create with type patrol', function()
    local behavior = PatrolBehavior:new()
    assert.are.equal('patrol', behavior.type)
  end)

  it('should have patrol radius', function()
    local behavior = PatrolBehavior:new(100)
    assert.are.equal(100, behavior.radius)
  end)

  it('should have default patrol radius', function()
    local behavior = PatrolBehavior:new()
    assert.are.equal(50, behavior.radius)
  end)

  describe(':update()', function()
    it('should set target point when idle', function()
      local behavior = PatrolBehavior:new(50)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 50
      }
      local dt = 0.1

      behavior:update(enemy, nil, dt)

      -- Should have set a target point
      assert.is_not_nil(behavior.targetX)
      assert.is_not_nil(behavior.targetY)
    end)

    it('should move towards target point', function()
      local behavior = PatrolBehavior:new(50)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      local dt = 0.1

      -- First call sets target
      behavior:update(enemy, nil, dt)
      local startX = enemy.transform.x

      -- Second call moves towards it
      behavior:update(enemy, nil, dt)

      -- Should have moved
      assert.is_true(enemy.transform.x ~= 0 or enemy.transform.y ~= 0 or
                     (behavior.targetX == 0 and behavior.targetY == 0))
    end)

    it('should pick new target when reaching current', function()
      local behavior = PatrolBehavior:new(50)
      local enemy = {
        transform = { x = 0, y = 0 },
        speed = 100
      }
      local dt = 0.1

      -- Set target very close
      behavior.targetX = 1
      behavior.targetY = 0
      behavior.waitTimer = 0

      local oldTargetX = behavior.targetX

      behavior:update(enemy, nil, dt)

      -- Should pick new target
      assert.is_true(behavior.targetX ~= oldTargetX or behavior.waitTimer > 0)
    end)
  end)
end)
