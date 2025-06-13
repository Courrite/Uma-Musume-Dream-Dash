--!strict

local Observer = {}
Observer.__index = Observer

export type Observer<T> = typeof(setmetatable({
    ["_value"] = (nil :: any) :: T,
    ["_observers"] = {} :: {any}
}, Observer))

function Observer.new<T>(initialValue: T): Observer<T>
    local self = setmetatable({
        _value = initialValue,
        _observers = {}
    }, Observer)
    return self
end

function Observer:Get()
    return self._value
end

function Observer:Set(newValue)
    local oldValue = self._value
    if oldValue ~= newValue then
        self._value = newValue
        self:_notify(newValue, oldValue)
    end
end

function Observer:Subscribe(callback: (newValue: any, oldValue: any) -> ()): () -> ()
    table.insert(self._observers, callback)

    return function()
        self:Unsubscribe(callback)
    end
end

function Observer:Unsubscribe(callback)
    for i, observer in ipairs(self._observers) do
        if observer == callback then
            table.remove(self._observers, i)
            break
        end
    end
end

function Observer:Map<U>(transform: (value: any) -> U): Observer<U>
    local mappedObserver = Observer.new(transform(self._value))
    
    self:Subscribe(function(newValue, _oldValue)
        mappedObserver:Set(transform(newValue))
    end)
    
    return mappedObserver
end

function Observer:Filter(predicate: (value: any) -> boolean): Observer<any>
    local filteredObserver = Observer.new(self._value)
    
    self:Subscribe(function(newValue, oldValue)
        if predicate(newValue) then
            filteredObserver:Set(newValue)
        end
    end)
    
    return filteredObserver
end

function Observer:_notify(newValue, oldValue)
    for _, callback in ipairs(self._observers) do
        task.spawn(callback, newValue, oldValue)
    end
end

return Observer
