-- Helper function to normalize a vector (make its length 1)
local function NormalizeVector(vec)
    local magnitude = #(vec)
    if magnitude > 0 then
        return vec / magnitude
    end
    return vector3(0.0, 0.0, 0.0)
end

RegisterNetEvent('chaos:divineIntervention')
AddEventHandler('chaos:divineIntervention', function(name, type, duration)
    if exports.chaos:IsEffectActive(name) then return end

    exports.chaos:AddEffectToUI(name, type, duration)
    print("Starting 'Divine Intervention' effect.")

    Citizen.CreateThread(function()
        local playerId = PlayerId()
        local playerPed = PlayerPedId()

        local projectileHashes = {
            GetHashKey("WEAPON_RPG"),
            GetHashKey("WEAPON_FIREWORK")
        }

        for _, hash in ipairs(projectileHashes) do
            RequestWeaponAsset(hash)
            local timeout = 200
            while not HasWeaponAssetLoaded(hash) and timeout > 0 do
                Citizen.Wait(10); timeout = timeout - 1
            end
            if timeout <= 0 then print("ERROR: Failed to load asset " .. hash) end
        end
        print("Divine Intervention weapon assets loaded.")

        -- Apply buffs
        SetEntityInvincible(playerPed, true)
        SetPedCanRagdoll(playerPed, false)
        SetPoliceIgnorePlayer(playerId, true)
        SetEveryoneIgnorePlayer(playerId, true)

        -- **THE FIX IS HERE:** Add explicit explosion-proofing.
        -- SetEntityProofs(entity, bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, smokeProof, drownProof)
        SetEntityProofs(playerPed, false, false, true, false, false, false, false, false)

        -- Main effect loop
        while exports.chaos:IsEffectActive(name) do
            if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) then
                local chosenProjectile = projectileHashes[math.random(#projectileHashes)]
                local startPos = GetEntityCoords(playerPed) + vector3(0.0, 0.0, 1.0)
                local randomDirection = NormalizeVector(vector3(math.random(-100, 100)/100.0, math.random(-100, 100)/100.0, math.random(50, 100)/100.0))
                local endPos = startPos + (randomDirection * 200.0)

                ShootSingleBulletBetweenCoords(
                    startPos.x, startPos.y, startPos.z,
                    endPos.x, endPos.y, endPos.z,
                    250, true, chosenProjectile, playerPed,
                    true, false, -1.0
                )
            end
            Citizen.Wait(math.random(150, 300))
        end

        print("Divine Intervention ended. Cleaning up assets and player state.")
        -- Clean up buffs and state
        if DoesEntityExist(playerPed) then
            SetEntityInvincible(playerPed, false)
            SetPedCanRagdoll(playerPed, true)
            -- **THE FIX IS HERE:** Also remove the explicit explosion-proofing.
            SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
        end
        SetPoliceIgnorePlayer(playerId, false)
        SetEveryoneIgnorePlayer(playerId, false)

        for _, hash in ipairs(projectileHashes) do
            RemoveWeaponAsset(hash)
        end
    end)
end)