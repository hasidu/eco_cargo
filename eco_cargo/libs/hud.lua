--
-- Created by IntelliJ IDEA.
-- User: ekhion
-- Date: 2020. 11. 14.
-- Time: 10:36
--

function setHud()

    local presetName

    -- HUD PRESET SELECT
    if ECO.PLAYER.isApprovedDriver then

        if ECO.MONITOR.towing then

            if ECO.targetZone[1] then

                presetName = 'deliveryInformation'
            else

                presetName = 'notification'
            end
        else

            presetName = 'notification'
        end
    else

        presetName = 'hide'
    end


    -- HUD SETTINGS
    if ECO.MONITOR.hud == presetName then return end

    if presetName == 'deliveryInformation' then

        local data = {}
        local product = ECO.allProducts[tonumber(ECO.CARGO.productId)]


        data.targetZone = ECO.allZones[tonumber(ECO.CARGO.destinationZoneId)]
        data.productProperties = product.properties
        data.productName = _(product.name) or product.name
        data.speedLimit = Config.speedLimit['country']
        data.trailerHealth = 0
        data.goodsQuality = 0

        if ECO.CARGO.trailerHealth then

            data.trailerHealth = math.round(ECO.CARGO.trailerHealth * 0.1)
        end

        if ECO.CARGO.quality then

            data.goodsQuality = math.round(ECO.CARGO.quality)
        end

        SendNUIMessage({
            subject = "DELIVERY_INFO",
            deliveryData = data
        })
    elseif presetName == 'notification' then

        SendNUIMessage({
            subject = "CLOSE_INFO",
        })

        DoCustomHudText("information", _('promotion_message'), 10000)
    else

        SendNUIMessage({
            subject = "CLOSE_INFO",
        })
    end

    ECO.MONITOR.hud = presetName
end

function sendHudLiveData(paramName, value)

    --[[if not ECO.MONITOR.hasAlreadyNotify[paramName] then

        ECO.MONITOR.hasAlreadyNotify[paramName] = true
    end]]
    if ECO.MONITOR.towing then

        SendNUIMessage({
            subject = "UPDATE",
            paramName = paramName,
            value = value
        })
    end
end

function sendHudActionData(actionData, operation)

    SendNUIMessage({
        subject = "ACTION_INFO",
        operation = operation, -- append, close
        actionData = actionData
    })
end

function DoCustomHudText(type, text, length, style)

    SendNUIMessage({
        type = type,
        text = text,
        length = length,
        style = style,
        subject = "NOTIFICATION"
    })
end

RegisterNetEvent('eco_cargo:showNotification')
AddEventHandler('eco_cargo:showNotification', function(data)

    DoCustomHudText(data.type, data.text, data.length, data.style)
end)

RegisterNetEvent('eco_cargo:missionNotification')
AddEventHandler('eco_cargo:missionNotification', function(data)

    if ECO.PLAYER.job then

        if (data.defender and data.defender == ECO.PLAYER.job.name) or (data.owner and data.owner.identifier == ECO.PLAYER.identifier) then

            DoCustomHudText(data.type, data.text, data.length, data.style)

            if data.showChat then

                TriggerEvent("chat:addMessage", { args = { "^1[ECO CARGO]", data.text } })
            end

        elseif data.otherText then

            TriggerEvent("chat:addMessage", { args = { "^1[ECO CARGO]", data.otherText } })
        end
    end
end)