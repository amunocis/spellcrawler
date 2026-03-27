-- src/core/state_manager.lua
-- Manejador de estados del juego (Menu, Hub, Dungeon, etc.)

local StateManager = {}
StateManager.__index = StateManager

function StateManager:new()
    local instance = {
        _states = {},
        current = nil,
        _currentName = nil
    }
    setmetatable(instance, self)
    return instance
end

function StateManager:register(name, stateClass)
    self._states[name] = stateClass
end

function StateManager:switch(name, ...)
    local newStateClass = self._states[name]
    if not newStateClass then
        error("State '" .. name .. "' not registered")
    end

    -- Salir del estado actual
    if self.current and self.current.exit then
        self.current:exit()
    end

    -- Crear nueva instancia del estado
    local newState = newStateClass:new(...)
    self.current = newState
    self._currentName = name

    -- Entrar al nuevo estado
    if self.current.enter then
        self.current:enter(...)
    end

    return self.current
end

function StateManager:getCurrentName()
    return self._currentName
end

function StateManager:pop()
    -- Para futuro: stack de estados (pause sobre gameplay)
end

function StateManager:push(name)
    -- Para futuro: stack de estados
end

return StateManager
