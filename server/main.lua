ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ECO = {
    CARGO = {},
    PLAYERS = {},
    MISSION = {},
    PRODUCTS = {},
    loadingZonesIds = {}
}

ESX.RegisterServerCallback('eco_cargo:getMission', function(source, cb)

    cb(ECO.MISSION)
end)

ESX.RegisterServerCallback('eco_cargo:getPlayers', function(source, cb)

    -- PLAYER MONITORING
    if next(ECO.PLAYERS) == nil then

        local xPlayer
        local getPlayers = ESX.GetPlayers()

        for i = 1, #getPlayers do

            xPlayer = ESX.GetPlayerFromId(getPlayers[i])

            if xPlayer ~= nil then

                ECO.PLAYERS[xPlayer.source] = xPlayer.job.name
            end
        end
    end

    cb(ECO.PLAYERS)
end)

ESX.RegisterServerCallback('eco_cargo:getPlayer', function(source, cb)

    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    local userData = {
        serverId = _source,
        characterName = 'John Doe',
        dateOfBirth = '-',
        group = 'player',
        permissionLevel = 0,
        job = {},
        identifier = '',
    }


    if xPlayer ~= nil then

        userData.job = xPlayer.job
        userData.identifier = xPlayer.identifier

        MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', { ['@identifier'] = xPlayer.identifier }, function(user)

            if user[1] then

                userData.characterName = user[1].firstname .. " " .. user[1].lastname
                userData.dateOfBirth = user[1].dateofbirth
                userData.group = user[1].group
                userData.permissionLevel = user[1].permission_level
            end

            cb(userData)
        end)
    else

        cb(userData)
    end
end)

ESX.RegisterServerCallback('eco_cargo:getZones', function(source, cb)

    MySQL.Async.fetchAll('SELECT * FROM eco_cargo_zones', {}, function(zones)

        cb(zones)
    end)
end)

ESX.RegisterServerCallback('eco_cargo:getProducts', function(source, cb)

    if next(ECO.PRODUCTS) == nil then

        local sql = 'SELECT * FROM `eco_cargo_products` WHERE `loading` NOT IN("[]", "") AND `destination` NOT IN("[]", "")'

        MySQL.Async.fetchAll(sql, {}, function(result)

            if result[1] then

                ECO.loadingZonesIds = {}

                local row, loading

                for i = 1, #result do

                    row = result[i]
                    loading = {}

                    row.loading = json.decode(row.loading)

                    if row.loading then

                        for j = 1, #row.loading do

                            loading[row.loading[j]] = 0
                            ECO.loadingZonesIds[row.loading[j]] = true
                        end
                    end

                    ECO.PRODUCTS[row.id] = row
                    ECO.PRODUCTS[row.id].loading = loading
                end
            end

            cb(ECO.PRODUCTS, ECO.loadingZonesIds)
        end)

    else

        cb(ECO.PRODUCTS, ECO.loadingZonesIds)
    end
end)

ESX.RegisterServerCallback('eco_cargo:getAllProducts', function(source, cb)

    MySQL.Async.fetchAll('SELECT * FROM `eco_cargo_products`', {}, function(result)

        cb(result)
    end)
end)

ESX.RegisterServerCallback('eco_cargo:getDistances', function(source, cb)

    MySQL.Async.fetchAll('SELECT * FROM `eco_cargo_distances`', {}, function(distances)

        cb(distances)
    end)
end)

ESX.RegisterServerCallback('eco_cargo:cargoLoader', function(source, cb, plate, existsCheck)

    -- local _source = source
    -- local identifier = GetPlayerIdentifier(_source, 0)

    if existsCheck then

        --[[if ECO.CARGO[plate] then

            ECO.CARGO[plate].requiredReSpawning = true

            local vehicle = getVehicleFromPlate(ECO.CARGO[plate].trailerPlate)

            if vehicle.coords then

                ECO.CARGO[plate].coords = vehicle.coords -- vector3 tostring??? CONVERT PROBLÉMA?
                ECO.CARGO[plate].requiredReSpawning = false
            end

            cb(ECO.CARGO[plate])
        else

            cb(nil)
        end]]
    else

        cb(ECO.CARGO[plate])
    end
end)

ESX.RegisterServerCallback('eco_cargo:getDataByPlate', function(source, cb, plate)

    plate = safePlate(plate)
    cb(ECO.CARGO[plate])
end)

