-- spec/spells/spell_caster_spec.lua
local SpellCaster = require('src.spells.spell_caster')
local SpellRegistry = require('src.spells.spell_registry')

describe('SpellCaster Component', function()
  before_each(function()
    SpellRegistry:clear()
  end)

  it('should create with empty spell slots', function()
    local caster = SpellCaster:new()
    -- Verificar que los 3 slots están disponibles (nil = vacío)
    assert.is_nil(caster.slots[1])
    assert.is_nil(caster.slots[2])
    assert.is_nil(caster.slots[3])
    assert.is_nil(caster.slots[4]) -- slot 4 no existe
  end)

  describe(':equipSpell()', function()
    it('should equip spell to slot', function()
      SpellRegistry:register({ id = 'chispa', name = 'Chispa', cooldown = 0.3 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')

      assert.are.equal('chispa', caster.slots[1])
    end)

    it('should throw error for invalid slot', function()
      local caster = SpellCaster:new()
      assert.has_error(function()
        caster:equipSpell(0, 'chispa')
      end)
      assert.has_error(function()
        caster:equipSpell(4, 'chispa')
      end)
    end)
  end)

  describe(':canCast()', function()
    it('should return true when spell is off cooldown', function()
      SpellRegistry:register({ id = 'chispa', cooldown = 0.3 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')

      assert.is_true(caster:canCast(1))
    end)

    it('should return false when spell is on cooldown', function()
      SpellRegistry:register({ id = 'chispa', cooldown = 0.3 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')
      caster:cast(1, 0, 0, 1, 0) -- cast once

      assert.is_false(caster:canCast(1))
    end)

    it('should return false for empty slot', function()
      local caster = SpellCaster:new()
      assert.is_false(caster:canCast(1))
    end)
  end)

  describe(':cast()', function()
    it('should return spell instance when cast', function()
      SpellRegistry:register({
        id = 'chispa',
        name = 'Chispa',
        damage = 10,
        speed = 400,
        cooldown = 0.3,
        type = 'projectile'
      })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')

      local projectile = caster:cast(1, 100, 200, 1, 0)

      assert.is_not_nil(projectile)
      assert.are.equal('chispa', projectile.spellId)
      assert.are.equal(10, projectile.damage)
      assert.are.equal(100, projectile.x)
      assert.are.equal(200, projectile.y)
      assert.are.equal(400, projectile.vx)
      assert.are.equal(0, projectile.vy)
    end)

    it('should start cooldown when cast', function()
      SpellRegistry:register({ id = 'chispa', cooldown = 0.3 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')
      caster:cast(1, 0, 0, 1, 0)

      assert.is_false(caster:canCast(1))
    end)

    it('should return nil when on cooldown', function()
      SpellRegistry:register({ id = 'chispa', cooldown = 0.3 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')
      caster:cast(1, 0, 0, 1, 0)

      local projectile = caster:cast(1, 0, 0, 1, 0)
      assert.is_nil(projectile)
    end)
  end)

  describe(':update()', function()
    it('should reduce cooldowns over time', function()
      SpellRegistry:register({ id = 'chispa', cooldown = 0.3 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')
      caster:cast(1, 0, 0, 1, 0)

      assert.is_false(caster:canCast(1))

      caster:update(0.3)

      assert.is_true(caster:canCast(1))
    end)
  end)

  describe(':getCooldownPercent()', function()
    it('should return 0 when ready', function()
      SpellRegistry:register({ id = 'chispa', cooldown = 0.3 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')

      assert.are.equal(0, caster:getCooldownPercent(1))
    end)

    it('should return 1 when just cast', function()
      SpellRegistry:register({ id = 'chispa', cooldown = 0.3 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')
      caster:cast(1, 0, 0, 1, 0)

      assert.are.equal(1, caster:getCooldownPercent(1))
    end)

    it('should return partial when cooling down', function()
      SpellRegistry:register({ id = 'chispa', cooldown = 1.0 })

      local caster = SpellCaster:new()
      caster:equipSpell(1, 'chispa')
      caster:cast(1, 0, 0, 1, 0)
      caster:update(0.5)

      assert.are.equal(0.5, caster:getCooldownPercent(1))
    end)
  end)
end)
