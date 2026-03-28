-- spec/helper.lua
-- Configuración global para tests

-- Mock de LÖVE para tests sin necesidad de ejecutar el juego
local function createLoveMock()
    return {
        graphics = {
            setColor = function() end,
            rectangle = function() end,
            circle = function() end,
            line = function() end,
            printf = function() end,
            print = function() end,
            getWidth = function() return 800 end,
            getHeight = function() return 600 end,
            push = function() end,
            pop = function() end,
            translate = function() end,
            setBackgroundColor = function() end
        },
        keyboard = {
            isDown = function() return false end
        },
        mouse = {
            getPosition = function() return 0, 0 end,
            isDown = function() return false end
        },
        joystick = {
            getJoysticks = function() return {} end
        },
        event = {
            quit = function() end
        }
    }
end

-- Crear mock global solo si no estamos en LÖVE real
if not love then
    _G.love = createLoveMock()
end

-- Registry mock para tests
_G.Registry = {
    _data = {},
    register = function(self, key, value)
        self._data[key] = value
    end,
    get = function(self, key)
        return self._data[key]
    end
}

-- Seed for deterministic tests (avoids random failures)
math.randomseed(12345)

print("Test environment loaded")
