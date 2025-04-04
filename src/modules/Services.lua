local Services = {}
shared.Services = {}

local cloneref = cloneref or function(i) return i end

function Services:GetService(serviceName)
    if shared.Services[serviceName] then return shared.Services[serviceName] end

    local service = cloneref(game:GetService(serviceName))
    shared[serviceName] = service

    return service
end

function Services:GetServices(serviceNames)
    for i, serviceName in pairs(serviceNames) do 
        Services:GetService(serviceName)
    end
end

return Services
