RegisterNetEvent('chaos:randomMetamorphosis')
AddEventHandler('chaos:randomMetamorphosis', function(name, effectType, duration)
    if exports.chaos:IsEffectActive(name) then return end
    exports.chaos:AddEffectToUI(name, effectType, duration)

    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then return end

    local availableModels = {
        -- (Your existing list of models is fine)
        { name = "a_f_y_juggalo_01", type = 'base' },
        { name = "a_m_m_fatlatin_01", type = 'base' },
        { name = "s_m_y_clown_01", type = 'base' },
        { name = "s_m_m_movalien_01", type = 'base' },
        { name = "u_m_y_juggernaut_01", type = 'base' },
        { name = "JessePinkman", type = 'custom', hash = `JessePinkman` }
    }

    local randomModelInfo
    local newModelHash
    repeat
        randomModelInfo = availableModels[math.random(#availableModels)]
        newModelHash = (randomModelInfo.type == 'base') and GetHashKey(randomModelInfo.name) or randomModelInfo.hash
    until newModelHash ~= GetEntityModel(playerPed)

    -- === THE FIX IS HERE ===
    -- Instead of changing the model locally, we ask the server to do it for us.
    -- The server will then tell everyone (including us and spectators) about the change.
    TriggerServerEvent('chaosrace:serverSetPlayerModel', newModelHash)
end)