--!strict

local Cleaner = {}
Cleaner.__index = Cleaner

export type Cleaner = typeof(setmetatable({
    _connections = {} :: {RBXScriptConnection},
    _tasks = {} :: {thread},
    _instances = {} :: {Instance}
}, Cleaner))

function Cleaner.new(): Cleaner
    local self = setmetatable({
        _connections = {},
        _tasks = {},
        _instances = {}
    }, Cleaner)

    return self
end

function Cleaner:AddConnection(connection: RBXScriptConnection): RBXScriptConnection
    table.insert(self._connections, connection)
    return connection
end

function Cleaner:AddTask(taskFunction: () -> ()): thread
    local task = task.spawn(taskFunction)
    table.insert(self._tasks, task)
    return task
end

function Cleaner:AddInstance(instance: Instance): Instance
    table.insert(self._instances, instance)
    return instance
end

function Cleaner:Clean(): ()
    for _, connection in self._connections do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    
    for _, taskThread in self._tasks do
        task.cancel(taskThread)
    end
    
    for _, instance in self._instances do
        if instance.Parent then
            instance:Destroy()
        end
    end
    
    table.clear(self._connections)
    table.clear(self._tasks)
    table.clear(self._instances)
end

function Cleaner:Destroy(): ()
    self:Clean()
end

return Cleaner
