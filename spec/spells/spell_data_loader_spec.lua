-- spec/spells/spell_data_loader_spec.lua
local SpellDataLoader = require('src.spells.spell_data_loader')
local SpellRegistry = require('src.spells.spell_registry')

describe('SpellDataLoader', function()
  before_each(function()
    SpellRegistry:clear()
  end)

  describe(':validateSpellData()', function()
    it('should validate complete spell data', function()
      local validData = {
        id = 'test_spell',
        name = 'Test Spell',
        damage = 10,
        speed = 400,
        cooldown = 0.5,
        type = 'projectile',
        color = {1, 0, 0}
      }
      
      assert.is_true(SpellDataLoader:validateSpellData(validData))
    end)
    
    it('should reject data with missing fields', function()
      local invalidData = {
        id = 'test_spell',
        name = 'Test Spell'
        -- missing damage, speed, cooldown, type, color
      }
      
      assert.is_false(SpellDataLoader:validateSpellData(invalidData))
    end)
    
    it('should reject non-table data', function()
      assert.is_false(SpellDataLoader:validateSpellData(nil))
      assert.is_false(SpellDataLoader:validateSpellData("string"))
      assert.is_false(SpellDataLoader:validateSpellData(123))
    end)
  end)

  describe(':loadSpell()', function()
    it('should load a valid spell file', function()
      local result = SpellDataLoader:loadSpell('chispa')
      
      assert.is_true(result)
      assert.is_true(SpellRegistry:has('chispa'))
      
      local spell = SpellRegistry:get('chispa')
      assert.are.equal('Chispa', spell.name)
      assert.are.equal(15, spell.damage)
      assert.are.equal('projectile', spell.type)
    end)
    
    it('should load dardo_magico with correct data', function()
      SpellDataLoader:loadSpell('dardo_magico')
      
      local spell = SpellRegistry:get('dardo_magico')
      assert.are.equal('Dardo Mágico', spell.name)
      assert.are.equal(600, spell.speed)
      assert.are.equal(0.2, spell.cooldown)
    end)
    
    it('should load rafaga_viento with correct data', function()
      SpellDataLoader:loadSpell('rafaga_viento')
      
      local spell = SpellRegistry:get('rafaga_viento')
      assert.are.equal('Ráfaga de Viento', spell.name)
      assert.are.equal(25, spell.damage)
      assert.are.equal(0.5, spell.cooldown)
    end)
  end)

  describe(':loadAllSpells()', function()
    it('should load all defined spells', function()
      local count = SpellDataLoader:loadAllSpells()
      
      assert.are.equal(3, count)
      assert.is_true(SpellRegistry:has('chispa'))
      assert.is_true(SpellRegistry:has('dardo_magico'))
      assert.is_true(SpellRegistry:has('rafaga_viento'))
    end)
  end)

  describe(':reloadAll()', function()
    it('should clear and reload all spells', function()
      SpellDataLoader:loadSpell('chispa')
      assert.is_true(SpellRegistry:has('chispa'))
      
      local count = SpellDataLoader:reloadAll()
      
      assert.are.equal(3, count)
      assert.is_true(SpellRegistry:has('chispa'))
      assert.is_true(SpellRegistry:has('dardo_magico'))
      assert.is_true(SpellRegistry:has('rafaga_viento'))
    end)
  end)
end)