ESX.RegisterServerCallback('eco_cargo:getAllStatistics', function(source, cb, data)

    if not data.orderBy or data.orderBy == '' then data.orderBy = 'all_started' end
    if not data.dir or data.dir == '' then data.dir = 'DESC' end

    -- STAT RECORD
    local sql = [[
        SELECT `eco_cargo_stats`.*,
        `eco_cargo_stats`.`started_mission` + `eco_cargo_stats`.`started_delivery` as `all_started`,
        `eco_cargo_stats`.`done_mission` + `eco_cargo_stats`.`done_delivery` as `all_done`,
        `eco_cargo_stats`.`stolen_mission` + `eco_cargo_stats`.`stolen_delivery` as `all_stolen`,
        `eco_cargo_stats`.`goods_quality` / (`eco_cargo_stats`.`started_mission` + `eco_cargo_stats`.`started_delivery`) as `quality_rate`,
        (`eco_cargo_stats`.`done_mission` + `eco_cargo_stats`.`done_delivery`) / (`eco_cargo_stats`.`started_mission` + `eco_cargo_stats`.`started_delivery`) * 100 as `success_rate`,
        `users`.`name`,
        `users`.`firstname`,
        `users`.`lastname`
        FROM `eco_cargo_stats`
        LEFT JOIN `users`
        USING (`identifier`)
        ORDER BY `]] .. data.orderBy .. [[` ]] .. data.dir .. [[
        LIMIT 50
    ]]

    MySQL.Async.fetchAll(sql, {}, function(result)

        cb(result)
    end)
end)

ESX.RegisterServerCallback('eco_cargo:getStatistics', function(source, cb)

    local _source = source
    local identifier = GetPlayerIdentifier(_source, 0)

    -- STAT RECORD
    local sql = [[
        SELECT `eco_cargo_stats`.*,
        `eco_cargo_stats`.`started_mission` + `eco_cargo_stats`.`started_delivery` as `all_started`,
        `eco_cargo_stats`.`done_mission` + `eco_cargo_stats`.`done_delivery` as `all_done`,
        `eco_cargo_stats`.`stolen_mission` + `eco_cargo_stats`.`stolen_delivery` as `all_stolen`,
        `eco_cargo_stats`.`goods_quality` / (`eco_cargo_stats`.`started_mission` + `eco_cargo_stats`.`started_delivery`) as `quality_rate`,
        (`eco_cargo_stats`.`done_mission` + `eco_cargo_stats`.`done_delivery`) / (`eco_cargo_stats`.`started_mission` + `eco_cargo_stats`.`started_delivery`) * 100 as `success_rate`,
        `users`.`name`,
        `users`.`firstname`,
        `users`.`lastname`
        FROM `eco_cargo_stats`
        LEFT JOIN `users`
        USING (`identifier`)
        WHERE `eco_cargo_stats`.`identifier` = @identifier
    ]]

    MySQL.Async.fetchAll(sql, {
        ['@identifier'] = identifier
    }, function(result)

        cb(result)
    end)
end)

ESX.RegisterServerCallback('eco_cargo:getServerTime', function(source, cb)

    cb(os.time())
end)

ESX.RegisterServerCallback('eco_cargo:getRemainingTime', function(source, cb, data)

    local product = ECO.PRODUCTS[data.productId]
    local lastStartTime = product.loading[data.loadingZoneId]

    cb(remainingTime(lastStartTime, product.reproduction_time, os.time()))
end)

-- PLAYER MONITORING
AddEventHandler('esx:setJob', function(playerId, job)

    ECO.PLAYERS[playerId] = job.name
    TriggerClientEvent('eco_cargo:updatePlayers', -1, ECO.PLAYERS)
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)

    ECO.PLAYERS[playerId] = xPlayer.job.name
    TriggerClientEvent('eco_cargo:updatePlayers', -1, ECO.PLAYERS)
end)

AddEventHandler('esx:playerDropped', function(playerId)

    ECO.PLAYERS[playerId] = nil
    TriggerClientEvent('eco_cargo:updatePlayers', -1, ECO.PLAYERS)
end)

