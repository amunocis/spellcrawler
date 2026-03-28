-- spec/core/input_manager_spec.lua
-- Tests para InputManager con soporte completo de gamepad

local InputManager = require('src.core.input_manager')

describe('InputManager', function()
  local input

  before_each(function()
    input = InputManager:new()
    input:setupDefaultMappings()
  end)

  describe('basic input API', function()
    it('should create InputManager instance', function()
      assert.is_not_nil(input)
      assert.is_table(input._mappings)
      assert.is_table(input._states)
    end)

    it('should setup default mappings on creation', function()
      assert.is_not_nil(input._mappings['move_left'])
      assert.is_not_nil(input._mappings['move_right'])
      assert.is_not_nil(input._mappings['cast_spell'])
      assert.is_not_nil(input._mappings['spell_1'])
      assert.is_not_nil(input._mappings['spell_2'])
    end)

    it('should allow custom mapping', function()
      input:map('test_action', {'key:t'})
      assert.is_not_nil(input._mappings['test_action'])
      assert.are.same({'key:t'}, input._mappings['test_action'])
    end)
  end)

  describe('gamepad connection detection', function()
    it('should return false when no gamepad is connected', function()
      -- Mock: no joysticks available
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {} end
      
      assert.is_false(input:isGamepadConnected())
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should return true when a gamepad is connected', function()
      local mockGamepad = { isGamepad = function() return true end }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      assert.is_true(input:isGamepadConnected())
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should return nil when no gamepad is connected', function()
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {} end
      
      assert.is_nil(input:getActiveGamepad())
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should return active gamepad when connected', function()
      local mockGamepad = { isGamepad = function() return true end }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      assert.are.equal(mockGamepad, input:getActiveGamepad())
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)
  end)

  describe('analog movement', function()
    it('should return 0,0 when no input', function()
      local x, y = input:getAnalogMovement()
      assert.are.equal(0, x)
      assert.are.equal(0, y)
    end)

    it('should return normalized vector for analog input', function()
      local mockGamepad = {
        isGamepad = function() return true end,
        getGamepadAxis = function(self, axis)
          if axis == 'leftx' then return 0.5 end
          if axis == 'lefty' then return 0.0 end
          return 0
        end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      local x, y = input:getAnalogMovement()
      assert.is_true(x > 0)
      assert.are.equal(0, y)
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should apply deadzone to analog movement', function()
      local mockGamepad = {
        isGamepad = function() return true end,
        getGamepadAxis = function(self, axis)
          if axis == 'leftx' then return 0.1 end -- Below default deadzone
          return 0
        end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      local x, y = input:getAnalogMovement()
      assert.are.equal(0, x) -- Should be filtered by deadzone
      assert.are.equal(0, y)
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should clamp analog movement to max length of 1', function()
      local mockGamepad = {
        isGamepad = function() return true end,
        getGamepadAxis = function(self, axis)
          if axis == 'leftx' then return 1.0 end
          if axis == 'lefty' then return 1.0 end
          return 0
        end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      local x, y = input:getAnalogMovement()
      local length = math.sqrt(x*x + y*y)
      assert.is_true(length <= 1.01) -- Allow small floating point error
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)
  end)

  describe('analog aim', function()
    it('should return 0,0 when no aim input', function()
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {} end
      
      local x, y = input:getAnalogAim(400, 300)
      -- When no input, returns 0,0
      assert.are.equal(0, x)
      assert.are.equal(0, y)
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should return right stick direction when gamepad aims', function()
      local mockGamepad = {
        isGamepad = function() return true end,
        getGamepadAxis = function(self, axis)
          if axis == 'rightx' then return 0.8 end
          if axis == 'righty' then return 0.0 end
          return 0
        end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      local x, y = input:getAnalogAim(400, 300)
      assert.is_true(x > 0)
      assert.are.equal(0, y)
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should apply deadzone to analog aim', function()
      local mockGamepad = {
        isGamepad = function() return true end,
        getGamepadAxis = function(self, axis)
          if axis == 'rightx' then return 0.19 end -- Below deadzone of 0.2
          return 0
        end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      local x, y = input:getAnalogAim(400, 300)
      assert.are.equal(0, x) -- Filtered by deadzone
      assert.are.equal(0, y)
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)
  end)

  describe('d-pad support', function()
    it('should have d-pad mapped for movement', function()
      -- Check that d-pad buttons are in the mappings
      local hasDPadLeft = false
      local hasDPadRight = false
      local hasDPadUp = false
      local hasDPadDown = false
      
      for _, inp in ipairs(input._mappings['move_left'] or {}) do
        if inp == 'button:dpleft' then hasDPadLeft = true end
      end
      for _, inp in ipairs(input._mappings['move_right'] or {}) do
        if inp == 'button:dpright' then hasDPadRight = true end
      end
      for _, inp in ipairs(input._mappings['move_up'] or {}) do
        if inp == 'button:dpup' then hasDPadUp = true end
      end
      for _, inp in ipairs(input._mappings['move_down'] or {}) do
        if inp == 'button:dpdown' then hasDPadDown = true end
      end
      
      assert.is_true(hasDPadLeft, 'dpleft should be mapped to move_left')
      assert.is_true(hasDPadRight, 'dpright should be mapped to move_right')
      assert.is_true(hasDPadUp, 'dpup should be mapped to move_up')
      assert.is_true(hasDPadDown, 'dpdown should be mapped to move_down')
    end)

    it('should detect d-pad button presses', function()
      local mockGamepad = {
        isGamepad = function() return true end,
        isGamepadDown = function(self, button)
          return button == 'dpleft'
        end,
        getGamepadAxis = function() return 0 end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      -- Update to process inputs
      input:update(0.016)
      
      assert.is_true(input:isDown('move_left'))
      assert.is_false(input:isDown('move_right'))
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)
  end)

  describe('spell mappings', function()
    it('should have spell_3 mapped to button:y', function()
      local hasY = false
      for _, inp in ipairs(input._mappings['spell_3'] or {}) do
        if inp == 'button:y' then hasY = true end
      end
      assert.is_true(hasY, 'spell_3 should be mapped to Y button')
    end)

    it('should have spell_4 mapped to rightstick click', function()
      local hasRightStick = false
      for _, inp in ipairs(input._mappings['spell_4'] or {}) do
        if inp == 'button:rightstick' then hasRightStick = true end
      end
      assert.is_true(hasRightStick, 'spell_4 should be mapped to right stick click')
    end)
  end)

  describe('vibration', function()
    it('should call setVibration on active gamepad', function()
      local vibrationCalled = false
      local leftMotor, rightMotor
      
      local mockGamepad = {
        isGamepad = function() return true end,
        setVibration = function(self, left, right)
          vibrationCalled = true
          leftMotor = left
          rightMotor = right
        end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      input:setVibration(0.5, 0.5)
      
      assert.is_true(vibrationCalled)
      assert.are.equal(0.5, leftMotor)
      assert.are.equal(0.5, rightMotor)
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should not error when no gamepad connected', function()
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {} end
      
      -- Should not throw error
      local ok, err = pcall(function()
        input:setVibration(0.5, 0.5)
      end)
      
      assert.is_true(ok, 'setVibration should not error without gamepad')
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)

    it('should stop vibration when called with 0,0', function()
      local stopCalled = false
      
      local mockGamepad = {
        isGamepad = function() return true end,
        setVibration = function(self, left, right)
          if left == 0 and right == 0 then
            stopCalled = true
          end
        end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      input:setVibration(0, 0)
      
      assert.is_true(stopCalled)
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)
  end)

  describe('response curve', function()
    it('should apply response curve to analog input', function()
      -- Test that small inputs are amplified (more sensitive at low values)
      local mockGamepad = {
        isGamepad = function() return true end,
        getGamepadAxis = function(self, axis)
          if axis == 'leftx' then return 0.5 end
          return 0
        end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      -- Get movement with default curve
      local x1, y1 = input:getAnalogMovement()
      
      -- With response curve, 0.5 input should produce higher output
      -- The exact value depends on the curve implementation
      assert.is_true(x1 >= 0.5, 'Response curve should maintain or amplify input')
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)
  end)

  describe('menu navigation with gamepad', function()
    it('should have menu_back mapped to button:b', function()
      local hasButtonB = false
      for _, inp in ipairs(input._mappings['menu_back'] or {}) do
        if inp == 'button:b' then hasButtonB = true end
      end
      assert.is_true(hasButtonB, 'menu_back should be mapped to B button')
    end)

    it('should detect menu back press with gamepad', function()
      local mockGamepad = {
        isGamepad = function() return true end,
        isGamepadDown = function(self, button)
          return button == 'b'
        end,
        getGamepadAxis = function() return 0 end
      }
      local originalGetJoysticks = love.joystick.getJoysticks
      love.joystick.getJoysticks = function() return {mockGamepad} end
      
      input:update(0.016)
      
      assert.is_true(input:isDown('menu_back'))
      
      love.joystick.getJoysticks = originalGetJoysticks
    end)
  end)
end)
