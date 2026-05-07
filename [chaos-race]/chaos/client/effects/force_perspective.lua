RegisterNetEvent('chaos:forcePerspective')
AddEventHandler('chaos:forcePerspective', function(name, type, duration)
    if not exports.chaos:IsEffectActive(name) then
        print("Starting 'Forced Perspective' effect (with Bike/Cycle Logic).")
        Citizen.CreateThread(function()
            while exports.chaos:IsEffectActive(name) do
                Citizen.Wait(0)
                local playerPed = PlayerPedId()
                DisableControlAction(0, 37, true)
                if not IsPedInAnyVehicle(playerPed, false) then
                    SetFollowPedCamViewMode(4)
                else
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    local vehicleClass = GetVehicleClass(vehicle)
                    if vehicleClass == 8 or vehicleClass == 13 then
                        SetFollowPedCamViewMode(4)
                    else
                        SetFollowVehicleCamViewMode(4)
                        if GetFollowVehicleCamViewMode() ~= 4 then
                            SetFollowVehicleCamViewMode(1)
                            SetGameplayCamRelativeHeading(0.0)
                            SetGameplayCamRelativePitch(0.0, 1.0)
                            DisableControlAction(0, 1, true)
                            DisableControlAction(0, 2, true)
                        end
                    end
                end
            end
            print("Last 'Forced Perspective' effect ended. Returning camera control.")
        end)
    end
    exports.chaos:AddEffectToUI(name, type, duration)
end)