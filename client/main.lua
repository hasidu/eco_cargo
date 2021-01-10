ESX = nil
ECO = {
    blips = {},
    zones = {},
    allZones = {},
    distances = {},
    loadingZones = {},
    targetZone = {},
    closestZones = {},
    allProducts = {},
    CARGO = {
        interruption = true
    },
    MONITOR = {
        queryStatus = {},
        hasAlreadyNotify = {},
        area = 'country'
    },
    LOADED = {},
    PLAYER = {},
    PLAYERS = {},
    MISSION = {},
    DIAGNOSTICS = {}
}

local selectCharacters

_PlayerPedId = nil

local playerLoaded
local hasAlreadyEnteredMarker, currentActionData = false, {}
local currentAction, currentActionMsg, lastZone

Citizen.CreateThread(function()

    while ESX == nil do TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) Citizen.Wait(10) end

    while not ESX.PlayerLoaded do Citizen.Wait(1000) end

    ESX.TriggerServerCallback('eco_cargo:getPlayers', function(players)

        ECO.PLAYERS = players
        ECO.LOADED.players = true
    end)

    while not ECO.LOADED.players do Citizen.Wait(10) end

    if Config.kashacters then

        local serverId = GetPlayerServerId(PlayerId())

        if not ECO.PLAYERS[serverId] then

            while not selectCharacters do Citizen.Wait(2000) end
        end
    end

    -- LOADING PLAYER DATA
    ESX.TriggerServerCallback('eco_cargo:getPlayer', function(player)

        ECO.PLAYER = player
        ECO.PLAYER.cargoRequestTime = 0
        ECO.LOADED.player = true
    end)

    while not ECO.LOADED.player do Citizen.Wait(10) end


    -- LOADING MISSION DATA
    ESX.TriggerServerCallback('eco_cargo:getMission', function(mission)

        ECO.MISSION = mission
        ECO.LOADED.mission = true
    end)

    while not ECO.LOADED.mission do Citizen.Wait(10) end


    -- LOADING DATABASE: ZONE DATA
    ESX.TriggerServerCallback('eco_cargo:getZones', function(zones)

        if zones and next(zones) ~= nil then

            for _, v in pairs(zones) do

                ECO.allZones[v.id] = v
                ECO.allZones[v.id].actionpoint = coordsPharser(v.actionpoint)
                ECO.allZones[v.id].spawnpoint = coordsPharser(v.spawnpoint)
            end
        end

        zones = nil
        ECO.LOADED.allZones = true
    end)

    while not ECO.LOADED.allZones do Citizen.Wait(10) end


    -- LOADING DATABASE: DISTANCE DATA
    ESX.TriggerServerCallback('eco_cargo:getDistances', function(distances)

        if distances and next(distances) ~= nil then

            for _, v in pairs(distances) do

                ECO.distances[v.id] = ESX.Math.Round(v.route * 0.001, 1)
            end
        end

        distances = nil
        ECO.LOADED.distances = true
    end)

    while not ECO.LOADED.distances do Citizen.Wait(10) end


    -- LOADING DATABASE: PRODUCT DATA
    ESX.TriggerServerCallback('eco_cargo:getProducts', function(products, loadingZonesIds)

        if products and next(products) ~= nil then

            ECO.allProducts = products

            for k, _ in pairs(loadingZonesIds) do

                ECO.loadingZones[#ECO.loadingZones + 1] = ECO.allZones[k]
            end
        end

        products = nil
        ECO.LOADED.loadingZones = true
        ECO.LOADED.allProducts = true
    end)


    _PlayerPedId = PlayerPedId()
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)

    ECO.PLAYER.job = job
end)


RegisterNetEvent('playerSpawned')
AddEventHandler('playerSpawned', function()

    ESX.PlayerLoaded = true
end)


RegisterNetEvent('esx:kashloaded')
AddEventHandler('esx:kashloaded', function()

    selectCharacters = true
end)


-- CHECKPOINT HANDLE - Enter / Exit marker events
Citizen.CreateThread(function()

    while not ECO.LOADED.allZones do Citizen.Wait(1000) end

    local closestZones, coords, distance, currentZone, isInMarker, zones

    while true do

        Citizen.Wait(1000)

        -- ZONALISTA VÁLTÁS
        zones = ECO.zones

        if ECO.PLAYER.isApprovedDriver then

            coords = GetEntityCoords(_PlayerPedId)
            isInMarker = false
            currentZone = nil
            closestZones = {}

            for k, v in pairs(zones) do

                distance = #(coords - v['actionpoint'][1][1])

                if distance < 150 then table.insert(closestZones, k) end
                if distance < 6 then isInMarker = true currentZone = k end
            end

            ECO.closestZones = closestZones

            if (isInMarker and not hasAlreadyEnteredMarker) or (isInMarker and lastZone ~= currentZone) then
                hasAlreadyEnteredMarker = true
                lastZone = currentZone

                TriggerEvent('eco_cargo:hasEnteredMarker', currentZone)
            end

            if not isInMarker and hasAlreadyEnteredMarker then
                hasAlreadyEnteredMarker = false
                TriggerEvent('eco_cargo:hasExitedMarker', lastZone)
            end
        end
    end
end)

