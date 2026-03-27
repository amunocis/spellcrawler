-- src/utils/table_utils.lua
-- Utilidades para manipulación de tablas

local TableUtils = {}

function TableUtils.copy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            copy[k] = TableUtils.copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function TableUtils.copyShallow(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

function TableUtils.merge(target, source)
    for k, v in pairs(source) do
        target[k] = v
    end
    return target
end

function TableUtils.contains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

function TableUtils.find(t, value)
    for i, v in ipairs(t) do
        if v == value then return i end
    end
    return nil
end

function TableUtils.removeByValue(t, value)
    local index = TableUtils.find(t, value)
    if index then
        table.remove(t, index)
        return true
    end
    return false
end

function TableUtils.filter(t, predicate)
    local result = {}
    for _, v in ipairs(t) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

function TableUtils.map(t, mapper)
    local result = {}
    for i, v in ipairs(t) do
        result[i] = mapper(v)
    end
    return result
end

function TableUtils.keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

function TableUtils.values(t)
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

function TableUtils.shuffle(t)
    local result = TableUtils.copyShallow(t)
    for i = #result, 2, -1 do
        local j = math.random(i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

return TableUtils
