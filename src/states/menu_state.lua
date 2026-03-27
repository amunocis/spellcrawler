-- src/states/menu_state.lua
-- Estado inicial: menú principal

local MenuState = {}
MenuState.__index = MenuState

function MenuState:new()
    local instance = {}
    setmetatable(instance, self)
    return instance
end

function MenuState:enter()
    print("MenuState: enter")
    self.options = {'Nueva Partida', 'Cargar Partida', 'Opciones', 'Salir'}
    self.selected = 1
end

function MenuState:exit()
    print("MenuState: exit")
end

function MenuState:update(dt)
    local input = _G.Registry:get('input')

    -- Navegación del menú
    if input:pressed('move_down') then
        self.selected = self.selected + 1
        if self.selected > #self.options then
            self.selected = 1
        end
    end

    if input:pressed('move_up') then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #self.options
        end
    end

    if input:pressed('menu_confirm') or input:pressed('cast_spell') then
        self:selectOption(self.selected)
    end
end

function MenuState:selectOption(index)
    local option = self.options[index]
    local stateManager = _G.Registry:get('state_manager')

    if option == 'Nueva Partida' then
        stateManager:switch('hub')
    elseif option == 'Cargar Partida' then
        -- TODO: Sistema de guardado
        print("Cargar partida aún no implementado")
    elseif option == 'Opciones' then
        -- TODO: Menú de opciones
        print("Opciones aún no implementadas")
    elseif option == 'Salir' then
        love.event.quit()
    end
end

function MenuState:draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    -- Título
    love.graphics.setColor(0.8, 0.6, 1)
    love.graphics.printf("SPELL-CRAWLER", 0, height * 0.2, width, 'center')

    -- Opciones
    local startY = height * 0.4
    local lineHeight = 50

    for i, option in ipairs(self.options) do
        if i == self.selected then
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.printf("> " .. option .. " <", 0, startY + (i-1) * lineHeight, width, 'center')
        else
            love.graphics.setColor(0.6, 0.6, 0.7)
            love.graphics.printf(option, 0, startY + (i-1) * lineHeight, width, 'center')
        end
    end

    -- Instrucciones
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.printf("WASD / Flechas para moverse - ESPACIO / ENTER para seleccionar", 0, height - 50, width, 'center')
end

function MenuState:keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        love.event.quit()
    end
end

return MenuState
