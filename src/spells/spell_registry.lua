-- src/spells/spell_registry.lua
-- Registro central de definiciones de hechizos

local SpellRegistry = {
    _spells = {},
    _slots = {}
}

function SpellRegistry:register(spellDef)
    if not spellDef.id then
        error("Spell definition must have an 'id' field")
    end

    if self._spells[spellDef.id] then
        error("Spell with id '" .. spellDef.id .. "' is already registered")
    end

    self._spells[spellDef.id] = spellDef
end

function SpellRegistry:get(id)
    return self._spells[id]
end

function SpellRegistry:has(id)
    return self._spells[id] ~= nil
end

function SpellRegistry:getAll()
    local list = {}
    for _, spell in pairs(self._spells) do
        table.insert(list, spell)
    end
    return list
end

function SpellRegistry:assignToSlot(slot, spellId)
    self._slots[slot] = spellId
end

function SpellRegistry:getBySlot(slot)
    local spellId = self._slots[slot]
    if spellId then
        return self:get(spellId)
    end
    return nil
end

function SpellRegistry:clear()
    self._spells = {}
    self._slots = {}
end

return SpellRegistry
