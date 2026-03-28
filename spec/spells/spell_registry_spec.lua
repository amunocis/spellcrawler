-- spec/spells/spell_registry_spec.lua
local SpellRegistry = require('src.spells.spell_registry')

describe('SpellRegistry', function()
  before_each(function()
    SpellRegistry:clear()
  end)

  describe(':register()', function()
    it('should register a spell definition', function()
      local spell = {
        id = 'chispa',
        name = 'Chispa',
        damage = 10,
        speed = 400,
        cooldown = 0.3,
        type = 'projectile'
      }

      SpellRegistry:register(spell)
      assert.is_true(SpellRegistry:has('chispa'))
    end)

    it('should throw error for duplicate id', function()
      local spell = { id = 'chispa', name = 'Chispa' }
      SpellRegistry:register(spell)

      assert.has_error(function()
        SpellRegistry:register(spell)
      end)
    end)

    it('should throw error for missing id', function()
      assert.has_error(function()
        SpellRegistry:register({ name = 'No ID' })
      end)
    end)
  end)

  describe(':get()', function()
    it('should return spell definition by id', function()
      local spell = { id = 'chispa', name = 'Chispa', damage = 10 }
      SpellRegistry:register(spell)

      local retrieved = SpellRegistry:get('chispa')
      assert.are.equal('Chispa', retrieved.name)
      assert.are.equal(10, retrieved.damage)
    end)

    it('should return nil for unknown spell', function()
      local retrieved = SpellRegistry:get('unknown')
      assert.is_nil(retrieved)
    end)
  end)

  describe(':getAll()', function()
    it('should return all registered spells', function()
      SpellRegistry:register({ id = 'spell1', name = 'Spell 1' })
      SpellRegistry:register({ id = 'spell2', name = 'Spell 2' })

      local all = SpellRegistry:getAll()
      assert.are.equal(2, #all)
    end)
  end)

  describe(':getBySlot()', function()
    it('should return spell assigned to slot', function()
      SpellRegistry:register({ id = 'chispa', name = 'Chispa' })
      SpellRegistry:assignToSlot(1, 'chispa')

      local spell = SpellRegistry:getBySlot(1)
      assert.are.equal('chispa', spell.id)
    end)

    it('should return nil for empty slot', function()
      local spell = SpellRegistry:getBySlot(5)
      assert.is_nil(spell)
    end)
  end)
end)
