-- src/spells/spell_caster.lua
-- Componente para entidades que pueden lanzar hechizos

local SpellRegistry = require('src.spells.spell_registry')

local SpellCaster = {}
SpellCaster.__index = SpellCaster

function SpellCaster:new()
    local instance = {
        slots = {nil, nil, nil},
        _cooldowns = {},
        _slotCount = 3
    }
    setmetatable(instance, self)
    return instance
end

function SpellCaster:equipSpell(slot, spellId)
    if slot < 1 or slot > self._slotCount then
        error("Invalid slot: " .. slot .. ". Must be between 1 and " .. self._slotCount)
    end

    self.slots[slot] = spellId
    self._cooldowns[slot] = 0
end

function SpellCaster:canCast(slot)
    if slot < 1 or slot > self._slotCount then
        return false
    end

    if not self.slots[slot] then
        return false
    end

    return (self._cooldowns[slot] or 0) <= 0
end

function SpellCaster:cast(slot, x, y, dirX, dirY)
    if not self:canCast(slot) then
        return nil
    end

    local spellId = self.slots[slot]
    local spellDef = SpellRegistry:get(spellId)

    if not spellDef then
        return nil
    end

    -- Start cooldown
    self._cooldowns[slot] = spellDef.cooldown or 0

    -- Create projectile instance
    local projectile = {
        spellId = spellId,
        name = spellDef.name,
        damage = spellDef.damage or 0,
        speed = spellDef.speed or 400,
        x = x,
        y = y,
        vx = dirX * (spellDef.speed or 400),
        vy = dirY * (spellDef.speed or 400),
        type = spellDef.type or 'projectile',
        lifetime = 2.0
    }

    return projectile
end

function SpellCaster:update(dt)
    for slot, cooldown in pairs(self._cooldowns) do
        if cooldown > 0 then
            self._cooldowns[slot] = math.max(0, cooldown - dt)
        end
    end
end

function SpellCaster:getCooldownPercent(slot)
    if slot < 1 or slot > self._slotCount then
        return 0
    end

    if not self.slots[slot] then
        return 0
    end

    local spellId = self.slots[slot]
    local spellDef = SpellRegistry:get(spellId)

    if not spellDef then
        return 0
    end

    local currentCooldown = self._cooldowns[slot] or 0
    if currentCooldown <= 0 then
        return 0
    end

    local maxCooldown = spellDef.cooldown or 0.1
    return math.min(1, currentCooldown / maxCooldown)
end

return SpellCaster
