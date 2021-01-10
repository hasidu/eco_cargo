local LastCCVehicle = nil
local CurrentCCMetersPerSecond = nil
local SpeedDiffTolerance = (0.5 / 3.6)
local LastIdealPedalPressure = 0.0
local IncreasePressure = false
local LastVehicleHealth = nil
local requestSpeed = 0


Citizen.CreateThread(function()

    while Config.enableSpeedControl do

        Citizen.Wait(0)

        if ECO.PLAYER.isApprovedDriver then

            if LastCCVehicle then

                if IsControlJustPressed(0, 72) or IsControlJustPressed(0, 76) then -- brake or handbrake
                    UnsetCruiseControl()
                else
                    local engineHealth = GetVehicleEngineHealth(ECO.Vehicle)

                    if LastVehicleHealth and ((LastVehicleHealth - engineHealth) > 10) then
                        UnsetCruiseControl()
                    else
                        LastVehicleHealth = engineHealth

                        local curSpeed = GetEntitySpeed(ECO.Vehicle)

                        local diff = CurrentCCMetersPerSecond - curSpeed

                        if diff > SpeedDiffTolerance then -- car is slower then required
                            local pedalPressure = 0.95

                            if IsSteering(ECO.Vehicle) then
                                pedalPressure = 0.4
                            end

                            if IncreasePressure then
                                LastIdealPedalPressure = LastIdealPedalPressure + 0.025
                                IncreasePressure = false
                            end

                            SetControlNormal(0, 71, pedalPressure)
                        elseif diff > -(4 * SpeedDiffTolerance) then -- when speed is met
                            ApplyIdealPedalPressure()
                        else
                            LastIdealPedalPressure = 0.2
                        end
                    end
                end
            end

            if IsControlJustReleased(0, 96) then

                if requestSpeed < 200 then

                    requestSpeed = requestSpeed + 10.0
                    msginf(_('tempomat_speed', requestSpeed), 3000)
                    SetCruiseControl(requestSpeed)
                end
            end

            if IsControlJustReleased(0, 97) then

                if requestSpeed >= 10 then

                    requestSpeed = requestSpeed - 10.0
                    msginf(_('tempomat_speed', requestSpeed), 3000)
                    SetCruiseControl(requestSpeed)
                end
            end
        else

            UnsetCruiseControl()
            Citizen.Wait(1000)
        end
    end
end)

function ApplyIdealPedalPressure()

    if not IncreasePressure then
        IncreasePressure = true
    end
    SetControlNormal(0, 71, LastIdealPedalPressure)
end

function IsSteering(veh)

    return GetVehicleSteeringAngle(veh) > 10.0
end

function SetCruiseControl(kmh)

    local mpsSpeed = KmhToMps(kmh)
    local veh = GetVehiclePedIsIn(PlayerPedId())
    local maxSpeed = GetVehicleHandlingFloat(veh, "CHandlingData", "fInitialDriveMaxFlatVel")
    SetVehicleMaxSpeed(veh, maxSpeed)
    LastCCVehicle = veh
    CurrentCCMetersPerSecond = mpsSpeed
end

function UnsetCruiseControl()

    LastCCVehicle = nil
    CurrentCCMetersPerSecond = nil
    LastVehicleHealth = nil
    requestSpeed = 0
end
