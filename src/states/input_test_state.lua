-- src/states/input_test_state.lua
-- Estado temporal para probar input (gamepad, teclado, mouse)
-- Acceder desde el menú principal o presionar F1 en cualquier estado

local InputManager = require('src.core.input_manager')

local InputTestState = {}
InputTestState.__index = InputTestState

function InputTestState:new()
    local instance = {}
    setmetatable(instance, self)
    return instance
end

function InputTestState:enter()
    print("InputTestState: enter")
    self.input = InputManager:new()
    self.input:setupDefaultMappings()
    
    -- Historial de eventos
    self.events = {}
    self.maxEvents = 10
end

function InputTestState:exit()
    print("InputTestState: exit")
end

function InputTestState:addEvent(text)
    table.insert(self.events, 1, text)
    if #self.events > self.maxEvents then
        table.remove(self.events)
    end
end

function InputTestState:update(dt)
    self.input:update(dt)
    
    -- Detectar cambios en botones
    local buttons = {'cast_spell', 'dash', 'interact', 'pause', 'spell_1', 'spell_2', 'spell_3', 'spell_4', 'menu_confirm', 'menu_back'}
    for _, btn in ipairs(buttons) do
        if self.input:pressed(btn) then
            self:addEvent("PRESSED: " .. btn)
        end
        if self.input:released(btn) then
            self:addEvent("RELEASED: " .. btn)
        end
    end
    
    -- Volver al menu con ESC
    if self.input:pressed('pause') then
        local stateManager = _G.Registry:get('state_manager')
        stateManager:switch('menu')
    end
    
    -- Test de vibración con F2
    if love.keyboard.isDown('f2') then
        self.input:setVibration(0.5, 0.5)
    else
        self.input:setVibration(0, 0)
    end
end

function InputTestState:draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local y = 20
    local lineHeight = 25
    
    -- Título
    love.graphics.setColor(0.8, 0.6, 1)
    love.graphics.printf("INPUT TEST - Probar Gamepad", 0, y, w, 'center')
    y = y + lineHeight * 2
    
    -- Estado de conexión
    love.graphics.setColor(1, 1, 1)
    if self.input:isGamepadConnected() then
        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.print("✓ GAMEPAD CONECTADO", 20, y)
    else
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.print("✗ No hay gamepad conectado", 20, y)
    end
    y = y + lineHeight * 2
    
    -- Analog Movement
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("=== ANALOG MOVEMENT (Left Stick) ===", 20, y)
    y = y + lineHeight
    
    local mx, my = self.input:getAnalogMovement()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("X: %.3f  Y: %.3f", mx, my), 20, y)
    y = y + lineHeight
    
    -- Visual del stick
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.circle('line', 100, y + 40, 40)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.circle('fill', 100 + mx * 35, y + 40 + my * 35, 8)
    y = y + lineHeight * 4
    
    -- Analog Aim
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("=== ANALOG AIM (Right Stick) ===", 20, y)
    y = y + lineHeight
    
    local ax, ay = self.input:getAnalogAim(0, 0)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("X: %.3f  Y: %.3f", ax, ay), 20, y)
    y = y + lineHeight
    
    -- Visual del stick
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.circle('line', 100, y + 40, 40)
    
    -- Color diferente para autoaim
    if math.abs(ax) < 0.2 and math.abs(ay) < 0.2 and self.input:isGamepadConnected() then
      love.graphics.setColor(1, 0.8, 0.2) -- Amarillo = autoaim disponible
    else
      love.graphics.setColor(0.8, 0.2, 0.8) -- Morado = aim manual
    end
    love.graphics.circle('fill', 100 + ax * 35, y + 40 + ay * 35, 8)
    
    -- Nota de autoaim
    if math.abs(ax) < 0.2 and math.abs(ay) < 0.2 and self.input:isGamepadConnected() then
      love.graphics.setColor(1, 0.8, 0.2)
      love.graphics.print("(Autoaim activo en Dungeon)", 160, y + 30)
    end
    y = y + lineHeight * 4
    
    -- Estado de botones
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("=== BOTONES ===", 20, y)
    y = y + lineHeight
    
    local buttons = {
        {name = 'cast_spell (A)', key = 'cast_spell'},
        {name = 'dash (B)', key = 'dash'},
        {name = 'interact (X)', key = 'interact'},
        {name = 'pause (Start)', key = 'pause'},
        {name = 'spell_1 (LB)', key = 'spell_1'},
        {name = 'spell_2 (RB)', key = 'spell_2'},
        {name = 'spell_3 (Y)', key = 'spell_3'},
        {name = 'spell_4 (RStick)', key = 'spell_4'},
    }
    
    for _, btn in ipairs(buttons) do
        if self.input:isDown(btn.key) then
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.print("[ON]  " .. btn.name, 20, y)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("[off] " .. btn.name, 20, y)
        end
        y = y + lineHeight
    end
    
    -- D-Pad
    y = y + 10
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("=== D-PAD ===", 20, y)
    y = y + lineHeight
    
    local dpad = {
        {name = 'UP', key = 'move_up'},
        {name = 'DOWN', key = 'move_down'},
        {name = 'LEFT', key = 'move_left'},
        {name = 'RIGHT', key = 'move_right'},
    }
    
    local x = 20
    for _, d in ipairs(dpad) do
        if self.input:isDown(d.key) then
            love.graphics.setColor(0.2, 1, 0.2)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
        end
        love.graphics.print(d.name, x, y)
        x = x + 80
    end
    y = y + lineHeight * 2
    
    -- Eventos recientes
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("=== EVENTOS ===", 20, y)
    y = y + lineHeight
    
    for i, event in ipairs(self.events) do
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print(event, 20, y)
        y = y + lineHeight
    end
    
    -- Instrucciones
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.print("ESC/Start: Volver al menu  |  F2: Probar vibración", 20, h - 30)
end

function InputTestState:keypressed(key)
    if key == 'escape' then
        local stateManager = _G.Registry:get('state_manager')
        stateManager:switch('menu')
    end
end

return InputTestState
