-- main.lua
-- Entry point minimalista. Solo bootstrap.

local Registry = require('src.core.registry')
local EventBus = require('src.core.event_bus')
local InputManager = require('src.core.input_manager')
local StateManager = require('src.core.state_manager')

-- Estados del juego
local MenuState = require('src.states.menu_state')
local HubState = require('src.states.hub_state')
local DungeonState = require('src.states.dungeon_state')
local InputTestState = require('src.states.input_test_state')

function love.load()
    -- Inicializar Registry (único global implícito)
    _G.Registry = Registry:new()

    -- Registrar sistemas core
    local eventBus = EventBus:new()
    local inputManager = InputManager:new()
    local stateManager = StateManager:new()

    _G.Registry:register('event_bus', eventBus)
    _G.Registry:register('input', inputManager)
    _G.Registry:register('state_manager', stateManager)

    -- Configurar mapeo de controles
    inputManager:setupDefaultMappings()

    -- Registrar estados disponibles
    stateManager:register('menu', MenuState)
    stateManager:register('hub', HubState)
    stateManager:register('dungeon', DungeonState)
    stateManager:register('input_test', InputTestState)

    -- Iniciar en el menú
    stateManager:switch('menu')
end

function love.update(dt)
    local stateManager = _G.Registry:get('state_manager')
    local inputManager = _G.Registry:get('input')
    local eventBus = _G.Registry:get('event_bus')

    -- Actualizar input primero
    inputManager:update(dt)

    -- Procesar eventos pendientes
    eventBus:process(dt)

    -- Actualizar estado actual
    if stateManager.current then
        stateManager.current:update(dt)
    end
end

function love.draw()
    local stateManager = _G.Registry:get('state_manager')

    if stateManager.current then
        stateManager.current:draw()
    end
end

-- Delegar eventos de LÖVE al estado actual
function love.keypressed(key, scancode, isrepeat)
    local stateManager = _G.Registry:get('state_manager')
    if stateManager.current and stateManager.current.keypressed then
        stateManager.current:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    local stateManager = _G.Registry:get('state_manager')
    if stateManager.current and stateManager.current.keyreleased then
        stateManager.current:keyreleased(key, scancode)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    local stateManager = _G.Registry:get('state_manager')
    if stateManager.current and stateManager.current.mousepressed then
        stateManager.current:mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    local stateManager = _G.Registry:get('state_manager')
    if stateManager.current and stateManager.current.mousereleased then
        stateManager.current:mousereleased(x, y, button, istouch, presses)
    end
end

function love.joystickpressed(joystick, button)
    local stateManager = _G.Registry:get('state_manager')
    if stateManager.current and stateManager.current.joystickpressed then
        stateManager.current:joystickpressed(joystick, button)
    end
end

function love.joystickreleased(joystick, button)
    local stateManager = _G.Registry:get('state_manager')
    if stateManager.current and stateManager.current.joystickreleased then
        stateManager.current:joystickreleased(joystick, button)
    end
end

function love.resize(w, h)
    local stateManager = _G.Registry:get('state_manager')
    if stateManager.current and stateManager.current.resize then
        stateManager.current:resize(w, h)
    end
end
