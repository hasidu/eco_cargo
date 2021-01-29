Config = {}
Config.Locale = 'hu'

-- MULTI CHARACTER
-- If true then wait for 'esx:kashloaded' trigger! -- README.MD
Config.kashacters = false

-- a member of a defensive faction is prohibited from launching a mission he defends
Config.disableMissionStartForDefenders = true

-- Included teb_speed_controll: RP Friendly Cruise Control/Speed Limiter (https://github.com/hojgr/teb_speed_control)
Config.enableSpeedControl = false

Config.illegalFactions = {
    'vagos',
    'ballas',
    'gang',
    'bluegang',
    'family',
    'yakuza',
    'lostmc',
    'cayoperico',
    'cardem',
    'unemployed'
}

Config.lawEnforcementFactions = {
    'police',
    'agency'
}

-- TACHOGRAF
Config.speedLimit = {
    country = 90,
    city = 60
}

-- MONEY TYPE FOR STOLEN CARGO
Config.stolenCargoPaymentType = 'black_money' -- OPTIONS: 'money', 'black_money', 'bank'; DEFAULT: 'black_money',
Config.stolenMissionPaymentMultiplier = 2

-- Delay time between the start of two transports (the cp disappears)
Config.cargoRequestDelay = 1 -- DEFAULT: 1, in minute

Config.kilometerFee = 90 -- DEFAULT: 90, Kilométerenkénti díj

Config.distanceMultiplier = 0.99 -- DEFAULT: 0.99,  Távolság szorzó (1 alatt csökkenti a távolság arányában a kifizetést)

Config.baseFee = 100 -- DEFAULT: 100, Kiállási alapdíj

Config.countingZoneRadius = 40 -- DEFAULT: 40 -- Defenders must be within that range

-- SAFETY REGULATIONS
Config.propertyParams = {
    -- Magas értékű
    high_value = {
        rollMonitoringSpeed = 0, -- DEFAULT 50 KM/H (activating damageRoll monitor)
        overturn = 0, -- over max roll = Goods destroyed, DEFAULT 40
        damageRoll = 0, -- DEFAULT 6 -- Over value damaged the goods
        collisionSensitivity = 0, -- 0 = INSENSITIVE, DEFAULT 60 (FULL GOODS DESTROY COLLISION SPEED IN KM/H)
        priceMultiplier = 40, -- 40% -- increase basic freightFee (kilometerFee * distanceMultiplier + baseFee)
        illegalPriceMultiplier = 0 -- 0% -- increase illegalBasePrice for database(value)
    },

    -- Robbanásveszélyes
    explosive = {
        rollMonitoringSpeed = 45,
        overturn = 30,
        damageRoll = 6,
        collisionSensitivity = 40,
        priceMultiplier = 40, -- %
        illegalPriceMultiplier = 0,
        impactFlash = 50 --km/h
    },

    -- Törékeny
    fragile = {
        rollMonitoringSpeed = 45,
        overturn = 40,
        damageRoll = 6,
        collisionSensitivity = 60,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0,
    },

    -- Tűzveszélyes
    flammable = {
        rollMonitoringSpeed = 0,
        overturn = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0,
        impactFlash = 50 --km/h
    },

    -- Mérgező
    toxic = {
        rollMonitoringSpeed = 0,
        overturn = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0
    },

    -- Maró
    corrodent = {
        rollMonitoringSpeed = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        overturn = 0,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0
    },

    -- Túlsúlyos
    heavy = {
        rollMonitoringSpeed = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        overturn = 0,
        priceMultiplier = 40,
        illegalPriceMultiplier = 0,
    },

    -- Hűtött
    refrigerate = {
        rollMonitoringSpeed = 0,
        overturn = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        illegalPriceMultiplier = 0
    },

    -- Szennyező
    pollutant = {
        rollMonitoringSpeed = 0,
        overturn = 0,
        damageRoll = 0,
        collisionSensitivity = 0,
        priceMultiplier = 40, -- %
        illegalPriceMultiplier = 0
    },
    -- illegal
    illegal = {
        illegal = 1
    },
    -- trailer signal
    marked_on_the_map = {
        marked_on_the_map = 1
    },

    -- possible improving statistics
    high_sensitivity = {
        rollMonitoringSpeed = 35,
        overturn = 40,
        damageRoll = 4,
        collisionSensitivity = 40,
        extraStatDeliveryPoint = 1, -- incrase mission and normal delivery (improving statistics)
        extraStatQualityMultiplier = 2, -- cargo quality Multiplier (improving statistics)
        impactFlash = 40 --km/h
    },
}

-- RANK CONDITIONS
Config.rank = {
    { vulnerable = 0, all_done = 0, quality_rate = 0, success_rate = 0 },       -- iron
    { vulnerable = 5, all_done = 50, quality_rate = 90, success_rate = 90 },    -- bronze
    { vulnerable = 30, all_done = 150, quality_rate = 95, success_rate = 95 },  -- silver
    { vulnerable = 90, all_done = 400, quality_rate = 97, success_rate = 97 },  -- gold
    { vulnerable = 150, all_done = 800, quality_rate = 99, success_rate = 99 }, -- platinum
}

-- TITLE CONDITIONS
Config.title = {
    { distance = 0, rank = 1 },     -- Newbie,
    { distance = 300, rank = 2 },   -- Enthusiast,
    { distance = 1000, rank = 3 },  -- Skilled Worker,
    { distance = 2500, rank = 3 },  -- Professional,
    { distance = 4000, rank = 3 },  -- Master,
    { distance = 5500, rank = 3 },  -- Instructor,
    { distance = 7500, rank = 4 },  -- Elite,
    { distance = 10000, rank = 4 }, -- King of the Road,
    { distance = 12000, rank = 4 }, -- Legend,
    { distance = 14500, rank = 5 }, -- Divine Champion,
}

-- ILLEGAL TARGETS
Config.illegalTargetZones = {
    {
        name = 'Cherry Pie',
        address = 'Grand Senora Desert - Baytree Canyon Rd',
        description = 'Illegális árú átvevő',
        actionpoint = vector3(-66.87, 1878.26, 197.96)
    },
    {
        name = 'Pajta',
        address = 'Great Chaparral - Route 68',
        description = 'Illegális árú átvevő',
        actionpoint = vector3(-87.88, 2805.13, 54.29)
    },
    {
        name = 'Flamingo',
        address = 'Redwood Lights Track - Senora Rd',
        description = 'Illegális árú átvevő',
        actionpoint = vector3(895.0, 2172.67, 50.29)
    },
    {
        name = 'Supermarket',
        address = 'Grand Senora Desert - Route 68',
        description = 'Illegális árú átvevő',
        actionpoint = vector3(596.1, 2801.67, 41.16)
    },
}

-- MISSION
Config.missionBlipSprite = 478 -- DEFAULT: 478 radar_contraband
Config.missionBlipColor = 5 -- DEFAULT: 5 orange
Config.missionTrailerSignalInterval = 20 -- DEFAULT: 20 in sec
Config.defenderSocietyPaymentPercent = 70 -- DEFAULT: 70 - védelmi díj jutalék = áru értékének 70 %-a

-- TRUCKS
Config.approvedVehicles = {
    "hauler",
    "phantom",
    "phantom3",
    "packer"
}

for i = 1, #Config.approvedVehicles do

    Config.approvedVehicles[GetHashKey(Config.approvedVehicles[i])] = Config.approvedVehicles[i]
end

-- ZONE MAP: https:--imgvol.cdn.lcpdfr.com/screenshots/monthly_2015_06/LSSD_Patrol_Zones.png.a9d508cd773ddae957219efd0df43df3.png
Config.zoneData = {
    AIRP = { "city", "Los Santos International Airport" },
    ALAMO = { "country", "Alamo Sea" },
    ALTA = { "city", "Alta" },
    ARMYB = { "country", "Fort Zancudo" },
    BANHAMC = { "country", "Banham Canyon Dr" },
    BANNING = { "city", "Banning" },
    BEACH = { "city", "Vespucci Beach" },
    BHAMCA = { "country", "Banham Canyon" },
    BRADP = { "country", "Braddock Pass" },
    BRADT = { "country", "Braddock Tunnel" },
    BURTON = { "city", "Burton" },
    CALAFB = { "country", "Calafia Bridge" },
    CANNY = { "country", "Raton Canyon" },
    CCREAK = { "country", "Cassidy Creek" },
    CHAMH = { "city", "Chamberlain Hills" },
    CHIL = { "country", "Vinewood Hills" },
    CHU = { "country", "Chumash" },
    CMSW = { "country", "Chiliad Mountain State Wilderness" },
    CYPRE = { "city", "Cypress Flats" },
    DAVIS = { "city", "Davis" },
    DELBE = { "city", "Del Perro Beach" },
    DELPE = { "city", "Del Perro" },
    DELSOL = { "city", "La Puerta" },
    DESRT = { "country", "Grand Senora Desert" },
    DOWNT = { "city", "Downtown" },
    DTVINE = { "city", "Downtown Vinewood" },
    EAST_V = { "city", "East Vinewood" },
    EBURO = { "city", "El Burro Heights" },
    ELGORL = { "country", "El Gordo Lighthouse" },
    ELYSIAN = { "city", "Elysian Island" },
    GALFISH = { "country", "Galilee" },
    GOLF = { "city", "GWC and Golfing Society" },
    GRAPES = { "country", "Grapeseed" },
    GREATC = { "country", "Great Chaparral" },
    HARMO = { "country", "Harmony" },
    HAWICK = { "city", "Hawick" },
    HORS = { "city", "Vinewood Racetrack" },
    HUMLAB = { "country", "Humane Labs and Research" },
    JAIL = { "country", "Bolingbroke Penitentiary" },
    KOREAT = { "city", "Little Seoul" },
    LACT = { "country", "Land Act Reservoir" },
    LAGO = { "country", "Lago Zancudo" },
    LDAM = { "country", "Land Act Dam" },
    LEGSQU = { "city", "Legion Square" },
    LMESA = { "city", "La Mesa" },
    LOSPUER = { "city", "La Puerta" },
    MIRR = { "city", "Mirror Park" },
    MORN = { "city", "Morningwood" },
    MOVIE = { "city", "Richards Majestic" },
    MTCHIL = { "country", "Mount Chiliad" },
    MTGORDO = { "country", "Mount Gordo" },
    MTJOSE = { "country", "Mount Josiah" },
    MURRI = { "city", "Murrieta Heights" },
    NCHU = { "country", "North Chumash" },
    NOOSE = { "city", "N.O.O.S.E" },
    OCEANA = { "city", "Pacific Ocean" },
    PALCOV = { "country", "Paleto Cove" },
    PALETO = { "country", "Paleto Bay" },
    PALFOR = { "country", "Paleto Forest" },
    PALHIGH = { "city", "Palomino Highlands" },
    PALMPOW = { "country", "Palmer-Taylor Power Station" },
    PBLUFF = { "city", "Pacific Bluffs" },
    PBOX = { "city", "Pillbox Hill" },
    PROCOB = { "country", "Procopio Beach" },
    RANCHO = { "city", "Rancho" },
    RGLEN = { "country", "Richman Glen" },
    RICHM = { "country", "Richman" },
    ROCKF = { "city", "Rockford Hills" },
    RTRAK = { "country", "Redwood Lights Track" },
    SANAND = { "city", "San Andreas" },
    SANCHIA = { "country", "San Chianski Mountain Range" },
    SANDY = { "country", "Sandy Shores" },
    SKID = { "city", "mission Row" },
    SLAB = { "country", "Stab City" },
    STAD = { "city", "Maze Bank Arena" },
    STRAW = { "city", "Strawberry" },
    TATAMO = { "country", "Tataviam Mountains" },
    TERMINA = { "city", "Terminal" },
    TEXTI = { "city", "Textile City" },
    TONGVAH = { "country", "Tongva Hills" },
    TONGVAV = { "country", "Tongva Valley" },
    VCANA = { "city", "Vespucci Canals" },
    VESP = { "city", "Vespucci" },
    VINE = { "city", "Vinewood" },
    WINDF = { "country", "Ron Alternates Wind Farm" },
    WVINE = { "city", "West Vinewood" },
    ZANCUDO = { "country", "Zancudo River" },
    ZP_ORT = { "city", "Port of South Los Santos" },
    ZQ_UAR = { "country", "Davis Quartz" },
}