RegisterNetEvent("filo_tow_attachVehicle", function(vehicle1, vehicle2)
    local ent1 = NetworkGetEntityFromNetworkId(vehicle1)
    local ent2 = NetworkGetEntityFromNetworkId(vehicle2)

    Entity(ent2).state:set("attached", vehicle1, true)

    if Entity(ent1).state.attachedVehicle then
        local data = json.decode(Entity(ent1).state.attachedVehicle)
        data[#data + 1 ] = vehicle2

        Entity(ent1).state:set("attachedVehicle", json.encode(data), true)
    else
        
        Entity(ent1).state:set("attachedVehicle", json.encode({
            vehicle2
        }), true)
    end
end)

RegisterNetEvent("filo_tow_detachVehicle", function(vehicle1, vehicle2)
    local ent1 = NetworkGetEntityFromNetworkId(vehicle1)
    local ent2 = NetworkGetEntityFromNetworkId(vehicle2)

    Entity(ent2).state:set("attached", nil, true)
    local attachedData = json.decode(Entity(ent1).state.attachedVehicle)
    for i = 1, #attachedData do
        if attachedData[i] == vehicle2 then
            table.remove(attachedData, i)
            break
        end
    end

    Entity(ent1).state:set("attachedVehicle", json.encode(attachedData), true)
end)