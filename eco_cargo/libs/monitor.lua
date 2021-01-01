--
-- Created by IntelliJ IDEA.
-- User: ekhion
-- Date: 2020. 11. 25.
-- Time: 12:55
--

function speedLimitMonitor(speed)

    if speed > Config.speedLimit[ECO.MONITOR.area] + 5 then

        if not ECO.MONITOR.overSpeed then

            sendHudLiveData('overSpeed', 1)
            ECO.MONITOR.overSpeed = true
        end
    else

        if ECO.MONITOR.overSpeed then

            sendHudLiveData('overSpeed', 0)
            ECO.MONITOR.overSpeed = false
        end
    end
end

function SetHudSpeedLimit(speedLimit)

    if ECO.MONITOR.hudSpeedLimit ~= speedLimit then

        -- NOTIFY
        sendHudLiveData('speedLimit', speedLimit)
        ECO.MONITOR.hudSpeedLimit = speedLimit
    end
end

function rollMonitor(speed, roll, frameTime)

    if speed > ECO.CARGO.params.rollMonitoringSpeed then

        local rollLimit = ECO.CARGO.params.damageRoll - (((speed - ECO.CARGO.params.rollMonitoringSpeed) * 0.20) ^ 2) / 100
        if rollLimit < 4 then rollLimit = 4 end

        if roll > rollLimit then

            ECO.CARGO.quality = ECO.CARGO.quality - frameTime * 4
            ECO.MONITOR.ServerSaveRequest = true

            -- NOTIFY
            if not ECO.MONITOR.rollNotify then

                sendHudLiveData('roll')
                ECO.MONITOR.rollNotify = true
            end

        else

            ECO.MONITOR.rollNotify = false
        end


        if not IsVehicleOnAllWheels(ECO.CARGO.trailer) then

            ECO.CARGO.quality = ECO.CARGO.quality - frameTime * 4
            ECO.MONITOR.ServerSaveRequest = true

            -- NOTIFY
            if not ECO.MONITOR.wheelNotify then

                sendHudLiveData('wheel')
                ECO.MONITOR.wheelNotify = true
            end
        else

            ECO.MONITOR.wheelNotify = false
        end
    end
end

function overturningMonitor(roll)

    if roll > ECO.CARGO.params.overturn then

        ECO.CARGO.quality = 0
        ECO.MONITOR.ServerSaveRequest = true

        -- END CARGO (FAIL)
        DoCustomHudText('fail', _('delivery_failed'))
        finishCargo('DESTROYED')
    end
end

function collisionMonitor(speed, prevSpeed)

    if ECO.CARGO.params.collisionSensitivity < 1000 then

        local diff = math.abs(speed - prevSpeed)

        if diff > 5 and (GetLastMaterialHitByEntity(ECO.CARGO.trailer) ~= 0 or
                GetLastMaterialHitByEntity(ECO.CARGO.attachedTo) ~= 0) then

            if not ECO.MONITOR.ImpactFlash and ECO.CARGO.params.impactFlash < diff then

                AddExplosion( GetEntityCoords(ECO.CARGO.trailer), 7, 0.6, true, false, 5.0 )
                ECO.MONITOR.ImpactFlash = true
            end

            ECO.CARGO.quality = ECO.CARGO.quality - ((diff / ECO.CARGO.params.collisionSensitivity) ^ 2) * 100
        end
    end
end