AddEventHandler('eco_cargo:hasEnteredMarker', function(itemIndex)

    currentActionData = ECO.zones[itemIndex]

    if not ECO.CARGO.interruption then

        currentAction = 'delivery_of_goods'
        currentActionData.message = _('delivery_of_goods')
    else

        currentAction = 'open_freight_list'
        currentActionData.message = _('open_freight_list')
    end

    sendHudActionData(currentActionData, 'append')
end)

AddEventHandler('eco_cargo:hasExitedMarker', function(itemIndex)

    currentAction = nil
    sendHudActionData({}, 'close')
end)

-- Display Action points markers
Citizen.CreateThread(function()

    while not ECO.LOADED.allZones do Citizen.Wait(1000) end

    local index, item, zones, p2pDistance

    while true do

        Citizen.Wait(0)

        index = ECO.closestZones
        zones = ECO.zones

        if index[1] and ECO.PLAYER.isApprovedDriver then

            -- Key controls
            if currentAction then

                if IsControlJustReleased(0, 38) then

                    -- MESSAGE CLOSE
                    SendNUIMessage({
                        subject = "CLOSE_PAGE"
                    })

                    if currentAction == 'delivery_of_goods' then

                        ECO.CARGO.showPayData = true
                        local report = createCargoReport(ECO.CARGO)

                        -- PAYMENT
                        local amount = tonumber(report.payData.payable)
                        local societyAmount = tonumber(report.payData.defenderSocietyPayable)
                        local moneyType = ECO.CARGO.stolen and Config.stolenCargoPaymentType or 'money'

                        if type(amount) == 'number' and amount > 0 then

                            TriggerServerEvent('eco_cargo:addMoney', amount, moneyType)
                        end

                        if type(societyAmount) == 'number' and societyAmount > 0 then

                            TriggerServerEvent('eco_cargo:societyAddMoney', societyAmount, report.product.defender)
                        end

                        -- REPORT
                        openNUI(report, "CARGO_REPORT")

                        DetachVehicleFromTrailer(ECO.Vehicle)
                        Citizen.Wait(300)

                        ESX.Game.DeleteVehicle(ECO.CARGO.trailer)
                        finishCargo('DELIVERED')

                    elseif currentAction == 'open_freight_list' then

                        ESX.TriggerServerCallback('eco_cargo:getServerTime', function(serverTimeStamp)

                            local loadingPositionId = currentActionData['id']
                            local zoneProductsIds = getZoneProductsIds(loadingPositionId)
                            local products = {}
                            local destinationZones, destinationIds, distance, km, cId, propertyNames

                            if next(zoneProductsIds) then

                                for productId, v in pairs(zoneProductsIds) do

                                    local product = deepCopy(ECO.allProducts[productId])
                                    local lastStartTime = product.loading[loadingPositionId]

                                    product.remainingTime = remainingTime(lastStartTime, product.reproduction_time, serverTimeStamp)
                                    product.remainingTimeDisplay = ''

                                    if product.remainingTime ~= 0 then

                                        local timeValue, timeUnit = displayTime(product.remainingTime)
                                        product.remainingTimeDisplay = string.format("%s %s", timeValue, _(timeUnit))
                                    end


                                    product.label = _(product.name)
                                    product.defenderLabel = product.defender == '' and '' or _(product.defender)


                                    destinationIds = json.decode(product.destination)
                                    propertyNames = json.decode(product.properties)
                                    product.params = calculateParams(propertyNames)

                                    product.destinationZones = {}

                                    for j = 1, #destinationIds do

                                        cId = tonumber(concatId(loadingPositionId, destinationIds[j], '', true))
                                        distance = getValue(ECO.distances, cId, 0)

                                        product.destinationZones[j] = deepCopy(ECO.allZones[destinationIds[j]])
                                        product.destinationZones[j].distance = distance
                                        product.destinationZones[j].priceData = calculatePrice(propertyNames, distance, product)
                                    end

                                    table.insert(products, product)
                                end
                            end

                            openNUI(products, "CARGO_SELECT")
                        end)
                    end

                    currentAction = nil
                end
            end

            -- DrawMarker
            for i = 1, #index do

                item = zones[index[i]]

                if item then

                    DrawMarker(23, item['actionpoint'][1][1], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 6.0, 6.0, 0.5, 255, 0, 0, 255, false, false, 2, false, false, false, false)
                end
            end
        else

            Citizen.Wait(1000)
        end
    end
end)

