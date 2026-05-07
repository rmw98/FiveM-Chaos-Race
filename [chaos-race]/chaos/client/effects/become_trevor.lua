RegisterNetEvent('chaos:becomeTrevor')
AddEventHandler('chaos:becomeTrevor', function(name, type, duration)
    exports.chaos:AddEffectToUI(name, type, duration)
    print("Activating 'Rage!' effect.")
    
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then return end
    
    local trevorModel = GetHashKey("player_two")

    -- === THE FIX IS HERE ===
    TriggerServerEvent('chaosrace:serverSetPlayerModel', trevorModel)
end)