RegisterNetEvent('eco_cargo:cargoRegister')
AddEventHandler('eco_cargo:cargoRegister', function(ecoCargo)

    local _source = source
    local plate = safePlate(ecoCargo.trailerPlate)
    local isMission, isVulnerable
    local osTime = os.time()

    if not ECO.CARGO[plate] then ECO.CARGO[plate] = {} end

    --LAST START TIME REGISTER
    ECO.PRODUCTS[ecoCargo.productId].loading[ecoCargo.loadingZoneId] = osTime

    ecoCargo.startDelivery = osTime

    table.refresh(ECO.CARGO[plate], ecoCargo)


    -- PAY CAUTION
    local cautionMoney = tonumber(ecoCargo.cautionMoney)


    if type(cautionMoney) == 'number' and cautionMoney > 0 then

        removeMoney(_source, cautionMoney)
    end


    -- ADD PLATE MISSION DATA
    local missionId = concatId(ecoCargo.loadingZoneId, ecoCargo.productId, '_')

    if ECO.MISSION[missionId] and ECO.MISSION[missionId].owner.identifier == ecoCargo.owner.identifier then

        isMission = true

        ECO.MISSION[missionId].trailerPlate = plate
        ECO.MISSION[missionId].destinationZoneId = ecoCargo.destinationZoneId

        TriggerClientEvent('eco_cargo:missionUpdate', -1, ECO.MISSION)

        -- BROADCAST
        TriggerClientEvent('eco_cargo:missionNotification', -1, { otherText = _('mission_start_alert') })
    end


    if ecoCargo.params.damageRoll < 10 or
            ecoCargo.params.collisionSensitivity < 100 then

        isVulnerable = true
    end


    -- STAT RECORD
    local sql = [[
    INSERT INTO `eco_cargo_stats`
    (
        `identifier`,
        `started_delivery`,
        `started_mission`,
        `vulnerable`,
        `last_activity`
    ) VALUES (

        @identifier,
        @started_delivery,
        @started_mission,
        @vulnerable,
        current_timestamp()
        )
        ON DUPLICATE KEY UPDATE
        `started_delivery` = `started_delivery` + @started_delivery,
        `started_mission` = `started_mission` + @started_mission,
        `vulnerable` = `vulnerable` + @vulnerable,
        `last_activity` = current_timestamp()
    ]]


    MySQL.Async.execute(sql,
        {
            ['@identifier'] = ecoCargo.owner.identifier,
            ['@started_delivery'] = isMission and 0 or 1,
            ['@started_mission'] = isMission and 1 or 0,
            ['@vulnerable'] = isVulnerable and 1 or 0,
        }, function(rowsChanged)

            print("STAT INSERT OK", rowsChanged)
        end)

    TriggerClientEvent('eco_cargo:productUpdate', -1, {
        productId = ecoCargo.productId,
        loadingZoneId = ecoCargo.loadingZoneId,
        time = osTime
    })
end)

RegisterNetEvent('eco_cargo:cargoUpdate')
AddEventHandler('eco_cargo:cargoUpdate', function(ecoCargo)

    local plate = safePlate(ecoCargo.trailerPlate)

    if not ECO.CARGO[plate] then ECO.CARGO[plate] = {} end

    table.refresh(ECO.CARGO[plate], ecoCargo)
end)

