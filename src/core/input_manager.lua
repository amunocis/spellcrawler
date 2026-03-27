-- src/core/input_manager.lua
-- Abstracción de input: soporta teclado, mouse y mando.
-- El resto del código no sabe de qué dispositivo viene el input.

local InputManager = {}
InputManager.__index = InputManager

function InputManager:new()
    local instance = {
        _mappings = {},
        _states = {},
        _previousStates = {},
        _joysticks = {}
    }
    setmetatable(instance, self)
    return instance
end

function InputManager:setupDefaultMappings()
    -- Movimiento
    self:map('move_left', {'key:a', 'key:left', 'axis:leftx_neg'})
    self:map('move_right', {'key:d', 'key:right', 'axis:leftx_pos'})
    self:map('move_up', {'key:w', 'key:up', 'axis:lefty_neg'})
    self:map('move_down', {'key:s', 'key:down', 'axis:lefty_pos'})

    -- Acciones principales
    self:map('cast_spell', {'key:space', 'button:a', 'mouse:1'})
    self:map('dash', {'key:lshift', 'button:b'})
    self:map('interact', {'key:e', 'button:x'})
    self:map('pause', {'key:escape', 'button:start'})

    -- Hechizos (números o bumpers)
    self:map('spell_1', {'key:1', 'button:lb'})
    self:map('spell_2', {'key:2', 'button:rb'})
    self:map('spell_3', {'key:3'})
    self:map('spell_4', {'key:4'})

    -- UI
    self:map('menu_confirm', {'key:return', 'button:a'})
    self:map('menu_back', {'key:escape', 'button:b'})
end

function InputManager:map(action, inputs)
    self._mappings[action] = inputs
    self._states[action] = false
    self._previousStates[action] = false
end

function InputManager:update(dt)
    -- Guardar estado anterior
    for action, _ in pairs(self._states) do
        self._previousStates[action] = self._states[action]
    end

    -- Actualizar estado actual
    for action, inputs in pairs(self._mappings) do
        self._states[action] = self:_checkInputs(inputs)
    end
end

function InputManager:_checkInputs(inputs)
    for _, input in ipairs(inputs) do
        if self:_isInputActive(input) then
            return true
        end
    end
    return false
end

function InputManager:_isInputActive(input)
    local type, value = input:match("^([^:]+):(.+)$")

    if type == 'key' then
        return love.keyboard.isDown(value)
    elseif type == 'mouse' then
        return love.mouse.isDown(tonumber(value))
    elseif type == 'button' then
        return self:_isGamepadButtonDown(value)
    elseif type == 'axis' then
        return self:_isAxisActive(value)
    end

    return false
end

function InputManager:_isGamepadButtonDown(button)
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            if button == 'a' and joystick:isGamepadDown('a') then return true end
            if button == 'b' and joystick:isGamepadDown('b') then return true end
            if button == 'x' and joystick:isGamepadDown('x') then return true end
            if button == 'y' and joystick:isGamepadDown('y') then return true end
            if button == 'lb' and joystick:isGamepadDown('leftshoulder') then return true end
            if button == 'rb' and joystick:isGamepadDown('rightshoulder') then return true end
            if button == 'start' and joystick:isGamepadDown('start') then return true end
        end
    end
    return false
end

function InputManager:_isAxisActive(axisName)
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            if axisName == 'leftx_pos' then
                local x = joystick:getGamepadAxis('leftx')
                if x > 0.3 then return true end
            elseif axisName == 'leftx_neg' then
                local x = joystick:getGamepadAxis('leftx')
                if x < -0.3 then return true end
            elseif axisName == 'lefty_pos' then
                local y = joystick:getGamepadAxis('lefty')
                if y > 0.3 then return true end
            elseif axisName == 'lefty_neg' then
                local y = joystick:getGamepadAxis('lefty')
                if y < -0.3 then return true end
            end
        end
    end
    return false
end

-- API pública para consultar estado
function InputManager:isDown(action)
    return self._states[action] or false
end

function InputManager:pressed(action)
    return (self._states[action] and not self._previousStates[action])
end

function InputManager:released(action)
    return (not self._states[action] and self._previousStates[action])
end

-- Obtener dirección del movimiento (normalizado)
function InputManager:getMovementVector()
    local x, y = 0, 0

    if self:isDown('move_left') then x = x - 1 end
    if self:isDown('move_right') then x = x + 1 end
    if self:isDown('move_up') then y = y - 1 end
    if self:isDown('move_down') then y = y + 1 end

    -- Normalizar para diagonales
    if x ~= 0 or y ~= 0 then
        local length = math.sqrt(x * x + y * y)
        if length > 1 then
            x = x / length
            y = y / length
        end
    end

    return x, y
end

-- Obtener dirección del aim (mouse o right stick)
function InputManager:getAimDirection(fromX, fromY)
    -- Priorizar mouse si hay movimiento reciente
    local mouseX, mouseY = love.mouse.getPosition()

    -- Si hay gamepad, usar right stick
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            local rx = joystick:getGamepadAxis('rightx')
            local ry = joystick:getGamepadAxis('righty')

            if math.abs(rx) > 0.3 or math.abs(ry) > 0.3 then
                return rx, ry
            end
        end
    end

    -- Default: dirección hacia el mouse
    local dx = mouseX - fromX
    local dy = mouseY - fromY
    local length = math.sqrt(dx * dx + dy * dy)

    if length > 0 then
        return dx / length, dy / length
    end

    return 0, 0
end

return InputManager
