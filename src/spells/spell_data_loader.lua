-- src/spells/spell_data_loader.lua
-- Carga hechizos desde archivos de datos en data/spells/
-- Single Responsibility: Solo carga datos, no procesa lógica de juego

local SpellRegistry = require('src.spells.spell_registry')

local SpellDataLoader = {}

-- Ruta base para los archivos de hechizos
SpellDataLoader.SPELLS_PATH = 'data/spells/'

-- Lista de hechizos a cargar (definidos explícitamente para evitar carga dinámica insegura)
SpellDataLoader.SPELL_FILES = {
    'chispa',
    'dardo_magico',
    'rafaga_viento'
}

--- Carga un hechizo individual desde su archivo de datos
-- @param spellId string: ID del hechizo (nombre del archivo sin extensión)
-- @return boolean: true si se cargó exitosamente (o ya estaba cargado)
function SpellDataLoader:loadSpell(spellId)
    -- Si ya está registrado, no hacer nada (idempotente)
    if SpellRegistry:has(spellId) then
        return true
    end
    
    local path = self.SPELLS_PATH .. spellId
    
    -- Intentar cargar el módulo
    local ok, spellData = pcall(require, path)
    
    if not ok then
        error(string.format("Failed to load spell '%s' from '%s': %s", spellId, path, tostring(spellData)))
        return false
    end
    
    -- Validar que tenga los campos requeridos
    if not self:validateSpellData(spellData) then
        error(string.format("Invalid spell data for '%s': missing required fields", spellId))
        return false
    end
    
    -- Registrar en el SpellRegistry
    SpellRegistry:register(spellData)
    
    return true
end

--- Valida que los datos del hechizo tengan los campos mínimos requeridos
-- @param data table: Datos del hechizo
-- @return boolean: true si es válido
function SpellDataLoader:validateSpellData(data)
    if type(data) ~= 'table' then
        return false
    end
    
    -- Campos requeridos mínimos
    local required = {'id', 'name', 'damage', 'speed', 'cooldown', 'type', 'color'}
    
    for _, field in ipairs(required) do
        if data[field] == nil then
            return false
        end
    end
    
    return true
end

--- Carga todos los hechizos definidos en SPELL_FILES
-- @return number: Cantidad de hechizos cargados exitosamente
function SpellDataLoader:loadAllSpells()
    local loaded = 0
    
    for _, spellId in ipairs(self.SPELL_FILES) do
        if self:loadSpell(spellId) then
            loaded = loaded + 1
        end
    end
    
    return loaded
end

--- Limpia el SpellRegistry y recarga todos los hechizos
-- Útil para hot-reloading durante desarrollo
function SpellDataLoader:reloadAll()
    SpellRegistry:clear()
    return self:loadAllSpells()
end

return SpellDataLoader
