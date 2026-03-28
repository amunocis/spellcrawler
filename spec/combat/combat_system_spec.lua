-- spec/combat/combat_system_spec.lua
local CombatSystem = require('src.combat.combat_system')
local Health = require('src.ecs.components.health')

describe('CombatSystem', function()
  it('should create with empty projectiles and enemies lists', function()
    local combat = CombatSystem:new()
    assert.are.equal(0, #combat.projectiles)
    assert.are.equal(0, #combat.enemies)
  end)

  describe(':addProjectile()', function()
    it('should add a projectile to the system', function()
      local combat = CombatSystem:new()
      local projectile = {
        x = 100, y = 200,
        w = 10, h = 10,
        damage = 15,
        spellId = 'chispa'
      }

      combat:addProjectile(projectile)
      assert.are.equal(1, #combat.projectiles)
    end)
  end)

  describe(':addEnemy()', function()
    it('should add an enemy to the system', function()
      local combat = CombatSystem:new()
      local enemy = {
        transform = { x = 100, y = 200 },
        health = Health:new(50),
        collider = { w = 20, h = 20 }
      }

      combat:addEnemy(enemy)
      assert.are.equal(1, #combat.enemies)
    end)
  end)

  describe(':checkCollision()', function()
    it('should return true when projectile hits enemy', function()
      local combat = CombatSystem:new()
      local projectile = { x = 100, y = 100, w = 10, h = 10 }
      local enemy = {
        transform = { x = 100, y = 100 },
        collider = { w = 20, h = 20, offsetX = 0, offsetY = 0 }
      }

      local hit = combat:checkCollision(projectile, enemy)
      assert.is_true(hit)
    end)

    it('should return false when no collision', function()
      local combat = CombatSystem:new()
      local projectile = { x = 0, y = 0, w = 10, h = 10 }
      local enemy = {
        transform = { x = 200, y = 200 },
        collider = { w = 20, h = 20, offsetX = 0, offsetY = 0 }
      }

      local hit = combat:checkCollision(projectile, enemy)
      assert.is_false(hit)
    end)
  end)

  describe(':update()', function()
    it('should damage enemy when projectile hits', function()
      local combat = CombatSystem:new()
      local enemy = {
        transform = { x = 100, y = 100 },
        health = Health:new(50),
        collider = { w = 20, h = 20, offsetX = 0, offsetY = 0 }
      }
      local projectile = {
        x = 100, y = 100,
        w = 10, h = 10,
        damage = 15,
        vx = 0, vy = 0
      }

      combat:addEnemy(enemy)
      combat:addProjectile(projectile)
      combat:update(0.1)

      assert.are.equal(35, enemy.health.current) -- 50 - 15 = 35
    end)

    it('should remove projectile on hit', function()
      local combat = CombatSystem:new()
      local enemy = {
        transform = { x = 100, y = 100 },
        health = Health:new(50),
        collider = { w = 20, h = 20, offsetX = 0, offsetY = 0 }
      }
      local projectile = {
        x = 100, y = 100,
        w = 10, h = 10,
        damage = 15
      }

      combat:addEnemy(enemy)
      combat:addProjectile(projectile)
      combat:update(0.1)

      assert.are.equal(0, #combat.projectiles)
    end)

    it('should mark dead enemies for removal', function()
      local combat = CombatSystem:new()
      local enemy = {
        transform = { x = 100, y = 100 },
        health = Health:new(20),
        collider = { w = 20, h = 20, offsetX = 0, offsetY = 0 },
        dead = false
      }
      local projectile = {
        x = 100, y = 100,
        w = 10, h = 10,
        damage = 25 -- More than enemy HP
      }

      combat:addEnemy(enemy)
      combat:addProjectile(projectile)
      combat:update(0.1)

      assert.are.equal(0, enemy.health.current)
      assert.is_true(enemy.dead)
    end)

    it('should return killed enemies for rewards processing', function()
      local combat = CombatSystem:new()
      local enemy = {
        transform = { x = 100, y = 100 },
        health = Health:new(20),
        collider = { w = 20, h = 20, offsetX = 0, offsetY = 0 },
        dead = false,
        type = 'bat'
      }
      local projectile = {
        x = 100, y = 100,
        w = 10, h = 10,
        damage = 25
      }

      combat:addEnemy(enemy)
      combat:addProjectile(projectile)
      local killed = combat:update(0.1)

      assert.are.equal(1, #killed)
      assert.are.equal('bat', killed[1].type)
    end)
  end)

  describe(':removeDeadEntities()', function()
    it('should remove dead enemies from list', function()
      local combat = CombatSystem:new()
      local aliveEnemy = {
        transform = { x = 0, y = 0 },
        health = Health:new(50),
        dead = false
      }
      local deadEnemy = {
        transform = { x = 100, y = 100 },
        health = Health:new(0),
        dead = true
      }

      combat:addEnemy(aliveEnemy)
      combat:addEnemy(deadEnemy)
      combat:removeDeadEntities()

      assert.are.equal(1, #combat.enemies)
      assert.are.equal(aliveEnemy, combat.enemies[1])
    end)
  end)
end)
