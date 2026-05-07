RegisterNetEvent('chaos:crabWalk')
AddEventHandler('chaos:crabWalk', function(name, type, duration)
    if not exports.chaos:IsEffectActive(name) then
        print("Starting 'Crab Walk' effect.")
        Citizen.CreateThread(function()
            while exports.chaos:IsEffectActive(name) do
                local ped = PlayerPedId()
                if not IsPedInAnyVehicle(ped, false) then
                    DisableControlAction(0, 31, true)
                    SetControlNormal(0, 32, 0.0)
                end
                Citizen.Wait(0)
            end
            print("Last 'Crab Walk' effect ended.")
        end)
    end
    exports.chaos:AddEffectToUI(name, type, duration)
end)