RegisterNetEvent('eco_cargo:deleteCargo')
AddEventHandler('eco_cargo:deleteCargo', function(plate, state)

    local _source = source
    local identifier = GetPlayerIdentifier(_source, 0)

    if ECO.CARGO[plate] then

        local isMission
        local increaseDoneDelivery, increaseDoneMission = 1, 1
        local quality = 0
        local defenders = {}
        local ecoCargo = ECO.CARGO[plate]
        local stolen = not (ecoCargo.owner.identifier == identifier)

        TriggerClientEvent('eco_cargo:trailerSignal', -1, {}, plate, false)

        -- DELETE MISSION DATA
        local missionId = concatId(ecoCargo.loadingZoneId, ecoCargo.productId, '_')

        if ECO.MISSION[missionId] and ECO.MISSION[missionId].trailerPlate == plate then

            isMission = true
            defenders = ECO.MISSION[missionId].joined
            TriggerEvent('eco_cargo:missionUpdate', { missionId = missionId }, 'delete')
        end


        local params = ecoCargo.params

        if params.extraStatDeliveryPoint and type(params.extraStatDeliveryPoint) == 'number' then

            increaseDoneDelivery = increaseDoneDelivery + params.extraStatDeliveryPoint
        end

        if params.extraStatQualityMultiplier and type(params.extraStatQualityMultiplier) == 'number' then

            quality = ecoCargo.quality * params.extraStatQualityMultiplier
        end

        if isMission then

            quality = ecoCargo.quality * 2
            increaseDoneMission = 2
        end

        local sql = [[
            INSERT INTO `eco_cargo_stats`
            (
                `identifier`,
                `distance`,
                `goods_quality`,
                `done_delivery`,
                `done_mission`,
                `stolen_delivery`,
                `stolen_mission`,
                `destroyed_trailer`,
                `working_time`,
                `last_activity`
            ) VALUES (
                @identifier,
                @distance,
                @goods_quality,
                @done_delivery,
                @done_mission,
                @stolen_delivery,
                @stolen_mission,
                @destroyed_trailer,
                @working_time,
                current_timestamp()
                )
                ON DUPLICATE KEY UPDATE
                `distance` = `distance` + @distance,
                `goods_quality` = IF(`goods_quality` + @goods_quality > (`done_delivery` + @done_delivery + `done_mission` + @done_mission) * 1000,
                (`done_delivery` + @done_delivery + `done_mission` + @done_mission) * 1000,
                `goods_quality` + @goods_quality),
                `done_delivery` = IF(`started_delivery` >= `done_delivery` + @done_delivery, `done_delivery` + @done_delivery, `started_delivery`),
                `done_mission` = IF(`started_mission` >= `done_mission` + @done_mission, `done_mission` + @done_mission, `started_mission`),
                `stolen_delivery` = `stolen_delivery` + @stolen_delivery,
                `stolen_mission` = `stolen_mission` + @stolen_mission,
                `destroyed_trailer` = `destroyed_trailer` + @destroyed_trailer,
                `working_time` = `working_time` + @working_time,
                `last_activity` = current_timestamp()
            ]]

        MySQL.Async.execute(sql,
            {
                ['@identifier'] = identifier,
                ['@distance'] = (not stolen and state ~= 'DESTROYED') and ecoCargo.km or 0,
                ['@goods_quality'] = (not stolen and state ~= 'DESTROYED') and quality or 0,
                ['@done_delivery'] = (not isMission and not stolen and state ~= 'DESTROYED') and increaseDoneDelivery or 0, -- if set extraStatDeliveryPoint then improves bad statistics
                ['@done_mission'] = (isMission and not stolen and state ~= 'DESTROYED') and increaseDoneMission or 0, -- DEFAULT: 1 (if 2 then improves bad statistics)
                ['@stolen_delivery'] = (not isMission and stolen and state ~= 'DESTROYED') and 1 or 0,
                ['@stolen_mission'] = (isMission and stolen and state ~= 'DESTROYED') and 1 or 0,
                ['@destroyed_trailer'] = state == 'DESTROYED' and 1 or 0,
                ['@working_time'] = not stolen and (os.time() - ecoCargo.startDelivery) or 0,
            }, function(rowsChanged)

                print("STAT FINISH INSERT OK", rowsChanged)
            end)


        if next(defenders) ~= nil and not stolen and state ~= 'DESTROYED' then

            for i = 1, #defenders do

                local sql = [[
                    INSERT INTO `eco_cargo_stats`
                    (
                        `identifier`,
                        `defender`,
                        `last_activity`
                    ) VALUES (
                        @identifier,
                        @defender,
                        current_timestamp()
                        )
                        ON DUPLICATE KEY UPDATE
                        `defender` = `defender` + @defender,
                        `last_activity` = current_timestamp()
                    ]]

                MySQL.Async.execute(sql,
                    {
                        ['@identifier'] = defenders[i],
                        ['@defender'] = 1,
                    }, function(rowsChanged)

                        print("STAT DEFENDERS INSERT OK", rowsChanged, defenders[i])
                    end)
            end
        end

        ECO.CARGO[plate] = nil
    end
end)

RegisterNetEvent('eco_cargo:changeMonitorOwner')
AddEventHandler('eco_cargo:changeMonitorOwner', function(oldOwner, plate)

    local _source = source

    ECO.CARGO[plate].monitorOwner = _source
    TriggerClientEvent('eco_cargo:changeMonitorOwner', oldOwner, plate, _source)
end)

RegisterNetEvent('eco_cargo:addMoney')
AddEventHandler('eco_cargo:addMoney', function(amount, moneyType)

    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if moneyType == 'black_money' or moneyType == 'bank' then

        xPlayer.addAccountMoney(moneyType, amount)
    else

        xPlayer.addMoney(amount)
    end

    TriggerClientEvent('eco_cargo:showNotification', _source, {
        type = 'money',
        text = _('add_money', amount, _(moneyType))
    })
end)

RegisterNetEvent('eco_cargo:societyAddMoney')
AddEventHandler('eco_cargo:societyAddMoney', function(amount, society)

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. society, function(account)

        account.addMoney(amount)
    end)

    TriggerClientEvent('eco_cargo:missionNotification', -1, {
        defender = society,
        type = 'money',
        text = _('add_society_money', _(society), amount)
    })
end)

