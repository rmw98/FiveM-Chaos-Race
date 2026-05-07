RegisterNetEvent('chaos:slipperyFeet')
AddEventHandler('chaos:slipperyFeet', function(name, type, duration)
    if not exports.chaos:IsEffectActive(name) then
        Citizen.CreateThread(function()
            while exports.chaos:IsEffectActive(name) do
                local playerPed = PlayerPedId()
                if not IsPedInAnyVehicle(playerPed, false) then
                    local pushForce, randomX, randomY = 1.75, (math.random() * 2.0 - 1.0), (math.random() * 2.0 - 1.0)
                    local slide_duration = GetGameTimer() + math.random(75, 150)
                    while GetGameTimer() < slide_duration and exports.chaos:IsEffectActive(name) do
                        ApplyForceToEntity(playerPed, 1, randomX * pushForce, randomY * pushForce, 0.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                        Citizen.Wait(0)
                    end
                end
                Citizen.Wait(math.random(300, 600))
            end
        end)
    end
    exports.chaos:AddEffectToUI(name, type, duration)
end)