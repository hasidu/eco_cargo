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
            data = result
        })
    end)
end)