-- src/core/event_bus.lua
-- Bus de eventos síncrono.
-- Si en el futuro necesitamos asíncrono, solo cambiamos este módulo.

local EventBus = {}
EventBus.__index = EventBus

function EventBus:new()
    local instance = {
        _listeners = {},
        _queue = {},
        _processing = false
    }
    setmetatable(instance, self)
    return instance
end

function EventBus:on(eventName, callback, context)
    if not self._listeners[eventName] then
        self._listeners[eventName] = {}
    end

    table.insert(self._listeners[eventName], {
        callback = callback,
        context = context
    })

    -- Retornar función para desuscribirse
    return function()
        self:off(eventName, callback, context)
    end
end

function EventBus:off(eventName, callback, context)
    local listeners = self._listeners[eventName]
    if not listeners then return end

    for i = #listeners, 1, -1 do
        local listener = listeners[i]
        if listener.callback == callback and listener.context == context then
            table.remove(listeners, i)
            break
        end
    end
end

function EventBus:emit(eventName, ...)
    -- Modo síncrono: procesar inmediatamente
    self:_dispatch(eventName, ...)
end

function EventBus:queue(eventName, ...)
    -- Encolar para procesar al final del frame (útil si necesitamos cambiar luego)
    table.insert(self._queue, {
        event = eventName,
        args = {...}
    })
end

function EventBus:process(dt)
    -- Procesar eventos encolados
    if #self._queue == 0 then return end

    -- Copiar cola para evitar modificar durante iteración
    local toProcess = self._queue
    self._queue = {}

    for _, item in ipairs(toProcess) do
        self:_dispatch(item.event, unpack(item.args))
    end
end

function EventBus:_dispatch(eventName, ...)
    local listeners = self._listeners[eventName]
    if not listeners then return end

    for _, listener in ipairs(listeners) do
        if listener.context then
            listener.callback(listener.context, ...)
        else
            listener.callback(...)
        end
    end
end

function EventBus:clear(eventName)
    if eventName then
        self._listeners[eventName] = nil
    else
        self._listeners = {}
    end
end

return EventBus
