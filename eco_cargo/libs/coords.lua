function stringToVector3(string)

    if not string or string == '' then return false end

    local tmp = {}
    local count = 1

    for coord in string:gmatch("%-?%d+%.%d+") do

        tmp[count] = tonumber(coord)
        count = count + 1
    end

    if count >= 3 then

        local vector = vector3(tmp[1], tmp[2], tmp[3])

        local heading = tmp[4] or 0.0

        return { vector, heading }
    end

    return false
end


function coordsPharser(coordsString)

    if not coordsString or coordsString == '' then return end

    local out = {}

    if string.find(coordsString, "|") then

        local parts = explode(coordsString, "|")

        for i = 1, #parts do

            table.insert(out, stringToVector3(parts[i]))
        end
    else

        table.insert(out, stringToVector3(coordsString))
    end

    return out
end