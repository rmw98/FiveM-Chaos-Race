RegisterNetEvent('chaos:unlimitedStamina')
AddEventHandler('chaos:unlimitedStamina', function(name, type, duration)
    if not exports.chaos:IsEffectActive(name) then
        print("Starting 'Unlimited Stamina' effect.")
        Citizen.CreateThread(function()
            while exports.chaos:IsEffectActive(name) do
                RestorePlayerStamina(PlayerId(), 100.0) 
                Citizen.Wait(0)
            end
            print("Last 'Unlimited Stamina' effect ended.")
        end)
    end
    exports.chaos:AddEffectToUI(name, type, duration)
end)