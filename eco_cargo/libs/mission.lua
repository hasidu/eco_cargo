--
-- Created by IntelliJ IDEA.
-- User: ekhion
-- Date: 2020. 12. 06.
-- Time: 10:30
--
RegisterNUICallback('missionRegister', function(data, cb)

    local time = GetGameTimer()
    local targetPlayers = 0

    if data.defender and type(data.required_defenders) == 'number' then

        targetPlayers = countPlayers(data.defender)
    end


    if not ECO.MONITOR.callDefenseTime or ECO.MONITOR.callDefenseTime < time then

        if targetPlayers > 0 then

            local counterFactions = {}
            local counters = 0

            -- calc counters
            if in_table(data.defender, Config.lawEnforcementFactions) then

                counterFactions = Config.illegalFactions
            else

                counterFactions = Config.lawEnforcementFactions
            end


            for i = 1, #counterFactions do

                counters = counters + countPlayers(counterFactions[i])
            end


            if counters >= data.required_defenders then

                local missionId = concatId(data.loadingZoneId, data.productId, '_')

                -- VÉDELEM KÉRŐ ÜZENET KÜLDÉSE:
                TriggerServerEvent('eco_cargo:missionRegister', {
                    missionId = missionId,
                    productId = data.productId,
                    loadingZoneId = data.loadingZoneId,
                    defender = data.defender,
                    owner = ECO.PLAYER
                })

                ECO.MONITOR.callDefenseTime = time + 60000

                cb(json.encode({
                    state = true,
                    type = "information",
                    message = _('invited_players', targetPlayers)
                }))
            else

                cb(json.encode({
                    state = false,
                    type = "warning",
                    message = _('too_few_counter_players_available')
                }))
            end
        else

            cb(json.encode({
                state = false,
                type = "warning",
                message = _('too_few_defensive_players_available')
            }))
        end
    else

        cb(json.encode({
            state = false,
            type = "warning",
            message = _('please_wait', 60)
        }))
    end
end)

RegisterNUICallback('checkDefense', function(data, cb)

    local time = GetGameTimer()
    local numberOfDefenders = 0

    if not ECO.MONITOR.checkDefenseTime or ECO.MONITOR.checkDefenseTime < time then

        if data.defender and type(data.required_defenders) == 'number' then

            numberOfDefenders = countDefenders(data.defender)

            cb(json.encode({
                state = numberOfDefenders >= data.required_defenders,
                type = "information",
                message = _('found_defenders', numberOfDefenders)
            }))

            ECO.MONITOR.checkDefenseTime = time + 10000
            TriggerServerEvent('eco_cargo:showCountingZone', GetEntityCoords(_PlayerPedId))
        end
    else

        cb(json.encode({
            state = false,
            type = "warning",
            message = _('please_wait', 10)
        }))
    end
end)

-- DEFENDER COUNTING ZONE
RegisterNetEvent('eco_cargo:showCountingZone')
AddEventHandler('eco_cargo:showCountingZone', function(coord)

    Citizen.CreateThread(function()

        local myPosition
        local time = GetGameTimer() + 10000

        while time > GetGameTimer() do

            Citizen.Wait(0)

            myPosition = GetEntityCoords(_PlayerPedId)

            if #(myPosition - coord) < 100 then

                DrawMarker(1,
                    coord.x,
                    coord.y,
                    coord.z - 1,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.countingZoneRadius + 0.0, Config.countingZoneRadius + 0.0, 8.0,
                    253, 88, 0, 155,
                    false, -- bobUpAndDown
                    true, 2, false, false, false, false)
            end
        end
    end)
end)

