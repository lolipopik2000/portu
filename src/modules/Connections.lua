local Connections = {}
shared.connections = {}

function Connections:AddConnection(con)
    table.insert(shared.connections, con)
end

function Connections:RemoveConnection(con)
    if con.Connected and table.find(shared.connections) then 
        con:Disconnect()
        table.remove(shared.connections, table.find(shared.connections, con))
    end
end

function Connections:RemoveAll()
    for _, con in pairs(shared.connections) do 
        if con.Connected then 
            con:Disconnect()
        end
    end
end

return Connections
