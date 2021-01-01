--
-- Created by IntelliJ IDEA.
-- User: ekhion
-- Date: 2020. 12. 03.
-- Time: 12:12
--

function calculatePrice(propertyNames, km, product)

    local defender = product.defender
    local value = product.value

    if defender ~= '' then

        return {
            freightFee = value,
            illegalPrice = value,
        }
    end


    --Defaults
    km = km or 1
    local kilometerFee = Config.kilometerFee or 90
    local distanceMultiplier = Config.distanceMultiplier or 0.99
    local baseFee = Config.baseFee or 100

    local freightFee = km * kilometerFee * (distanceMultiplier ^ km) + baseFee
    local maxPrice = freightFee * 2
    local illegalPrice = value


    if propertyNames and next(propertyNames) ~= nil then

        --Price modifiers
        for i = 1, #propertyNames do

            local propertyName = propertyNames[i]

            if Config.propertyParams[propertyName] then

                local propertyParams = Config.propertyParams[propertyName]

                freightFee = freightFee + percentageValue((maxPrice - freightFee), propertyParams['priceMultiplier'])
                illegalPrice = illegalPrice + percentageValue(value, propertyParams['illegalPriceMultiplier'])
            end
        end
    end

    freightFee = math.round(freightFee)
    illegalPrice = math.round(illegalPrice)

    return {
        freightFee = freightFee,
        illegalPrice = illegalPrice,
    }
end

function payData(data)

    -- PAYMENT
    local payData = {
        -- GOODS
        priceDeduction = 0,
        pricePayment = 0,

        -- TRIALER
        cautionDeduction = 0,
        cautionPayment = 0,

        -- PAYABLE
        payable = 0,
        defenderSocietyPayable = 0,

        freightFee = data.freightFee
    }

    local tDamage = ((1000 - data.trailerHealth) * 0.001) ^ 2
    local gDamage = data.quality * 0.01

    if data.stolen then

        payData.pricePayment = math.round(data.illegalPrice * gDamage)
        payData.priceDeduction = data.illegalPrice - payData.pricePayment

        payData.payable = payData.pricePayment
    else

        payData.cautionPayment = math.round(data.cautionMoney * (1 - tDamage))
        payData.cautionDeduction = data.cautionMoney - payData.cautionPayment

        payData.pricePayment = math.round(data.freightFee * gDamage)
        payData.priceDeduction = data.freightFee - payData.pricePayment

        if data.product.defender ~= '' then

            payData.defenderSocietyPayable = math.round(payData.pricePayment * (Config.defenderSocietyPaymentPercent * 0.01))
        end

        payData.payable = payData.pricePayment - payData.defenderSocietyPayable + payData.cautionPayment
    end

    return payData
end

function calculateParams(propertyNames)

    --Defaults
    local params = {
        rollMonitoringSpeed = 1000,
        overturn = 80,
        damageRoll = 80,
        collisionSensitivity = 1000,
        impactFlash = 1000,
        illegal = 0
    }

    if propertyNames and next(propertyNames) ~= nil then


        for i = 1, #propertyNames do

            local propertyName = propertyNames[i]

            if Config.propertyParams[propertyName] then

                local property = Config.propertyParams[propertyName]

                setProperty(property, params, 'rollMonitoringSpeed', 'min')
                setProperty(property, params, 'damageRoll', 'min')
                setProperty(property, params, 'overturn', 'min')
                setProperty(property, params, 'collisionSensitivity', 'min')
                setProperty(property, params, 'impactFlash', 'min')
                setProperty(property, params, 'illegal', 'max')
            end
        end
    end

    return json.encode(params)
end




