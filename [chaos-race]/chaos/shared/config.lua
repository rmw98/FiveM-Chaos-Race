-- File: chaos/shared/config.lua
-- This file centralizes all configuration for the chaos resource.
Config = {}

-- Time in seconds between chaos effects.
Config.chaosInterval = 10 

-- The master list of all chaos effects.
-- 'cost' is a NEW property for the Haunting system.
-- Effects with a 'cost' can be purchased by Ghosts.
Config.Effects = {

    -- 'any' context
    {name = "Black Hole", clientEvent = "chaos:blackHole", duration = 25000,      type = 'bad', context = {'any'},    weight = 1},
    {name = "Bouncy Castle", clientEvent = "chaos:bouncyCastle", duration = 25000,      type = 'bad', context = {'any'},    weight = 2},
    {name = "Explosive Zombies", clientEvent = "chaos:zombies", duration = 40000,      type = 'bad', context = {'any'},    weight = 1, cost = 4500},
    {name = "Fake Death", clientEvent = "chaos:fakeDeath", duration = 3000,      type = 'bad', context = {'any'},    weight = 4, cost = 1200},
    {name = "Forced Perspective", clientEvent = "chaos:forcePerspective", duration = 20000,      type = 'bad', context = {'any'},    weight = 3},
    {name = "Freedom Delivery", clientEvent = "chaos:divineIntervention", duration = 15000,      type = 'good', context = {'any'},    weight = 2},
    {name = "Full Health & Armor", clientEvent = "chaos:giveHealthArmor", duration = 0,      type = 'good', context = {'any'},    weight = 5},
    {name = "IBIZA 2008", clientEvent = "chaos:ibiza2008", duration = 48000,      type = 'bad', context = {'any'},    weight = 1},
    {name = "Mass Hysteria", clientEvent = "chaos:massHysteria", duration = 25000,      type = 'bad', context = {'any'},    weight = 2, cost = 2000},
    {name = "Meteor Shower", clientEvent = "chaos:meteorShower", duration = 20000,      type = 'bad', context = {'any'},    weight = 1, cost = 5000},
    {name = "News Team", clientEvent = "chaos:newsTeam", duration = 30000,      type = 'bad', context = {'any'},    weight = 2},
    {name = "Peds Riot", clientEvent = "chaos:pedsRiot", duration = 15000,      type = 'bad', context = {'any'},    weight = 2, cost = 2500},
    {name = "Realistic LA", clientEvent = "chaos:realisticLA", duration = 30000,      type = 'bad', context = {'any'},    weight = 2},
    {name = "Sussy Baka", clientEvent = "chaos:sussyBaka", duration = 45000,      type = 'bad', context = {'any'},    weight = 1, cost = 3500},
    {name = "Tube Man Army", clientEvent = "chaos:tubeManArmy", duration = 30000,      type = 'bad', context = {'any'},    weight = 2},
    {name = "Vehicle Rain", clientEvent = "chaos:vehicleRain", duration = 15000,      type = 'bad', context = {'any'},    weight = 1, cost = 4000},
    {name = "Wanted Level Up", clientEvent = "chaos:wantedLevelUp", duration = 0,      type = 'bad', context = {'any'},    weight = 5, cost = 500},
    {name = "What's Behind?", clientEvent = "chaos:flipCamera", duration = 15000,      type = 'bad', context = {'any'},    weight = 4},

    -- 'car' context
    {name = "Blow The Bloody Doors Off!", clientEvent = "chaos:blowDoorsOff", duration = 0,      type = 'bad', context = {'car'},    weight = 7, cost = 300},
    {name = "Drunk Driving", clientEvent = "chaos:drunkCam", duration = 15000,      type = 'bad', context = {'car'},    weight = 5, cost = 1000},
    {name = "Engine Damage", clientEvent = "chaos:engineDamage", duration = 0,      type = 'bad', context = {'car'},    weight = 8, cost = 400},
    {name = "ENGLAND!", clientEvent = "chaos:englandChant", duration = 6000,      type = 'bad', context = {'car'},    weight = 3},
    {name = "Ice Rink", clientEvent = "chaos:iceRink", duration = 10000,      type = 'bad', context = {'car'},    weight = 5, cost = 1500},
    {name = "Jesus Take The Wheel", clientEvent = "chaos:jesusTakeTheWheel", duration = 45000,      type = 'bad', context = {'car'},    weight = 1, cost = 8000},
    {name = "Kachow!", clientEvent = "chaos:kachow", duration = 25000,      type = 'bad', context = {'car'},    weight = 1},
    {name = "Marked Man", clientEvent = "chaos:markedMan", duration = 45000,      type = 'bad', context = {'car'},    weight = 1, cost = 3500},
    {name = "No Fuel", clientEvent = "chaos:engineCutoff", duration = 0,      type = 'bad', context = {'car'},    weight = 6, cost = 600},
    {name = "Pop Tires", clientEvent = "chaos:popTires", duration = 0,      type = 'bad', context = {'car'},    weight = 8, cost = 750},
    {name = "Reverse Boost", clientEvent = "chaos:reverseBoost", duration = 3000,      type = 'bad', context = {'car'},    weight = 4},
    {name = "Speed", clientEvent = "chaos:needForSpeed", duration = 30000,      type = 'bad', context = {'car'},    weight = 5},
    {name = "Unscheduled Pit Stop", clientEvent = "chaos:detachWheel", duration = 0,      type = 'bad', context = {'car'},    weight = 7, cost = 900},
    {name = "Unscheduled Stunt", clientEvent = "chaos:forcedStunt", duration = 0,      type = 'good', context = {'car'},    weight = 3},
    {name = "Vehicle Boost", clientEvent = "chaos:vehicleBoost", duration = 5000,      type = 'good', context = {'car'},    weight = 5},
    {name = "Void Touch", clientEvent = "chaos:voidTouch", duration = 20000,      type = 'good', context = {'car'},    weight = 2},
    {name = "Where We're Going...", clientEvent = "chaos:flyingCars", duration = 30000,      type = 'good', context = {'car'},    weight = 2},

    -- 'foot' context
    {name = "Aim For The Stars", clientEvent = "chaos:launchPlayer", duration = 0,      type = 'bad', context = {'foot'},    weight = 3, cost = 1000},
    {name = "Crab Walk", clientEvent = "chaos:crabWalk", duration = 8000,      type = 'bad', context = {'foot'},    weight = 4},
    {name = "Desync?", clientEvent = "chaos:slipperyFeet", duration = 5000,      type = 'bad', context = {'foot'},    weight = 6, cost = 250},
    {name = "Instant Supercar", clientEvent = "chaos:instantSupercar", duration = 0,      type = 'good', context = {'foot'},    weight = 2},
    {name = "Races Have Cougars?", clientEvent = "chaos:spawnCougars", duration = 0,      type = 'bad', context = {'foot'},    weight = 3, cost = 2000},
    {name = "Random Metamorphosis", clientEvent = "chaos:randomMetamorphosis", duration = 0,      type = 'bad', context = {'foot'},    weight = 1},
    {name = "Run Forrest!", clientEvent = "chaos:forceRun", duration = 15000,      type = 'bad', context = {'foot'},    weight = 2},
    {name = "Tied Shoelaces", clientEvent = "chaos:tripPlayer", duration = 0,      type = 'bad', context = {'foot'},    weight = 8, cost = 150},
    {name = "Trevor?", clientEvent = "chaos:becomeTrevor", duration = 0,      type = 'bad', context = {'foot'},    weight = 1},
    {name = "Unlimited Stamina", clientEvent = "chaos:unlimitedStamina", duration = 10000,      type = 'good', context = {'foot'},    weight = 5},

    -- 'plane' context
    {name = "Engine Failure", clientEvent = "chaos:engineFailure", duration = 5000,      type = 'bad', context = {'plane'},    weight = 10, cost = 1500},

    -- 'boat' context
    {name = "Leaky Boat", clientEvent = "chaos:leakyBoat", duration = 10000,      type = 'bad', context = {'boat'},    weight = 10, cost = 1000},

    -- Multi-context effects
    {name = "Ejecto Seato Cuz!", clientEvent = "chaos:ejectPlayer", duration = 0,      type = 'bad', context = {'car', 'plane', 'boat'},    weight = 5, cost = 1800},
    {name = "La Lamborghini", clientEvent = "chaos:LaLamborghini", duration = 45000,      type = 'bad', context = {'car', 'foot'},    weight = 1},
    {name = "Mandatory Conscription", clientEvent = "chaos:mandatoryConscription", duration = 30000,      type = 'bad', context = {'car', 'foot'},    weight = 1},
    {name = "Repair Vehicle", clientEvent = "chaos:repairVehicle", duration = 0,      type = 'good', context = {'car', 'plane', 'boat'},    weight = 5},
}
