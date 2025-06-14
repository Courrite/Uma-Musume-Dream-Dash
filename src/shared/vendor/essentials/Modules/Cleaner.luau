--!strict

local Cleaner = {}
Cleaner.__index = Cleaner

export type Cleaner = typeof(setmetatable({
    _connections = {} :: {RBXScriptConnection}
}, Cleaner))

function Cleaner.new(): Cleaner
    local self = setmetatable({
        _connections = {},
    }, Cleaner)
    return self
end

function Cleaner:Add(connection: RBXScriptConnection): RBXScriptConnection
    table.insert(self._connections, connection)
    return connection
end

function Cleaner:Clean(): ()
    local activeConnections = {}
    
    for _, connection in self._connections do
        if connection.Connected then
            table.insert(activeConnections, connection)
        end
    end
    
    self._connections = activeConnections
end

function Cleaner:Destroy(): ()
    self:Clean()
end

return Cleaner