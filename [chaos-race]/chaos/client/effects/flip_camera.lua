-- File: chaos/client/effects/flip_camera.lua
-- VERSION 2: Correctly positions the camera for a true flipped effect.

local isFlipCameraActive = false
local flippedCamera = 0

local function endFlipCamera()
    print("Flip Camera: Restoring normal camera.")
    if flippedCamera ~= 0 and DoesCamExist(flippedCamera) then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(flippedCamera, true)
        flippedCamera = 0
    end
end

RegisterNetEvent('chaos:flipCamera')
AddEventHandler('chaos:flipCamera', function(name, effectType, duration)
    exports.chaos:AddEffectToUI(name, effectType, duration)
    
    if not isFlipCameraActive then
        isFlipCameraActive = true
        print("Starting 'Flip Camera' effect.")

        Citizen.CreateThread(function()
            flippedCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            
            while exports.chaos:IsEffectActive(name) do
                local playerPed = PlayerPedId()
                local gameplayCamRot = GetGameplayCamRot(2)
                
                -- *** THE FIX IS HERE: Attach the camera to the player's head. ***
                -- This ensures the camera is in the correct position before being flipped.
                AttachCamToPedBone(flippedCamera, playerPed, 31086, 0.0, 0.0, 0.0, true)

                -- Now apply the rotation, flipping it 180 degrees
                SetCamRot(flippedCamera, gameplayCamRot.x, gameplayCamRot.y, gameplayCamRot.z + 180.0, 2)
                
                RenderScriptCams(true, false, 0, true, true)
                Citizen.Wait(0)
            end

            endFlipCamera()
            isFlipCameraActive = false
        end)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then endFlipCamera() end
end)