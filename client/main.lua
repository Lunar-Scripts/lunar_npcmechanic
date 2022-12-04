local peds = {}
local isBusy = {}
local currentZone = nil

function ShowNotification(message, notifyType)
    lib.notify({
        description = message,
        type = notifyType
    })
end

function ShowUI(message, icon)
    if icon == 0 then
        lib.showTextUI(message)
    else
        lib.showTextUI(message, {
            icon = icon
        })
    end
end

function HideUI()
    lib.hideTextUI()
end

RegisterNetEvent('lunar_npcmechanic:startRepair')
AddEventHandler('lunar_npcmechanic:startRepair', function(index, vehicle)
    --Check if far away
    if #(GetEntityCoords(PlayerPedId()) - Config.Locations[index].VehiclePoint) < 400 then
        isBusy[index] = true
        local vehicle = NetworkGetEntityFromNetworkId(vehicle)
        local mechanic = peds[index]
        FreezeEntityPosition(mechanic, false)
        local pos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'engine'))
        TaskGoToCoordAnyMeans(mechanic, pos.x, pos.y, pos.z, 1.0, 0, 0, 786603, 0xbf800000)
        while #(GetEntityCoords(mechanic) - pos) > 1.75 do
            Wait(200)
        end
        TaskTurnPedToFaceCoord(mechanic, pos.x, pos.y, pos.z, -1)
        SetVehicleDoorOpen(vehicle, 4, false)
        Wait(1000)
        TaskStartScenarioInPlace(mechanic, 'PROP_HUMAN_BUM_BIN', 0, true)
    end
end)

RegisterNetEvent('lunar_npcmechanic:startClean')
AddEventHandler('lunar_npcmechanic:startClean', function(index, vehicle)
    --Check if far away
    if #(GetEntityCoords(PlayerPedId()) - Config.Locations[index].VehiclePoint) < 400 then
        isBusy[index] = true
        local vehicle = NetworkGetEntityFromNetworkId(vehicle)
        local mechanic = peds[index]
        FreezeEntityPosition(mechanic, false)
        local pos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'window_lf'))
        TaskGoToCoordAnyMeans(mechanic, pos.x, pos.y, pos.z, 1.0, 0, 0, 786603, 0xbf800000)
        while #(GetEntityCoords(mechanic) - pos) > 1.35 do
            Wait(200)
        end
        TaskTurnPedToFaceCoord(mechanic, pos.x, pos.y, pos.z, -1)
        Wait(1000)
        TaskStartScenarioInPlace(mechanic, 'WORLD_HUMAN_MAID_CLEAN', 0, true)
    end
end)

--Don't check for distance so you can be sure that he ends up in the spawn position
RegisterNetEvent('lunar_npcmechanic:end')
AddEventHandler('lunar_npcmechanic:end', function(index)
    
    local mechanic = peds[index]
    ClearPedTasks(mechanic)
    local x, y, z, heading = table.unpack(Config.Locations[index].MechanicPosition)
    TaskGoToCoordAnyMeans(mechanic, x, y, z, 1.0)
    while #(GetEntityCoords(mechanic) - vector3(x, y, z)) > 1.25 do
        Wait(200)
    end
    TaskAchieveHeading(mechanic, heading)
    while Absf(GetEntityHeading(mechanic) - heading) > 10.0 do
        Wait(200)
    end
    FreezeEntityPosition(mechanic, true)
    isBusy[index] = nil
end)

function RepairVehicle(vehicle, index)
    currentZone = nil
    HideUI()
    FreezeEntityPosition(vehicle, true)
    if lib.progressBar({
        duration = Config.Repair.Duration,
        label = _U('npc_repairing'),
        useWhileDead = false,
        canCancel = false,
    }) then
        SetVehicleDoorShut(vehicle, 4, false)
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true)
        ShowNotification(_U('repair_success'), 'success')
        FreezeEntityPosition(vehicle, false)
    end
end

function CleanVehicle(vehicle, index)
    currentZone = nil
    HideUI()
    FreezeEntityPosition(vehicle, true)
    if lib.progressBar({
        duration = Config.Clean.Duration,
        label = _U('npc_cleaning'),
        useWhileDead = false,
        canCancel = false,
    }) then
        SetVehicleDirtLevel(vehicle, 0)
        ShowNotification(_U('clean_success'), 'success')
        FreezeEntityPosition(vehicle, false)
    end
end

function CreateBlip(position)
    local blip = AddBlipForCoord(position.x, position.y, position.z)

	SetBlipSprite(blip, Config.Blip.Type)
	SetBlipDisplay(blip, 4)
	SetBlipScale(blip, Config.Blip.Size)
	SetBlipColour(blip, Config.Blip.Color)
    SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(_U('npc_mechanic'))
	EndTextCommandSetBlipName(blip)
end

Citizen.CreateThread(function()
    for _,v in ipairs(Config.Locations) do
        lib.requestModel(`mp_m_waremech_01`)
        ped = CreatePed(4, `mp_m_waremech_01`, v.MechanicPosition, false, true)
        CreateBlip(v.MechanicPosition)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        table.insert(peds, ped)
    end
    lib.registerContext({
        id = 'npcmechanic_menu',
        title = _U('npc_mechanic'),
        options = {
            {
                title = _U('repair_vehicle'),
                description = _U('price', Config.Repair.Price),
                onSelect = function(args)
                    local vehicle = GetVehiclePedIsIn(PlayerPedId())
                    ESX.TriggerServerCallback('lunar_npcmechanic:pay', function(success) 
                        if success then
                            RepairVehicle(vehicle, currentZone)
                        else
                            ShowNotification(_U('no_money'), 'error')
                        end
                    end, 'repair', currentZone, NetworkGetNetworkIdFromEntity(vehicle))
                end
            },
            {
                title = _U('clean_vehicle'),
                description = _U('price', Config.Clean.Price),
                onSelect = function(args)
                    local vehicle = GetVehiclePedIsIn(PlayerPedId())
                    ESX.TriggerServerCallback('lunar_npcmechanic:pay', function(success) 
                        if success then
                            CleanVehicle(vehicle, currentZone)
                        else
                            ShowNotification(_U('no_money'), 'error')
                        end
                    end, 'clean', currentZone, NetworkGetNetworkIdFromEntity(vehicle))
                end
            },
        },
    })
end)

RegisterKeyMapping('npcmechanicinteract', 'E Pressed', 'keyboard', 'e')

RegisterCommand('npcmechanicinteract', function(source, args, raw)
    if currentZone ~= nil then 
        lib.showContext('npcmechanic_menu')
    end
end)

--Draw markers.
Citizen.CreateThread(function()
    while true do
        Wait(500)
        local sleep = true
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) and IsEntityDead(playerPed) == false then
            for k,v in ipairs(Config.Locations) do
                if isBusy[k] == nil then
                    local dist = #(GetEntityCoords(playerPed) - v.VehiclePoint)
                    if dist < 2.0 and currentZone == nil then
                        currentZone = k
                        local message = _U('mechanic_prompt')
                        ShowUI(message, 'wrench')
                    elseif dist > 2.0 and currentZone == k then
                        currentZone = nil
                        HideUI()
                    end
                elseif currentZone == k then
                    currentZone = nil
                    HideUI()
                end
            end
        else
            if lib.getOpenContextMenu() == 'npcmechanic_menu' then
                lib.hideContext()
                currentZone = nil
                HideUI()
            end
            if currentZone ~= nil then
                currentZone = nil
                HideUI()
            end
        end
    end
end)