RegisterNetEvent('eco_cargo:changeMonitorOwner')
AddEventHandler('eco_cargo:changeMonitorOwner', function(trailerPlate, newOwner)

    -- changeMonitorOwner
    if ECO.CARGO.trailerPlate == trailerPlate then

        ECO.CARGO.trailer = false
        ECO.CARGO.monitorOwner = newOwner
    end
end)


function openNUI(data, subject)

    SetNuiFocus(true, true)

    SendNUIMessage({
        data = data,
        subject = subject,
        currentZone = currentActionData or {},
        player = ECO.PLAYER,
        mission = ECO.MISSION,
        disableMissionStartForDefenders = Config.disableMissionStartForDefenders
    })
end


RegisterNUICallback('registerCargo', function(data, cb)

    SetNuiFocus(false, false)

    local startPermission = true
    local permissionMsg = ''

    if data.defender ~= '' then

        if next(ECO.MISSION) ~= nil then

            for _, v in pairs(ECO.MISSION) do

                if v.trailerPlate then startPermission = false end
            end

            permissionMsg = _('a_mission_is_already_in_progress')
        end


        if Config.disableMissionStartForDefenders then

            if data.defender == ECO.PLAYER.job.name then

                startPermission = false
                permissionMsg = _('disable_mission_start_for_defenders')
            end
        end
    end


    if startPermission then

        ESX.TriggerServerCallback('eco_cargo:getRemainingTime', function(remainingTime)

            if remainingTime == 0 then

                local trailer = trailerSpawn(currentActionData['spawnpoint'], data.productId)

                if trailer then

                    ECO.PLAYER.cargoRequestTime = GetGameTimer()

                    ECO.CARGO = {
                        -- TRAILER
                        trailer = trailer,
                        trailerHealth = 1000,
                        trailerModel = data.trailerModel,
                        trailerPlate = safePlate(GetVehicleNumberPlateText(trailer)),
                        stolen = false,

                        -- PRODUCT
                        productId = data.productId,

                        -- MONITOR
                        monitorOwner = ECO.PLAYER.serverId,
                        quality = 100,
                        params = json.decode(data.params),

                        -- MONEY
                        freightFee = data.freightFee,
                        illegalPrice = data.illegalPrice,
                        goodsValue = data.goodsValue,
                        cautionMoney = data.cautionMoney,

                        -- ZONE
                        km = data.km,
                        destinationZoneId = data.destinationId,
                        loadingZoneId = data.loadingZoneId,

                        -- OWNER
                        owner = ECO.PLAYER
                    }

                    TriggerServerEvent('eco_cargo:cargoRegister', ECO.CARGO)
                end
            else

                local timeValue, timeUnit = displayTime(remainingTime)
                DoCustomHudText('fail', _('cargo_not_available', timeValue, _(timeUnit)))
            end
        end, data)
    else

        DoCustomHudText('fail', permissionMsg)
    end

    cb('ok')
end)


RegisterNUICallback('exit', function(data, cb)

    SetNuiFocus(false, false)
    cb('ok')
end)


RegisterCommand('inspect', function()

    local coords = GetEntityCoords(PlayerPedId())
    local vehicle, distance = ESX.Game.GetClosestVehicle(coords)

    if not IsPedOnFoot(PlayerPedId()) then

        DoCustomHudText('information', _('that_way_you_cant_scan_anything'))
        return false
    end

    if vehicle == 0 or distance > 10 then

        DoCustomHudText('information', _('there_are_no_vehicles_nearby'))
        return false
    end

    if GetVehicleClass(vehicle) ~= 11 then

        DoCustomHudText('information', _('you_can_only_scan_a_trailer'))
        return false
    end

    ESX.TriggerServerCallback('eco_cargo:getDataByPlate', function(data)

        if data then

            openNUI(createCargoReport(data), "CARGO_REPORT")
        else

            DoCustomHudText('fail', _('no_information'))
        end
    end, GetVehicleNumberPlateText(vehicle))
end)


RegisterCommand('closenui', function()

    SetNuiFocus(false, false)

    SendNUIMessage({
        subject = 'CLOSE_PAGE'
    })
end)

