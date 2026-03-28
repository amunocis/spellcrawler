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
    -- Movimiento (teclado + analog + d-pad)
    self:map('move_left', {'key:a', 'key:left', 'axis:leftx_neg', 'button:dpleft'})
    self:map('move_right', {'key:d', 'key:right', 'axis:leftx_pos', 'button:dpright'})
    self:map('move_up', {'key:w', 'key:up', 'axis:lefty_neg', 'button:dpup'})
    self:map('move_down', {'key:s', 'key:down', 'axis:lefty_pos', 'button:dpdown'})

    -- Acciones principales
    self:map('cast_spell', {'key:space', 'button:a', 'mouse:1'})
    self:map('dash', {'key:lshift', 'button:b'})
    self:map('interact', {'key:e', 'button:x'})
    self:map('pause', {'key:escape', 'button:start'})

    -- Hechizos (números o bumpers + botones)
    self:map('spell_1', {'key:1', 'button:lb'})
    self:map('spell_2', {'key:2', 'button:rb'})
    self:map('spell_3', {'key:3', 'button:y'})
    self:map('spell_4', {'key:4', 'button:rightstick'})

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
            -- D-Pad
            if button == 'dpleft' and joystick:isGamepadDown('dpleft') then return true end
            if button == 'dpright' and joystick:isGamepadDown('dpright') then return true end
            if button == 'dpup' and joystick:isGamepadDown('dpup') then return true end
            if button == 'dpdown' and joystick:isGamepadDown('dpdown') then return true end
            -- Stick clicks
            if button == 'leftstick' and joystick:isGamepadDown('leftstick') then return true end
            if button == 'rightstick' and joystick:isGamepadDown('rightstick') then return true end
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

-- ============================================
-- NUEVA API PARA GAMEPAD COMPLETO
-- ============================================

--- Verifica si hay un gamepad conectado
-- @return boolean true si hay al menos un gamepad conectado
function InputManager:isGamepadConnected()
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            return true
        end
    end
    return false
end

--- Obtiene el gamepad activo (el primero encontrado)
-- @return joystick|nil El objeto joystick o nil si no hay gamepad
function InputManager:getActiveGamepad()
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            return joystick
        end
    end
    return nil
end

--- Obtiene el vector de movimiento analógico del left stick
-- Aplica deadzone y curva de respuesta para mejor feel
-- @return number, number x, y normalizados (-1 a 1)
function InputManager:getAnalogMovement()
    local gamepad = self:getActiveGamepad()
    if not gamepad then
        return 0, 0
    end

    local x = gamepad:getGamepadAxis('leftx')
    local y = gamepad:getGamepadAxis('lefty')

    -- Aplicar deadzone
    local deadzone = 0.15
    local length = math.sqrt(x * x + y * y)
    
    if length < deadzone then
        return 0, 0
    end

    -- Aplicar curva de respuesta para más sensibilidad en valores bajos
    -- Usamos pow < 1 para amplificar valores pequeños: output = sign * |input|^0.7
    local curveExponent = 0.7
    x = (x < 0 and -1 or 1) * (math.abs(x) ^ curveExponent)
    y = (y < 0 and -1 or 1) * (math.abs(y) ^ curveExponent)

    -- Re-normalizar si excede 1
    local newLength = math.sqrt(x * x + y * y)
    if newLength > 1 then
        x = x / newLength
        y = y / newLength
    end

    return x, y
end

--- Obtiene el vector de aim analógico del right stick
-- Aplica deadzone para evitar drift
-- @return number, number x, y normalizados (-1 a 1)
function InputManager:getAnalogAim(fromX, fromY)
    local gamepad = self:getActiveGamepad()
    if not gamepad then
        return 0, 0
    end

    local x = gamepad:getGamepadAxis('rightx')
    local y = gamepad:getGamepadAxis('righty')

    -- Aplicar deadzone
    local deadzone = 0.2
    local length = math.sqrt(x * x + y * y)
    
    if length < deadzone then
        return 0, 0
    end

    -- Normalizar
    if length > 0 then
        x = x / length
        y = y / length
    end

    return x, y
end

--- Activa la vibración en el gamepad
-- @param left number Intensidad del motor izquierdo (0-1)
-- @param right number Intensidad del motor derecho (0-1)
-- @return boolean true si se pudo activar la vibración
function InputManager:setVibration(left, right)
    local gamepad = self:getActiveGamepad()
    if not gamepad then
        return false
    end

    -- LÖVE 11.x usa setVibration(left, right)
    local ok, result = pcall(function()
        return gamepad:setVibration(left or 0, right or 0)
    end)

    return ok and result ~= nil
end

return InputManager
