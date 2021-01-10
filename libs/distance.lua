function calcRoute(v1, v2)

    local calculate, dist

    SetNewWaypoint(v2.x, v2.y)

    local try = 0

    repeat

        try = try + 1
        Citizen.Wait(500)

        if (try == 10) then

            SetEntityCoords(PlayerPedId(), v2)
            SetNewWaypoint(v1.x, v1.y)
            refV1 = v2
            Citizen.Wait(4000)
        end


        calculate = CalculateTravelDistanceBetweenPoints(v1, v2)

    until (calculate ~= 100000 or try > 19)


    DeleteWaypoint()
    dist = 0

    if calculate ~= 100000 then

        dist = calculate
    end

    return dist
end
