-- ============================================
-- SISTEMA DE CAÇA DE ABÓBORAS - COM ZOMBIES E EXPLOSÕES
-- ============================================

local ActivePumpkins = {}
local OpenedPumpkins = {}
local MissionStarted = false

-- Sistema de chances para abóboras
local PumpkinChances = {
    Treat = 60,        -- 60% chance de doces
    Zombie = 30,       -- 30% chance de zombies
    Explosion = 10     -- 10% chance de explosão
}

-- Função para spawn das abóboras
local function SpawnPumpkins()
    if not Config.Halloween.PumpkinHunt.Enable then return end
    
    for k, v in pairs(Config.Halloween.PumpkinHunt.Location) do
        local coords = vector3(v.x, v.y, v.z)
        
        -- Pegar altura correta do chão
        local _, groundZ = GetGroundZFor_3dCoord(v.x, v.y, v.z + 5.0, false)
        
        if groundZ == 0.0 then
            groundZ = v.z
        end
        
        local spawnCoords = vector3(v.x, v.y, groundZ)
        
        -- Spawnar abóbora
        local Model = Config.Halloween.PumpkinHunt.Model
        RequestModel(Model)
        while not HasModelLoaded(Model) do
            Wait(10)
        end
        
        local pumpkin = CreateObject(Model, spawnCoords.x, spawnCoords.y, spawnCoords.z - 1.0, false, false, false)
        
        SetEntityAsMissionEntity(pumpkin, true, true)
        FreezeEntityPosition(pumpkin, true)
        SetEntityCollision(pumpkin, false, false)
        
        ActivePumpkins[k] = {
            entity = pumpkin,
            coords = spawnCoords,
            opened = false
        }
        
        SetModelAsNoLongerNeeded(Model)
    end
    
    print("^2[Halloween VRP]^0 Total de " .. #Config.Halloween.PumpkinHunt.Location .. " abóboras spawnadas")
end

-- Função para limpar abóboras
local function CleanupPumpkins()
    for k, v in pairs(ActivePumpkins) do
        if v.entity and DoesEntityExist(v.entity) then
            DeleteEntity(v.entity)
        end
    end
    ActivePumpkins = {}
end

-- Função para spawnar zombies na abóbora
local function SpawnPumpkinZombies(coords, amount)
    local zombieModels = Config.Halloween.ZombieModels or {`u_m_y_zombie_01`, `u_m_o_filmnoir`}
    
    for i = 1, amount do
        CreateThread(function()
            -- Posição aleatória ao redor da abóbora
            local angle = math.random() * 2 * math.pi
            local radius = math.random(2, 5)
            local x = coords.x + radius * math.cos(angle)
            local y = coords.y + radius * math.sin(angle)
            
            local _, groundZ = GetGroundZFor_3dCoord(x, y, coords.z + 5.0, false)
            
            local model = zombieModels[math.random(#zombieModels)]
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
            
            local zombie = CreatePed(4, model, x, y, groundZ, 0.0, true, true)
            
            if DoesEntityExist(zombie) then
                SetEntityHealth(zombie, 150)
                SetPedArmour(zombie, 30)
                SetEntityAsMissionEntity(zombie, true, true)
                SetPedCombatAttributes(zombie, 46, true)
                SetPedCombatAttributes(zombie, 0, false)
                SetPedCombatRange(zombie, 2)
                SetPedFleeAttributes(zombie, 0, false)
                SetPedRelationshipGroupHash(zombie, GetHashKey("HATES_PLAYER"))
                
                -- Dar arma ao zombie (50% chance)
                if math.random(100) <= 50 then
                    GiveWeaponToPed(zombie, `WEAPON_KNIFE`, 1, false, true)
                end
                
                TaskCombatHatedTargetsAroundPed(zombie, 50.0, 0)
                
                -- Remover após 2 minutos
                SetTimeout(120000, function()
                    if DoesEntityExist(zombie) then
                        DeleteEntity(zombie)
                    end
                end)
            end
            
            SetModelAsNoLongerNeeded(model)
        end)
        
        Wait(300)
    end
end

-- Thread para desenhar markers e interação
CreateThread(function()
    while true do
        local sleep = 1000
        
        if MissionStarted and Config.Halloween.PumpkinHunt.Enable then
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            for k, pumpkin in pairs(ActivePumpkins) do
                if pumpkin and not OpenedPumpkins[k] then
                    local distance = #(playerCoords - pumpkin.coords)
                    
                    if distance < 30.0 then
                        sleep = 0
                        
                        -- Desenhar marker (seta)
                        if Config.Halloween.PumpkinHunt.VisualEffects.Marker.Enable then
                            local marker = Config.Halloween.PumpkinHunt.VisualEffects.Marker
                            DrawMarker(
                                marker.Type,
                                pumpkin.coords.x, pumpkin.coords.y, pumpkin.coords.z + 1.0,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                marker.Size.x, marker.Size.y, marker.Size.z,
                                marker.Color.r, marker.Color.g, marker.Color.b, marker.Color.a,
                                marker.BobUpAndDown,
                                false,
                                2,
                                marker.Rotate,
                                nil,
                                nil,
                                false
                            )
                        end
                        
                        -- Luz laranja
                        if Config.Halloween.PumpkinHunt.VisualEffects.Light.Enable and distance < 15.0 then
                            local light = Config.Halloween.PumpkinHunt.VisualEffects.Light
                            DrawLightWithRange(
                                pumpkin.coords.x, pumpkin.coords.y, pumpkin.coords.z + 0.5,
                                light.Color.r, light.Color.g, light.Color.b,
                                light.Range,
                                light.Intensity
                            )
                        end
                        
                        -- Interação
                        if distance < 2.0 then
                            lib.showTextUI(string.format(
                                Config.Halloween.Locals.PumpkinHunt['InteractOpen'], 
                                'E'
                            ), {
                                position = "left-center",
                                icon = 'hand'
                            })
                            
                            if IsControlJustReleased(0, 38) then -- E
                                OpenPumpkin(k)
                            end
                        else
                            lib.hideTextUI()
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Função para abrir abóbora COM SISTEMA DE CHANCES
function OpenPumpkin(pumpkinIndex)
    if OpenedPumpkins[pumpkinIndex] then
        Notify("", Config.Halloween.Locals.PumpkinHunt['NotifyAlreadyOpened'], 'error')
        return
    end
    
    if not MissionStarted then
        Notify("", Config.Halloween.Locals.PumpkinHunt['NeedStart'], 'error')
        return
    end
    
    lib.hideTextUI()
    
    -- Animação de abertura
    if lib.progressBar({
        duration = 2000,
        label = Config.Halloween.Locals.PumpkinHunt['InteractPumpkinOpen'],
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'amb@prop_human_bum_bin@base',
            clip = 'base'
        },
    }) then
        -- Marcar como aberta
        OpenedPumpkins[pumpkinIndex] = true
        
        -- Som de abertura
        if Config.Halloween.PumpkinHunt.Audio.OpenPumpkin then
            exports.xsound:PlayUrl("pumpkin_open", Config.Halloween.PumpkinHunt.Audio.OpenPumpkin, Config.Halloween.PumpkinHunt.Audio.Volume, false)
        end
        
        -- NOVO SISTEMA DE CHANCES
        local roll = math.random(100)
        local pumpkinCoords = ActivePumpkins[pumpkinIndex].coords
        
        if roll <= PumpkinChances.Treat then
            -- TREAT - Dar recompensa
            Player(cache.serverId).state:set("hghalloween_rewardplayer", true, true)
            TriggerServerEvent('server:HG-Halloween:RewardPlayer', 'PumpkinHunt')
            Notify("", "🎃 ¡Dulce! Recibiste golosinas de Halloween", 'success')
            
        elseif roll <= (PumpkinChances.Treat + PumpkinChances.Zombie) then
            -- TRICK - Spawnar ZOMBIES
            local zombieAmount = math.random(1, 2)
            SpawnPumpkinZombies(pumpkinCoords, zombieAmount)
            
            -- Efeito visual
            AddExplosion(pumpkinCoords.x, pumpkinCoords.y, pumpkinCoords.z, 'EXPLOSION_FLARE', 0.5, true, false, 0.0)
            
            Notify("", "💀 ¡Zombies salieron de la calabaza! ¡Cuidado!", 'error')
            
        else
            -- TRICK - Explosão
            AddExplosion(pumpkinCoords.x, pumpkinCoords.y, pumpkinCoords.z, 'EXPLOSION_BARREL', 2.0, true, false, 0.3)
            Notify("", "💥 ¡BOOM! La calabaza explotó", 'error')
        end
        
        -- Remover abóbora
        if ActivePumpkins[pumpkinIndex] and DoesEntityExist(ActivePumpkins[pumpkinIndex].entity) then
            DeleteEntity(ActivePumpkins[pumpkinIndex].entity)
        end
        
        -- Notificar servidor
        TriggerServerEvent('server:HG-Halloween:openedPumpkin')
    end
end

-- Evento para iniciar missão
RegisterNetEvent('client:HG-Halloween:StartPumpkinHunt', function()
    if MissionStarted then
        Notify("", "Ya iniciaste la misión", 'error')
        return
    end
    
    MissionStarted = true
    OpenedPumpkins = {}
    
    CleanupPumpkins()
    SpawnPumpkins()
    
    Notify("", "Misión de Calabazas iniciada! Busca las flechas naranjas", 'success')
end)

-- Evento para parar missão
RegisterNetEvent('client:HG-Halloween:StopPumpkinHunt', function()
    MissionStarted = false
    OpenedPumpkins = {}
    CleanupPumpkins()
end)

-- Limpar ao desconectar
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupPumpkins()
    end
end)

print("^2[Halloween VRP]^0 Sistema de Caça de Abóboras com ZOMBIES e EXPLOSÕES carregado")