RegisterNetEvent('eco_cargo:removeMoney')
AddEventHandler('eco_cargo:removeMoney', function(amount)

    local _source = source

    removeMoney(_source, amount)
end)

-- MISSION
RegisterNetEvent('eco_cargo:missionUpdate')
AddEventHandler('eco_cargo:missionUpdate', function(data, subject)

    local currentMission = ECO.MISSION[data.missionId]

    if currentMission then

        if subject == 'leave' then

            for i = 1, #currentMission.joined do

                if currentMission.joined[i] == data.player.identifier then

                    table.remove(currentMission.joined, i)
                end
            end

            data.type = 'warning'
            data.text = _('defender_left', data.player.characterName, data.player.job.grade_label)

            TriggerClientEvent('eco_cargo:missionNotification', -1, data)

        elseif subject == 'join' then

            table.insert(currentMission.joined, data.player.identifier)

            data.type = 'information'
            data.text = _('defender_joined', data.player.characterName, data.player.job.grade_label)

            TriggerClientEvent('eco_cargo:missionNotification', -1, data)

        elseif subject == 'delete' then

            data.owner = currentMission.owner
            data.defender = currentMission.defender
            data.type = 'warning'
            data.text = _('mission_is_over')

            TriggerClientEvent('eco_cargo:missionNotification', -1, data)
            TriggerClientEvent('eco_cargo:trailerSignal', -1, {}, currentMission.plate, false)

            ECO.MISSION[data.missionId] = nil
        end

        TriggerClientEvent('eco_cargo:missionUpdate', -1, ECO.MISSION)
    end
end)

RegisterNetEvent('eco_cargo:missionRegister')
AddEventHandler('eco_cargo:missionRegister', function(data)

    local missionId = data.missionId

    -- REGISTER MISSION
    if not ECO.MISSION[missionId] then

        ECO.MISSION[missionId] = {
            owner = data.owner,
            joined = {},
            defender = data.defender
        }

        TriggerClientEvent('eco_cargo:missionUpdate', -1, ECO.MISSION)
    end


    -- BROADCAST
    data.showChat = true
    data.type = "information"
    data.text = _('request_protection', data.owner.characterName)
    data.otherText = _('mission_alert')

    TriggerClientEvent('eco_cargo:missionNotification', -1, data)
end)

RegisterNetEvent('eco_cargo:showCountingZone')
AddEventHandler('eco_cargo:showCountingZone', function(coord)

    TriggerClientEvent('eco_cargo:showCountingZone', -1, coord)
end)

RegisterServerEvent('eco_cargo:trailerSignal')
AddEventHandler('eco_cargo:trailerSignal', function(coord, plate, state)

    TriggerClientEvent('eco_cargo:trailerSignal', -1, coord, plate, state)
end)

RegisterNetEvent('eco_cargo:updateDistance')
AddEventHandler('eco_cargo:updateDistance', function(data)

    for k, v in pairs(data) do

        MySQL.Async.execute("INSERT INTO `eco_cargo_distances` (`id`, `air`, `route`) VALUES (@id, @air, @route) ON DUPLICATE KEY UPDATE `air` = @air, `route` = @route",

            {
                ['@id'] = k,
                ['@air'] = v.air,
                ['@route'] = v.route
            }, function(rowsChanged)

                print("DISTANCES INSERT OK", rowsChanged)
            end)
    end
end)

RegisterNetEvent('eco_cargo:deleteDistance')
AddEventHandler('eco_cargo:deleteDistance', function(data)

    if type(data) == 'table' and next(data) then

        MySQL.Async.execute("DELETE FROM `eco_cargo_distances` WHERE `id` IN (" .. table.concat(data, ', ') .. ")", {},

            function(rowsChanged)

                print("DISTANCES DELETE OK", rowsChanged)
            end)
    end
end)


function removeMoney(_source, amount)

    local xPlayer = ESX.GetPlayerFromId(_source)

    xPlayer.removeMoney(amount)

    TriggerClientEvent('eco_cargo:showNotification', _source, {
        type = 'money',
        text = _('remove_money', amount)
    })
end


TriggerEvent('es:addGroupCommand', 'cargodiag', 'admin', function(source, args, user)

    TriggerClientEvent('eco_cargo:cargoDiagnostics', source)
    TriggerClientEvent('esx:showNotification', source, '~r~ECO CARGO:~s~ Diagnosztika')
end, function(source, args, user)

    TriggerClientEvent('chat:addMessage', source, { args = { "^1SYSTEM", "Ehhez nincs jogosultságod!" } })
end, { help = "ECO CARGO diagnosztika" })