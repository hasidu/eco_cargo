--
-- Created by IntelliJ IDEA.
-- User: ekhion
-- Date: 2020. 12. 10.
-- Time: 1:22
--

local refV1

RegisterNUICallback('distanceCalc', function(data, cb)

    SetNuiFocus(false, false)

    local loading, destination
    local id1, id2, idC
    local v1, v2
    local k = 0
    local uniqueIdC, distances = {}, {}


    Citizen.CreateThread(function()

        -- ÚTVONALAK KIGYŰJTÉSE
        local loadAllProducts
        ESX.TriggerServerCallback('eco_cargo:getAllProducts', function(product)

            if (product[1] ~= nil) then

                for j = 1, #product do

                    loading = json.decode(product[j].loading)
                    destination = json.decode(product[j].destination)


                    if loading and loading[1] and destination and destination[1] then

                        for i = 1, #loading do

                            id1 = loading[i]


                            for z = 1, #destination do

                                id2 = destination[z]

                                k = k + 1

                                idC = concatId(id1, id2, '|', true)
                                uniqueIdC[idC] = 1
                            end
                        end
                    else

                        print(product[j].id, 'üres étréket adott vissza!')
                    end
                end
            end
            loadAllProducts = true
        end)

        while not loadAllProducts do Citizen.Wait(100) end


        -- TÁVOLSÁGADATOK LEKÉRÉSE
        local loadDistances
        ESX.TriggerServerCallback('eco_cargo:getDistances', function(result)

            if (result[1] ~= nil) then

                for i = 1, #result do

                    distances[result[i].id] = result[i]
                end
            end

            loadDistances = true
        end)

        while not loadDistances do Citizen.Wait(100) end


        -- TÁVOLSÁGOK SZÁMÍTÁSA
        local uniqueIdCKeys = {}

        if next(uniqueIdC) ~= nil then

            local air, waypoint, calculate, try, blip, km, distance, route, cId
            local injectData = {}

            DeleteWaypoint()

            -- PAUSE MENU OPEN
            if not IsPauseMenuActive() then
                ActivateFrontendMenu('FE_MENU_VERSION_MP_PAUSE', 0, -1)
                while not IsPauseMenuActive() do Citizen.Wait(100) end
            end


            uniqueIdC = array_keys(uniqueIdC)
            table.sort(uniqueIdC)


            -- DISTANCE CALC
            for i = 1, #uniqueIdC do

                id1, id2 = table.unpack(explode(uniqueIdC[i], "|"))

                v1 = ECO.allZones[tonumber(id1)].actionpoint[1][1]
                v2 = ECO.allZones[tonumber(id2)].actionpoint[1][1]

                air = math.round(#(v1 - v2))
                cId = tonumber(concatId(id1, id2, '', true))
                distance = distances[cId]

                table.insert(uniqueIdCKeys, cId)

                if not distance or distance.air ~= air or distance.route == '' then

                    if v1 ~= refV1 then

                        SetEntityCoords(PlayerPedId(), v1)

                        refV1 = v1
                        Citizen.Wait(2000)
                    end

                    route = calcRoute(v1, v2)

                    if route ~= 0 then

                        injectData[cId] = {
                            route = route,
                            air = air
                        }
                    end
                end
            end

            if next(injectData) ~= nil then

                TriggerServerEvent('eco_cargo:updateDistance', injectData)
            end

            -- PAUSE MENU CLOSE
            Citizen.Wait(1000)
            if IsPauseMenuActive() then
                ActivateFrontendMenu('FE_MENU_VERSION_MP_PAUSE', 0, -1)
            end



            -- ORPHAN DISTANCE DELETE
            for i=1, #uniqueIdCKeys do

                if distances[uniqueIdCKeys[i]] then distances[uniqueIdCKeys[i]] = nil end
            end


            if next(distances) ~= nil then

                local orphanDistanceRecord = {}

                for k, _ in pairs(distances) do

                    table.insert(orphanDistanceRecord, k)
                end

                TriggerServerEvent('eco_cargo:deleteDistance', orphanDistanceRecord)
            end
        end
    end)

    cb('ok')
end)

RegisterNetEvent('eco_cargo:cargoDiagnostics')
AddEventHandler('eco_cargo:cargoDiagnostics', function()

    local loading, destination
    local id1, id2, idC
    local v1, v2
    local k = 0
    local uniqueIdC, distances, usedZones = {}, {}, {}


    ECO.DIAGNOSTICS.countProducts = 0
    ECO.DIAGNOSTICS.orphanProduct = {}

    ECO.DIAGNOSTICS.countRoutes = 0
    ECO.DIAGNOSTICS.countUniqueRoutes = 0

    ECO.DIAGNOSTICS.wrongDistanceRecord = 0
    ECO.DIAGNOSTICS.orphanDistanceRecord = {}
    ECO.DIAGNOSTICS.missingDistanceRecord = 0

    ECO.DIAGNOSTICS.missingActionPoints = {}
    ECO.DIAGNOSTICS.orphanActionPoints = {}

    ECO.DIAGNOSTICS.localeDiagnostics = {}


    Citizen.CreateThread(function()


        -- LOADING DATABASE: ZONE DATA
        local loadAllZones

        ESX.TriggerServerCallback('eco_cargo:getZones', function(zones)

            if zones[1] ~= nil then

                ECO.allZones = {}

                for _, v in pairs(zones) do

                    ECO.allZones[v.id] = v
                    ECO.allZones[v.id].actionpoint = coordsPharser(v.actionpoint)
                    ECO.allZones[v.id].spawnpoint = coordsPharser(v.spawnpoint)
                end
            end

            zones = nil
            loadAllZones = true
        end)

        while not loadAllZones do Citizen.Wait(10) end


        ECO.DIAGNOSTICS.countActionPoints = assocCount(ECO.allZones)


        -- TÁVOLSÁGADATOK LEKÉRÉSE
        local loadDistances

        ESX.TriggerServerCallback('eco_cargo:getDistances', function(result)

            if (result[1] ~= nil) then

                for i = 1, #result do distances[result[i].id] = result[i] end
            end

            loadDistances = true
        end)

        while not loadDistances do Citizen.Wait(100) end


        -- ÚTVONALAK KIGYŰJTÉSE
        local loadAllProducts
        ESX.TriggerServerCallback('eco_cargo:getAllProducts', function(product)

            if (product[1] ~= nil) then

                ECO.DIAGNOSTICS.countProducts = #product

                for j = 1, #product do

                    loading = json.decode(product[j].loading)
                    destination = json.decode(product[j].destination)

                    if loading and loading[1] and destination and destination[1] then

                        for i = 1, #loading do

                            id1 = loading[i]

                            usedZones[id1] = true

                            for z = 1, #destination do

                                id2 = destination[z]

                                usedZones[id2] = true

                                k = k + 1

                                idC = tonumber(concatId(id1, id2, '', true))

                                local zone1 = ECO.allZones[tonumber(id1)]
                                local zone2 = ECO.allZones[tonumber(id2)]

                                if zone1 and zone2 then

                                    v1 = zone1.actionpoint[1][1]
                                    v2 = zone2.actionpoint[1][1]

                                    uniqueIdC[idC] = math.round(#(v1 - v2))
                                else

                                    if not zone1 then

                                        ECO.DIAGNOSTICS.missingActionPoints[id1] = {
                                            zoneId = id1,
                                            productId = product[j].id,
                                            productName = product[j].name,
                                            productLabel = _(product[j].name)
                                        }
                                    end
                                    if not zone2 then

                                        ECO.DIAGNOSTICS.missingActionPoints[id2] = {
                                            zoneId = id2,
                                            productId = product[j].id,
                                            productName = product[j].name,
                                            productLabel = _(product[j].name)
                                        }
                                    end
                                end
                            end
                        end
                    else

                        table.insert(ECO.DIAGNOSTICS.orphanProduct, { id = product[j].id, name = product[j].name, transName =  _(product[j].name)})
                    end
                end

                if next(usedZones) then

                    for k, v in pairs(ECO.allZones) do

                        if not usedZones[k] then

                            table.insert(ECO.DIAGNOSTICS.orphanActionPoints, v)
                        end
                    end
                end

                ECO.DIAGNOSTICS.countRoutes = k
                ECO.DIAGNOSTICS.countUniqueRoutes = assocCount(uniqueIdC)

                -- LOCALE DIAGNOSTICS
                localeDiagnostics(product)
            end

            loadAllProducts = true
        end, true)

        while not loadAllProducts do Citizen.Wait(100) end


        for id, air in pairs(uniqueIdC) do

            if distances[id] then

                if distances[id].air ~= air then

                    ECO.DIAGNOSTICS.wrongDistanceRecord = ECO.DIAGNOSTICS.wrongDistanceRecord + 1
                end

                distances[id] = nil
            else

                ECO.DIAGNOSTICS.missingDistanceRecord = ECO.DIAGNOSTICS.missingDistanceRecord + 1
            end
        end

        if next(distances) ~= nil then

            for k, v in pairs(distances) do

                table.insert(ECO.DIAGNOSTICS.orphanDistanceRecord, k)
            end
        end

        openNUI(ECO.DIAGNOSTICS, 'MAINTENANCE')
    end)
end)

function localeDiagnostics(product)

    ECO.DIAGNOSTICS.missingLocales = {}

    for j = 1, #product do

        if string.match(_(product[j].name), "Translation") then

            table.insert(ECO.DIAGNOSTICS.missingLocales, product[j].name)
        end
    end
end