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

function Cleaner:Remove(connection: RBXScriptConnection): boolean
    for i, conn in self._connections do
        if conn == connection then
            table.remove(self._connections, i)
            return true
        end
    end
    return false
end

function Cleaner:Clean(): ()
    for _, connection in self._connections do
        if connection.Connected then
            continue
        end

        connection.Disconnect()
    end
    
    table.clear(self._connections)
end

function Cleaner:Destroy(): ()
    self:Clean()
end

function Cleaner:__call(connection: RBXScriptConnection): RBXScriptConnection
    return self:Add(connection)
end

return Cleaner
