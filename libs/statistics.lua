--
-- Created by IntelliJ IDEA.
-- User: ekhion
-- Date: 2020. 12. 27.
-- Time: 13:57
--

RegisterCommand('cargostat', function()

    ESX.TriggerServerCallback('eco_cargo:getStatistics', function(result)

        SetNuiFocus(true, true)

        SendNUIMessage({
            subject = 'STATISTICS',
            operation = 'open',
            data = result[1] and result[1] or {}
        })
    end)
end)

RegisterNUICallback('myStatistics', function(data, cb)

    ExecuteCommand('cargostat')
    cb('ok')
end)


RegisterNUICallback('getAllStatistics', function(data, cb)

    ESX.TriggerServerCallback('eco_cargo:getAllStatistics', function(result)

        cb(json.encode(result))
    end, data)
end)



