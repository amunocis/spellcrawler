-- src/core/registry.lua
-- Sistema central de registro de dependencias.
-- Único punto de acceso global. Puro Registry pattern.

local Registry = {}
Registry.__index = Registry

function Registry:new()
    local instance = {
        _services = {},
        _metadata = {}
    }
    setmetatable(instance, self)
    return instance
end

function Registry:register(name, service, metadata)
    if self._services[name] then
        error("Service '" .. name .. "' is already registered")
    end

    self._services[name] = service
    self._metadata[name] = metadata or {}

    return service
end

function Registry:get(name)
    local service = self._services[name]
    if not service then
        error("Service '" .. name .. "' not found in registry")
    end
    return service
end

function Registry:try_get(name)
    return self._services[name]
end

function Registry:has(name)
    return self._services[name] ~= nil
end

function Registry:unregister(name)
    local service = self._services[name]
    self._services[name] = nil
    self._metadata[name] = nil
    return service
end

function Registry:replace(name, newService, metadata)
    local oldService = self._services[name]
    self._services[name] = newService
    self._metadata[name] = metadata or self._metadata[name] or {}
    return oldService
end

function Registry:get_metadata(name)
    return self._metadata[name]
end

function Registry:list()
    local names = {}
    for name, _ in pairs(self._services) do
        table.insert(names, name)
    end
    return names
end

function Registry:clear()
    self._services = {}
    self._metadata = {}
end

return Registry
