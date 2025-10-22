-- Função para desenhar texto 3D
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Função para reproduzir sons locais
function PlaySound(ID, FileName, Volume, Pos, Loop)
    local path = ('sounds/%s.ogg'):format(FileName)
    local data = LoadResourceFile(GetCurrentResourceName(), path)
    if data then
        local soundFile = 'nui://' .. GetCurrentResourceName() .. '/sounds/'.. FileName..'.ogg'
        if Pos and Pos ~= nil then
            exports['xsound']:PlayUrlPos(ID, soundFile, Volume, vector3(Pos.x, Pos.y, Pos.z), Loop)
        else
            exports['xsound']:PlayUrl(ID, soundFile, Volume, Loop)
        end
    else
        print("^1[Halloween VRP]^0 Arquivo de som não encontrado: " .. path)
    end
end

function AddBlackout()
    MissionData.BlackoutActive = true
    CreateThread(function()
        while MissionData.BlackoutActive do
            Wait(0)
            SetArtificialLightsState(true)
            SetTimecycleModifier("nightvision")
            SetTimecycleModifierStrength(0.5)
            NetworkOverrideClockTime(23, 0, 0)
            SetWeatherTypeNowPersist("HALLOWEEN")
        end
    end)
end

function AddStorm()
    MissionData.StormActive = true
    CreateThread(function()
        while MissionData.StormActive do
            Wait(0)
            SetArtificialLightsState(true)
            SetTimecycleModifier("nightvision")
            SetTimecycleModifierStrength(0.5)
            NetworkOverrideClockTime(23, 0, 0)
            SetWeatherTypeNowPersist("THUNDER")
        end
    end)
end

function HauntedHouseStart()
    return true
end

function HauntedHouseEnd()
end

function HauntedHouseAddFlashlight()
    local Wep = GetSelectedPedWeapon(cache.ped)
    if Wep ~= GetHashKey(Config.Halloween.Mission.Weprequired) then
        Notify(Config.Halloween.Locals.Main['noflashlight'], '', 'error')
        return false
    end
    return true
end
