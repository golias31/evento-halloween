-- ============================================
-- SISTEMA DE CAÇA DE FANTASMAS - CORRIGIDO
-- COM ANIMAÇÃO DE FOTO + FLASH
-- ============================================

local ActiveGhosts = {}
local FoundGhosts = {}
local MissionStarted = false

-- Função para verificar se é horário noturno
local function IsNightTime()
    local hour = GetClockHours()
    if Config.Halloween.GhostHunt.SpawnStartHour > Config.Halloween.GhostHunt.SpawnEndHour then
        return hour >= Config.Halloween.GhostHunt.SpawnStartHour or hour < Config.Halloween.GhostHunt.SpawnEndHour
    else
        return hour >= Config.Halloween.GhostHunt.SpawnStartHour and hour < Config.Halloween.GhostHunt.SpawnEndHour
    end
end

-- Função para spawnar fantasmas
local function SpawnGhosts()
    if not Config.Halloween.GhostHunt.Enable then return end
    
    print("^3[Halloween]^0 Iniciando spawn de fantasmas...")
    
    for k, coords in pairs(Config.Halloween.GhostHunt.GhostsLocation) do
        local pos = vector3(coords.x, coords.y, coords.z)
        
        local Model = Config.Halloween.GhostHunt.GhostModel
        RequestModel(Model)
        while not HasModelLoaded(Model) do
            Wait(10)
        end
        
        local ghost = CreatePed(4, Model, pos.x, pos.y, pos.z, coords.w, false, false)
        
        if DoesEntityExist(ghost) then
            SetEntityAsMissionEntity(ghost, true, true)
            FreezeEntityPosition(ghost, true)
            SetEntityInvincible(ghost, true)
            SetEntityCollision(ghost, false, false)
            SetEntityAlpha(ghost, 180, false)
            SetEntityProofs(ghost, true, true, true, true, true, true, true, true)
            
            -- Controlar visibilidade
            if Config.Halloween.GhostHunt.NightSpawn then
                local isNight = IsNightTime()
                SetEntityVisible(ghost, isNight, false)
            else
                SetEntityVisible(ghost, true, false)
            end
            
            ActiveGhosts[k] = {
                entity = ghost,
                coords = pos
            }
        end
        
        SetModelAsNoLongerNeeded(Model)
    end
    
    print("^2[Halloween VRP]^0 " .. #Config.Halloween.GhostHunt.GhostsLocation .. " fantasmas spawnados")
end

-- Função para limpar fantasmas
local function CleanupGhosts()
    for k, v in pairs(ActiveGhosts) do
        if v.entity and DoesEntityExist(v.entity) then
            DeleteEntity(v.entity)
        end
    end
    ActiveGhosts = {}
end

-- Thread para controlar visibilidade
if Config.Halloween.GhostHunt.NightSpawn then
    CreateThread(function()
        while true do
            Wait(30000)
            
            if MissionStarted then
                local isNight = IsNightTime()
                
                for k, ghost in pairs(ActiveGhosts) do
                    if ghost.entity and DoesEntityExist(ghost.entity) then
                        SetEntityVisible(ghost.entity, isNight, false)
                    end
                end
            end
        end
    end)
end

-- ANIMAÇÃO DE TIRAR FOTO COM FLASH
local function TakePhotoAnimation()
    local playerPed = PlayerPedId()
    
    -- Props da câmera
    local cameraModel = `prop_ing_camera_01`
    RequestModel(cameraModel)
    while not HasModelLoaded(cameraModel) do
        Wait(10)
    end
    
    -- Criar câmera
    local camera = CreateObject(cameraModel, 0, 0, 0, true, true, true)
    AttachEntityToEntity(camera, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    -- Animação
    RequestAnimDict("amb@world_human_paparazzi@male@base")
    while not HasAnimDictLoaded("amb@world_human_paparazzi@male@base") do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, "amb@world_human_paparazzi@male@base", "base", 8.0, -8.0, 2000, 49, 0, false, false, false)
    
    Wait(1000)
    
    -- FLASH
    SetFlash(0, 0, 500, 500, 500)
    
    -- Partículas
    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do
        Wait(10)
    end
    
    local coords = GetEntityCoords(playerPed)
    UseParticleFxAssetNextCall("core")
    local particle = StartParticleFxLoopedAtCoord("exp_grd_bzgas_smoke", coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 0.5, false, false, false, false)
    
    -- Som
    PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", true)
    
    Wait(1000)
    
    -- Limpar
    StopParticleFxLooped(particle, 0)
    ClearPedTasks(playerPed)
    DeleteObject(camera)
    SetModelAsNoLongerNeeded(cameraModel)
end

-- Comando para tirar foto
RegisterCommand(Config.Halloween.GhostHunt.PhotoCommand, function()
    if not MissionStarted then
        Notify("", Config.Halloween.Locals.GhostHunt['NotifyNeedStart'], 'error')
        return
    end
    
    if Config.Halloween.GhostHunt.NightSpawn and not IsNightTime() then
        Notify("", Config.Halloween.Locals.GhostHunt['NotifyGhostNotVisible'], 'error')
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestGhost = nil
    local closestDistance = 999999.0
    
    for k, ghost in pairs(ActiveGhosts) do
        if not FoundGhosts[k] then
            local distance = #(playerCoords - ghost.coords)
            if distance < closestDistance then
                closestDistance = distance
                closestGhost = k
            end
        end
    end
    
    if closestGhost and closestDistance < Config.Halloween.GhostHunt.PhotoDistance then
        -- ANIMAÇÃO
        TakePhotoAnimation()
        
        FoundGhosts[closestGhost] = true
        
        Player(cache.serverId).state:set("hghalloween_rewardplayer", true, true)
        TriggerServerEvent('server:HG-Halloween:RewardPlayer', 'GhostHunt')
        TriggerServerEvent('server:HG-Halloween:foundghost', closestGhost)
        
        Notify("", Config.Halloween.Locals.GhostHunt['NotifyPhoto'], 'success')
        
        -- Efeito no fantasma
        if ActiveGhosts[closestGhost].entity and DoesEntityExist(ActiveGhosts[closestGhost].entity) then
            local ghost = ActiveGhosts[closestGhost].entity
            
            CreateThread(function()
                local alpha = 180
                while alpha > 0 do
                    alpha = alpha - 10
                    SetEntityAlpha(ghost, alpha, false)
                    Wait(50)
                end
                DeleteEntity(ghost)
            end)
        end
    else
        Notify("", Config.Halloween.Locals.GhostHunt['NotifyNoClose'], 'error')
    end
end, false)

-- Evento para iniciar missão
RegisterNetEvent('client:HG-Halloween:StartGhostHunt', function()
    if MissionStarted then
        Notify("", "Ya iniciaste la misión", 'error')
        return
    end
    
    MissionStarted = true
    FoundGhosts = {}
    
    CleanupGhosts()
    SpawnGhosts()
    
    Notify("", "Misión iniciada! Usa /" .. Config.Halloween.GhostHunt.PhotoCommand .. " cerca de los fantasmas", 'success')
end)

-- Evento para parar missão
RegisterNetEvent('client:HG-Halloween:StopGhostHunt', function()
    MissionStarted = false
    FoundGhosts = {}
    CleanupGhosts()
end)

-- Debug
RegisterCommand("debugfantasmas", function()
    if not MissionStarted then
        print("^1Missão não iniciada^0")
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    print("^2========== DEBUG ==========^0")
    print("Fantasmas ativos: " .. #ActiveGhosts)
    print("Encontrados: " .. #FoundGhosts)
    
    for k, ghost in pairs(ActiveGhosts) do
        local distance = #(playerCoords - ghost.coords)
        print(string.format("#%d: %.1fm | Existe: %s", k, distance, tostring(DoesEntityExist(ghost.entity))))
    end
end, false)

-- Limpar ao desconectar
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupGhosts()
    end
end)

print("^2[Halloween VRP]^0 Sistema de Caça de Fantasmas com FOTO + FLASH carregado")
