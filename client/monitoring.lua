--
-- Created by IntelliJ IDEA.
-- User: ekhion
-- Date: 2020. 11. 11.
-- Time: 12:59
--

-- ROUTER
Citizen.CreateThread(function()

    while not ECO.LOADED.player do Citizen.Wait(1000) end

    while true do

        _PlayerPedId = PlayerPedId()

        Citizen.Wait(2000)

        ----------------- DATA COLLECTION -----------------

        ECO.MONITOR.gameTimer = GetGameTimer()
        ECO.PLAYER.coords = GetEntityCoords(_PlayerPedId)


        -- CHECK VEHICLE
        ECO.Vehicle = GetVehiclePedIsIn(_PlayerPedId, false)


        -- TRUCK AND DRIVER INSPECTION
        isApprovedDriver()


        -- TRAILER INSPECTION
        getTrailer()


        -- TRAILER SLOW MONITORING
        getLiveData()

        ------------------ CARGO SETTINGS -----------------

        -- DELIVERY INTERRUPTION
        deliveryInterruption()


        -- TRAILER TOWING
        initCargo()


        -- INIT ZONES
        setZones()


        -- SHOW ACTIONS, NOTIFICATION, DELIVERY INFORMATION
        setHud()
    end
end)

-- FAST LIVEDATA
Citizen.CreateThread(function()

    while not ECO.CARGO or not ECO.CARGO.trailer do Citizen.Wait(1000) end

    local speed = 0
    local _GetFrameTime, prevSpeed, roll
    local abs = math.abs

    while true do

        Citizen.Wait(0)

        if ECO.CARGO.trailer then

            prevSpeed = speed
            speed = GetEntitySpeed(ECO.CARGO.trailer) * 3.6
            roll = abs(GetEntityRoll(ECO.CARGO.trailer))

            _GetFrameTime = GetFrameTime()


            -- HitByEntity
            collisionMonitor(speed, prevSpeed)


            -- OVERTURNING MONITOR
            overturningMonitor(roll)


            -- ROLL AND WHEELS MONITOR
            rollMonitor(speed, roll, _GetFrameTime)


            -- SPEEDLIMIT ALERT
            speedLimitMonitor(speed)
        else

            Citizen.Wait(2000)
        end
    end
end)

-- SEND DATA TO SERVER
Citizen.CreateThread(function()

    while true do

        Citizen.Wait(20000)

        if ECO.MONITOR.ServerSaveRequest and ECO.CARGO.trailer then

            TriggerServerEvent('eco_cargo:cargoUpdate', ECO.CARGO)
            ECO.MONITOR.ServerSaveRequest = false
        end
    end
end)

-- TRAILER MARKER IF NOT ATTACHED
Citizen.CreateThread(function()

    while true do

        Citizen.Wait(0)

        if ECO.PLAYER.isApprovedDriver and
                ECO.CARGO.trailer and
                ECO.CARGO.attachedTo == 0 and
                #(ECO.PLAYER.coords - ECO.CARGO.coords) < 100 then

            DrawMarker(22,
                ECO.CARGO.coords.x,
                ECO.CARGO.coords.y,
                ECO.CARGO.coords.z + 5,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                2.0, 2.0, -6.0,
                255, 255, 0, 255,
                true, -- bobUpAndDown
                true, 2, false, false, false, false)
        else

            Citizen.Wait(2000)
        end
    end
end)

-- SEND TRAILER SIGNAL
Citizen.CreateThread(function()

    while true do

        Citizen.Wait(Config.missionTrailerSignalInterval * 1000)

        if ECO.MONITOR.towing then

            for _, v in pairs(ECO.MISSION) do

                if ECO.MONITOR.trailerPlate == v.trailerPlate then

                    TriggerServerEvent('eco_cargo:trailerSignal', ECO.CARGO.coords, true)
                end
            end
        end
    end
end)


-- PLAYER MONITORING
RegisterNetEvent('eco_cargo:updatePlayers')
AddEventHandler('eco_cargo:updatePlayers', function(players)

    ECO.PLAYERS = players
end)

-- MISSION MONITORING
RegisterNetEvent('eco_cargo:missionUpdate')
AddEventHandler('eco_cargo:missionUpdate', function(mission)

    ECO.MISSION = mission
end)


-- PRODUCT COOLDOWN MONITORING
RegisterNetEvent('eco_cargo:productUpdate')
AddEventHandler('eco_cargo:productUpdate', function(data)

    if ECO.allProducts[data.productId] then

        ECO.allProducts[data.productId].loading[data.loadingZoneId] = data.time
    end
end)
