ESX.RegisterServerCallback('lunar_npcmechanic:pay', function(source, cb, option, index, vehicle)
    local xPlayer = ESX.GetPlayerFromId(source)
    if option == 'repair' then
        if xPlayer.getAccount('money').money >= Config.Repair.Price then
            xPlayer.removeAccountMoney('money', Config.Repair.Price)
            TriggerClientEvent('lunar_npcmechanic:startRepair', -1, index, vehicle)
            cb(true)
            Wait(Config.Repair.Duration)
            TriggerClientEvent('lunar_npcmechanic:end', -1, index)
        else
            cb(false)
        end
    else
        if xPlayer.getAccount('money').money >= Config.Clean.Price then
            xPlayer.removeAccountMoney('money', Config.Clean.Price)
            TriggerClientEvent('lunar_npcmechanic:startClean', -1, index, vehicle)
            cb(true)
            Wait(Config.Clean.Duration)
            TriggerClientEvent('lunar_npcmechanic:end', -1, index)
        else
            cb(false)
        end
    end
end)