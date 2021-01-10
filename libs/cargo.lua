function trailerSpawn(zones, productId)

    local spawnPoint, distance, vehicleCoords, isFree

    if productId == nil or productId == '' or not zones or next(zones) == nil then return end

    local allVehicles = ESX.Game.GetVehicles()

    for i = 1, #zones do

        if isFree then break end

        spawnPoint = zones[i]
        isFree = true

        for j = 1, #allVehicles do

            distance = #(GetEntityCoords(allVehicles[j]) - spawnPoint[1])

            if distance < 6 then

                isFree = false
                break
            end
        end
    end


    if isFree then

        local product = ECO.allProducts[tonumber(productId)]
        local model = product.trailer
        local trailerProperties = json.decode(product.trailer_properties)
        local spawn, trailer

        ESX.Game.SpawnVehicle(model, spawnPoint[1] - vector3(0, 0, 2.5), spawnPoint[2], function(spawnedTrailer)

            trailer = spawnedTrailer

            if trailerProperties then

                ESX.Game.SetVehicleProperties(spawnedTrailer, trailerProperties)
            end

            SetVehicleBodyHealth(spawnedTrailer, 1000.0)
            DoCustomHudText('information', _('you_can_attach_your_trailer'))
            spawn = true
        end)

        while spawn == nil do Citizen.Wait(10) end
        return trailer
    else

        DoCustomHudText('fail', _('every_place_occupied'))
        return false
    end
end

function setRoute(coord)

    --SetWaypointOff()
    ClearAllBlipRoutes()

    if next(ECO.blips) ~= nil then removeBlips() end

    local blip = AddBlipForCoord(coord)

    SetBlipSprite(blip, 477)
    SetBlipRoute(blip, true)


    if ECO.CARGO.stolen then

        SetBlipRouteColour(blip, 1)
    end

    ECO.blips = { [1] = blip }
end

function setZones()

    local presetName


    -- ZONELIST PRESET SELECT
    if ECO.PLAYER.isApprovedDriver then

        if ECO.MONITOR.towing then

            if ECO.targetZone[1] then presetName = 'target' else presetName = 'empty' end

        else

            if (ECO.PLAYER.cargoRequestTime + Config.cargoRequestDelay * 60000) > ECO.MONITOR.gameTimer and ECO.PLAYER.cargoRequestTime ~= 0 then

                presetName = 'empty'
            else
                presetName = 'loading'
            end
        end
    else

        presetName = 'empty'
    end


    -- ZONE SETTINGS
    if ECO.LOADED.zones == presetName then return end

    ECO.closestZones = {}
    ClearAllBlipRoutes()

    if presetName == 'loading' then

        ECO.zones = ECO.loadingZones
        setBlips(ECO.loadingZones)

    elseif presetName == 'target' then

        ECO.zones = ECO.targetZone
        setRoute(ECO.targetZone[1]['actionpoint'][1][1])
    else

        ECO.zones = {}
        removeBlips()
    end

    ECO.LOADED.zones = presetName
end