function countDefenders(defender)

    local zoneCenter = GetEntityCoords(_PlayerPedId)
    local ped, serverId, job
    local defenders = 0

    for _, player in ipairs(GetActivePlayers()) do

        ped = GetPlayerPed(player)

        if DoesEntityExist(ped) and not IsEntityDead(ped) then

            if #(zoneCenter - GetEntityCoords(ped)) < Config.countingZoneRadius + 0.0 then

                serverId = GetPlayerServerId(player)

                job = ECO.PLAYERS[serverId] or 'unknown'

                if job == defender and serverId ~= ECO.PLAYER['serverId'] then

                    defenders = defenders + 1
                end
            end
        end
    end

    return defenders
end

-- MISSION PAGE HANDLER
RegisterNUICallback('setWaypoint', function(data, cb)

    SetNuiFocus(false, false)

    local zoneId, productId = table.unpack(explode(data.missionId, '_'))
    local zone = ECO.allZones[tonumber(zoneId)]

    if zone then

        local coord = zone.actionpoint[1][1]

        DeleteWaypoint()
        SetNewWaypoint(coord.x, coord.y)

        DoCustomHudText('information', _('loading_point_marked'))
    end

    cb('ok')
end)

RegisterNUICallback('setDestinationWaypoint', function(data, cb)

    SetNuiFocus(false, false)

    local mission = ECO.MISSION[data.missionId]

    if mission then

        local zone = ECO.allZones[tonumber(mission.destinationZoneId)]
        local coord = zone.actionpoint[1][1]

        DeleteWaypoint()
        SetNewWaypoint(coord.x, coord.y)

        DoCustomHudText('information', _('destination_point_marked'))
    end

    cb('ok')
end)

RegisterNUICallback('missionJoin', function(data, cb)

    SetNuiFocus(false, false)

    if ECO.MISSION[data.missionId] then

        TriggerServerEvent('eco_cargo:missionUpdate', data, 'join')
    else

        DoCustomHudText('error', _('mission_does_not_exist'))
    end

    cb('ok')
end)

RegisterNUICallback('missionLeave', function(data, cb)

    SetNuiFocus(false, false)

    TriggerServerEvent('eco_cargo:missionUpdate', data, 'leave')

    cb('ok')
end)

RegisterNUICallback('missionDelete', function(data, cb)

    SetNuiFocus(false, false)

    TriggerServerEvent('eco_cargo:missionUpdate', data, 'delete')

    cb('ok')
end)

RegisterNetEvent('eco_cargo:trailerSignal')
AddEventHandler('eco_cargo:trailerSignal', function(coords, state)

    if ECO.MONITOR.trailerSignal and DoesBlipExist(ECO.MONITOR.trailerSignal) then

        RemoveBlip(ECO.MONITOR.trailerSignal)
    end

    if state then

        ECO.MONITOR.trailerSignal = createBlip(coords, Config.missionBlipSprite, Config.missionBlipColor, _('mission_trailer_signal'))
    end
end)

RegisterNetEvent('eco_cargo:addAlarmBlip')
AddEventHandler('eco_cargo:addAlarmBlip', function(player)

    local ped = GetPlayerPed(player)
    local blip = GetBlipFromEntity(ped)

    if not DoesBlipExist(blip) then

        blip = AddBlipForEntity(ped)
        SetBlipSprite(blip, 42)
    end
end)

RegisterCommand('mission', function()

    if next(ECO.MISSION) == nil then

        DoCustomHudText('fail', _('no_missions'))
    else

        local mission, product = {}, {}

        for k, v in pairs(ECO.MISSION) do

            local loadingZoneId, productId = table.unpack(explode(k, '_'))


            mission[k] = v
            mission[k].loadingZone = ECO.allZones[tonumber(loadingZoneId)]

            product = ECO.allProducts[tonumber(productId)]

            mission[k].product = product
            mission[k].product.label = _(product.name)
            mission[k].product.defenderLabel = _(product.defender)
        end

        SetNuiFocus(true, true)

        SendNUIMessage({
            subject = 'MISSION_LIST',
            mission = mission,
            player = ECO.PLAYER
        })
    end
end)