function setBlips(zoneList)

    if type(zoneList) ~= 'table' or next(zoneList) == nil then return end

    if next(ECO.blips) ~= nil then removeBlips() end

    ECO.blips = {}

    for k, v in pairs(zoneList) do

        ECO.blips[k] = AddBlipForCoord(v['actionpoint'][1][1])

        SetBlipSprite(ECO.blips[k], 477) -- 477 Turck sprite
        SetBlipScale(ECO.blips[k], 0.8)
        SetBlipColour(ECO.blips[k], 2)
        SetBlipAsShortRange(ECO.blips[k], true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(_("zone_blip_name"))
        EndTextCommandSetBlipName(ECO.blips[k])
    end
end

function removeBlips()

    if next(ECO.blips) == nil then return end

    for _, v in pairs(ECO.blips) do

        RemoveBlip(v)
    end

    ECO.blips = {}
end

function cargoPreset(productId)

    if not productId then return nil, nil end

    productId = tonumber(productId)
    local product = ECO.allProducts[productId]
    local propertyParams = {}
    local safetyReg

    if product.properties ~= '' then

        local props = json.decode(product.properties)

        for i = 1, #props do

            safetyReg = Config.propertyParams[props[i]]

            if safetyReg and next(safetyReg) then

                for preset, value in pairs(safetyReg) do

                    propertyParams[preset] = value
                end
            end
        end

        if not props or next(props) == nil then props = nil end
        if next(propertyParams) == nil then propertyParams = nil end

        return props, propertyParams
    else
        return nil, nil
    end
end

function createCargoReport(data)

    if type(data) ~= 'table' or next(data) == nil then return false end

    if not data.maxSpeed then

        data.maxSpeed = { country = 0, city = 0 }
    end

    data.product = deepCopy(ECO.allProducts[tonumber(data.productId)])
    data.payData = payData(data)
    data.loadingZone = ECO.allZones[tonumber(data.loadingZoneId)]
    data.targetZone = ECO.allZones[tonumber(data.destinationZoneId)]
    data.maxSpeed['country'] = data.maxSpeed['country'] or 0
    data.maxSpeed['city'] = data.maxSpeed['city'] or 0
    data.product.name = _(data.product.name)
    data.product.defenderLabel = _(data.product.defender)
    data.product.propnames = ""

    if data.product.properties ~= "" then

        local properties = json.decode(data.product.properties)

        if type(properties) == 'table' and next(properties) ~= nil then

            for i = 1, #properties do

                properties[i] = _(properties[i]) or properties[i]
            end

            data.product.propnames = table.concat(properties, ", ")
        end
    end

    return data
end

function finishCargo(state)

    UnsetCruiseControl()

    -- DELETE SERVER RECORD
    TriggerServerEvent('eco_cargo:deleteCargo', ECO.CARGO.trailerPlate, state)

    -- DISABLE REINIT CARGO
    ECO.MONITOR.queryStatus[ECO.CARGO.trailer] = 0

    -- RESET EXPLOSION TILT
    ECO.MONITOR.ImpactFlash = nil

    -- DELETE ROUTE AND BLIP
    ECO.Targetzone = {}

    -- RESET CARGO DATA, INTERRUPTION ON
    ECO.CARGO.trailer = nil
    ECO.CARGO.trailerPlate = nil
    ECO.CARGO.interruption = true
end

function deliveryInterruption()

    if not ECO.CARGO.interruption then

        if not ECO.PLAYER.isApprovedDriver or not ECO.MONITOR.towing then

            -- INTERRUPTION ON
            ECO.CARGO.interruption = true
        end
    end
end

function initCargo()

    if not ECO.CARGO.interruption or not ECO.MONITOR.towing then return end

    local plate = safePlate(ECO.MONITOR.trailerPlate)
    local trailer = ECO.MONITOR.attachedTrailer

    -- DBQUERY
    if (ECO.CARGO.trailerPlate ~= plate or ECO.CARGO.monitorOwner ~= ECO.PLAYER.serverId) and ECO.MONITOR.queryStatus[trailer] ~= 0 then

        local load

        ESX.TriggerServerCallback('eco_cargo:cargoLoader', function(ecoCargo)

            ECO.MONITOR.queryStatus[trailer] = 0

            if ecoCargo then

                ECO.MONITOR.queryStatus[trailer] = 1
                ECO.CARGO = ecoCargo
            end

            load = true
        end, plate)

        while not load do Citizen.Wait(10) end
    end


    -- CARGO SETTING
    if ECO.CARGO.trailerPlate == plate then

        ECO.CARGO.trailer = trailer


        if ECO.CARGO.owner.identifier == ECO.PLAYER.identifier then

            ECO.CARGO.stolen = false
            ECO.targetZone = { ECO.allZones[tonumber(ECO.CARGO.destinationZoneId)] }
        else

            ECO.CARGO.stolen = true
            ECO.loadingZone = ECO.allZones[tonumber(ECO.CARGO.loadingZoneId)]
            ECO.targetZone = getIllegalTargetZone()
        end

        -- INTERRUPTION OFF
        ECO.CARGO.interruption = false

        -- SET MONITOR OWNER
        if ECO.CARGO.monitorOwner ~= ECO.PLAYER.serverId then

            TriggerServerEvent('eco_cargo:changeMonitorOwner', ECO.CARGO.monitorOwner, ECO.CARGO.trailerPlate)
            ECO.CARGO.monitorOwner = ECO.PLAYER.serverId
        end

        ECO.MONITOR.hudSpeedLimit = 0

    else

        ECO.targetZone = {}
    end
end

function getIllegalTargetZone()

    local loadingZone = ECO.loadingZone.actionpoint[1][1]
    local distance = 0
    local targetZone = {}

    for k, v in pairs(Config.illegalTargetZones) do

        if #(v.actionpoint - loadingZone) > distance then

            for key, value in pairs(v) do

                if key == 'actionpoint' then

                    targetZone.actionpoint = { { value, 0.0 } }
                else
                    targetZone[key] = value
                end
            end
        end
    end

    return { targetZone }
end

function trailerOrGoodsDestroyed()

    if ECO.CARGO.trailerHealth == 0 then

        -- END CARGO (FAIL)
        finishCargo('DESTROYED')
        DoCustomHudText('fail', _('delivery_failed'), 10000)
    end
end

function isApprovedDriver()

    if ECO.Vehicle ~= 0 and Config.approvedVehicles[GetEntityModel(ECO.Vehicle)] then

        ECO.PLAYER.isApprovedDriver = GetPedInVehicleSeat(ECO.Vehicle, -1) == _PlayerPedId
    else

        ECO.PLAYER.isApprovedDriver = false
    end
end

function getTrailer()

    if ECO.PLAYER.isApprovedDriver then

        -- ATTACHED TRAILER
        ECO.MONITOR.towing, ECO.MONITOR.attachedTrailer = GetVehicleTrailerVehicle(ECO.Vehicle)

        -- ATTACHED TRAILER PLATE
        if ECO.MONITOR.attachedTrailer > 0 then

            ECO.MONITOR.trailerPlate = GetVehicleNumberPlateText(ECO.MONITOR.attachedTrailer)
        end
    else

        ECO.MONITOR.towing = false
        ECO.MONITOR.attachedTrailer = 0
        ECO.MONITOR.trailerPlate = nil
    end
end

function getLiveData()

    if not ECO.CARGO.trailer or ECO.CARGO.trailer == 0 then return end

    ECO.MONITOR.area = ECO.MONITOR.area or 'country'


    local newRegistration, maxSpeed = {}, {}
    local speed = transformToKm(GetEntitySpeed(ECO.CARGO.trailer))
    local coords = GetEntityCoords(ECO.CARGO.trailer)
    local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneData = Config.zoneData[zoneHash] or { "country", "Unknown" }
    local bodyHealth = GetVehicleBodyHealth(ECO.CARGO.trailer)


    ECO.MONITOR.area = zoneData[1]

    -- SET HUD SPEEDLIMIT
    SetHudSpeedLimit(Config.speedLimit[zoneData[1]])


    -- BODY DAMAGE REGISTER
    if ECO.CARGO.trailerHealth and ECO.CARGO.trailerHealth > bodyHealth then

        newRegistration['bodyHealth'] = true

        -- NOTIFY
        sendHudLiveData('trailerHealth', math.round(bodyHealth * 0.1))
    end

    -- DESTROYED TRAILER INTERRUPTION
    trailerOrGoodsDestroyed()

    -- GOODSQUALITY REFRESH ( ROLL, WHEEL, DAMAGE EVENT )
    if ECO.CARGO.quality ~= ECO.MONITOR.quality then

        if not ECO.MONITOR.goodsQualityTilt then

            sendHudLiveData('goodsQuality', math.round(ECO.CARGO.quality))
        end

        if ECO.CARGO.quality < 0 then

            ECO.CARGO.quality = 0
            ECO.MONITOR.goodsQualityTilt = true
        else

            ECO.MONITOR.goodsQualityTilt = false
        end

        ECO.MONITOR.quality = ECO.CARGO.quality
    end

    --[[
    -- COORDS REGISTER
    if ECO.CARGO.coords'] and #(ECO.CARGO.coords'] - coords) > 15 then

        newRegistration['coords'] = true
    end
    ]]

    -- TACHOGRAF: MAXSPEED REGISTER
    if ECO.CARGO.maxSpeed then

        if not ECO.CARGO.maxSpeed[ECO.MONITOR.area] then

            maxSpeed[ECO.MONITOR.area] = speed
            newRegistration['speed'] = speed > Config.speedLimit[ECO.MONITOR.area]
        end

        for k, v in pairs(ECO.CARGO.maxSpeed) do

            maxSpeed[k] = v

            if ECO.MONITOR.area == k then

                if speed > v then

                    newRegistration['speed'] = speed > Config.speedLimit[ECO.MONITOR.area]
                    maxSpeed[k] = speed
                end
            end
        end

    else

        maxSpeed[ECO.MONITOR.area] = speed
        newRegistration['speed'] = speed > Config.speedLimit[ECO.MONITOR.area]
    end

    for _, v in pairs(newRegistration) do

        if v == true then

            ECO.MONITOR.ServerSaveRequest = true
            break
        end
    end


    ECO.CARGO.coords = coords
    ECO.CARGO.maxSpeed = maxSpeed
    ECO.CARGO.trailerHealth = bodyHealth
    ECO.CARGO.attachedTo = GetEntityAttachedTo(ECO.CARGO.trailer)
end