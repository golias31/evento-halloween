-- ============================================
-- SISTEMA DO PAYASO - MELHORADO E MAIS DIFÍCIL
-- ============================================

local ClownConfig = {
    Enable = true,
    
    -- NPC Payaso (CEMENTERIO)
    NPC = {
        Model = `s_m_y_clown_01`,
        Coords = vector4(-1753.86, -203.54, 57.52, 150.0),
        Blip = {
            Enable = true,
            Sprite = 484,
            Color = 1,
            Name = "🎪 Payaso Misterioso",
            Scale = 0.8
        }
    },
    
    -- Item requerido
    RequiredItem = "chocolate",
    RequiredAmount = 1,
    
    -- Zombies terrestres (MÁS DIFÍCILES)
    Zombies = {
        Amount = 15,  -- AUMENTADO
        Models = {
            `u_m_y_zombie_01`,
            `u_m_o_filmnoir`
        },
        Health = 300,  -- AUMENTADO
        Armor = 100,   -- AUMENTADO
        SpawnRadius = 20.0,
        Weapon = `WEAPON_MACHETE`,
        WeaponChance = 80  -- 80% de ter arma
    },
    
    -- NOVO: Zombies voadores com vassoura
    FlyingZombies = {
        Enable = true,
        Amount = 3,
        Model = `u_m_y_zombie_01`,
        BroomModel = `sum_prop_dufoil_boardbag_01a`,  -- Vassoura
        Health = 250,
        Weapon = `WEAPON_KNIFE`,
        FlyHeight = 15.0,
        Speed = 8.0,
        FollowDistance = 50.0
    },
    
    -- Boss Payaso (MUITO MAIS DIFÍCIL)
    Boss = {
        Model = `s_m_y_clown_01`,
        Health = 3000,  -- AUMENTADO
        Weapon = `WEAPON_MG`,
        Ammo = 9999,
        Damage = 100,  -- AUMENTADO
        Armor = 200,   -- AUMENTADO
        AggroRange = 80.0,  -- AUMENTADO
        Accuracy = 85  -- AUMENTADO
    },
    
    -- Recompensas
    Rewards = {
        Enable = true,
        Items = {
            ['dinheirosujer'] = {amount = 25000, chance = 100},
            ['c4'] = {amount = 3, chance = 50},
            ['antibiotico'] = {amount = 2, chance = 75},
        },
        Money = 5000
    },
    
    -- Cooldown (4 HORAS)
    Cooldown = 240,  -- 240 minutos = 4 horas
    
    -- Textos
    Locals = {
        MenuTitle = "🎪 Payaso Misterioso",
        MenuDesc = "Este payaso quiere un dulce...",
        MenuContent = "Tengo algo especial para ti... pero primero, dame un dulce. ¿Qué dices? 🍬",
        AcceptTitle = "Dar Dulce",
        AcceptDesc = "Entregar chocolate al payaso",
        CancelTitle = "Rechazar",
        NoItem = "¡No tienes el dulce que quiero!",
        OnCooldown = "Ya jugaste conmigo recientemente. Vuelve en %s minutos",
        EventActive = "Ya hay un evento activo! Espera a que terminen",
        SpawnStart = "🎃 ¡El Payaso liberó su ejército de zombis!",
        BossSpawned = "👹 ¡EL JEFE PAYASO HA APARECIDO! ¡Cuidado!",
        BossKilled = "💀 ¡JEFE PAYASO DERROTADO!",
        AllKilled = "✅ ¡Todos los zombis fueron eliminados!",
        InteractText = "[E] Hablar con el Payaso"
    }
}

-- Variables globales
local ClownMission = {
    Active = false,
    BossSpawned = false,
    BossEntity = nil,
    Zombies = {},
    FlyingZombies = {},
    BossBlip = nil
}

-- Crear NPC Payaso
CreateThread(function()
    Wait(2000)
    
    if not ClownConfig.Enable then return end
    
    local Model = ClownConfig.NPC.Model
    RequestModel(Model)
    while not HasModelLoaded(Model) do
        Wait(10)
    end
    
    local NPC = CreatePed(4, Model, 
        ClownConfig.NPC.Coords.x, 
        ClownConfig.NPC.Coords.y, 
        ClownConfig.NPC.Coords.z, 
        ClownConfig.NPC.Coords.w, 
        false, true)
    
    SetEntityAsMissionEntity(NPC, true, true)
    SetBlockingOfNonTemporaryEvents(NPC, true)
    SetEntityInvincible(NPC, true)
    FreezeEntityPosition(NPC, true)
    
    RequestAnimDict("amb@world_human_stand_impatient@male@no_sign@base")
    while not HasAnimDictLoaded("amb@world_human_stand_impatient@male@no_sign@base") do
        Wait(10)
    end
    TaskPlayAnim(NPC, "amb@world_human_stand_impatient@male@no_sign@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    SetModelAsNoLongerNeeded(Model)
    
    print("^2[Halloween VRP]^0 NPC Payaso criado no cemitério")
end)

-- Criar Blip
if ClownConfig.NPC.Blip.Enable then
    CreateThread(function()
        local blip = AddBlipForCoord(ClownConfig.NPC.Coords.x, ClownConfig.NPC.Coords.y, ClownConfig.NPC.Coords.z)
        SetBlipSprite(blip, ClownConfig.NPC.Blip.Sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, ClownConfig.NPC.Blip.Scale)
        SetBlipColour(blip, ClownConfig.NPC.Blip.Color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(ClownConfig.NPC.Blip.Name)
        EndTextCommandSetBlipName(blip)
    end)
end

-- Zona de interação
local clownZone = lib.zones.box({
    coords = vec3(ClownConfig.NPC.Coords.x, ClownConfig.NPC.Coords.y, ClownConfig.NPC.Coords.z),
    size = vec3(3, 3, 3),
    rotation = ClownConfig.NPC.Coords.w,
    debug = false,
    onEnter = function()
        lib.showTextUI(ClownConfig.Locals.InteractText, {
            position = "left-center",
            icon = 'hand'
        })
    end,
    inside = function()
        if IsControlJustReleased(0, 38) then -- E
            OpenClownMenu()
        end
    end,
    onExit = function()
        lib.hideTextUI()
    end,
})

-- Menu do payaso
function OpenClownMenu()
    -- Verificar se já tem evento ativo
    if ClownMission.Active then
        Notify("", ClownConfig.Locals.EventActive, 'error')
        return
    end
    
    lib.callback('server:halloween:checkClownCooldown', false, function(canStart, message)
        if not canStart then
            Notify("", message, 'error')
            return
        end
        
        local alert = lib.alertDialog({
            header = ClownConfig.Locals.MenuTitle,
            content = ClownConfig.Locals.MenuContent,
            centered = true,
            cancel = true,
            labels = {
                confirm = ClownConfig.Locals.AcceptTitle,
                cancel = ClownConfig.Locals.CancelTitle
            }
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('server:halloween:startClownEvent')
        end
    end)
end

-- Evento de iniciar spawns
RegisterNetEvent('client:halloween:startClownEvent', function()
    if ClownMission.Active then return end
    
    ClownMission.Active = true
    
    Notify("", ClownConfig.Locals.SpawnStart, 'info')
    
    -- Spawn zombies terrestres
    SpawnGroundZombies()
    
    -- Spawn zombies voadores
    if ClownConfig.FlyingZombies.Enable then
        SpawnFlyingZombies()
    end
    
    -- Spawn boss após 15 segundos
    SetTimeout(15000, function()
        SpawnBoss()
    end)
end)

-- SPAWN ZOMBIES TERRESTRES (MAIS FORTES)
function SpawnGroundZombies()
    local centerCoords = vector3(ClownConfig.NPC.Coords.x, ClownConfig.NPC.Coords.y, ClownConfig.NPC.Coords.z)
    
    for i = 1, ClownConfig.Zombies.Amount do
        CreateThread(function()
            local angle = math.random() * 2 * math.pi
            local radius = math.random(5, ClownConfig.Zombies.SpawnRadius)
            local x = centerCoords.x + radius * math.cos(angle)
            local y = centerCoords.y + radius * math.sin(angle)
            local z = centerCoords.z
            
            local _, groundZ = GetGroundZFor_3dCoord(x, y, z + 100.0, false)
            
            local model = ClownConfig.Zombies.Models[math.random(#ClownConfig.Zombies.Models)]
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
            
            local zombie = CreatePed(4, model, x, y, groundZ, 0.0, true, true)
            
            if DoesEntityExist(zombie) then
                SetEntityHealth(zombie, ClownConfig.Zombies.Health)
                SetEntityMaxHealth(zombie, ClownConfig.Zombies.Health)
                SetPedArmour(zombie, ClownConfig.Zombies.Armor)
                SetEntityAsMissionEntity(zombie, true, true)
                SetPedCombatAttributes(zombie, 46, true)
                SetPedCombatAttributes(zombie, 0, false)
                SetPedCombatRange(zombie, 2)
                SetPedFleeAttributes(zombie, 0, false)
                SetPedRelationshipGroupHash(zombie, GetHashKey("HATES_PLAYER"))
                
                -- DAR ARMA (80% de chance)
                if math.random(100) <= ClownConfig.Zombies.WeaponChance then
                    GiveWeaponToPed(zombie, ClownConfig.Zombies.Weapon, 1, false, true)
                end
                
                TaskCombatHatedTargetsAroundPed(zombie, 100.0, 0)
                
                table.insert(ClownMission.Zombies, zombie)
                
                -- NÃO DESAPARECEM AUTOMATICAMENTE - só quando morrem ou missão acaba
            end
            
            SetModelAsNoLongerNeeded(model)
        end)
        
        Wait(500)
    end
end

-- NOVO: SPAWN ZOMBIES VOADORES COM VASSOURA
function SpawnFlyingZombies()
    local centerCoords = vector3(ClownConfig.NPC.Coords.x, ClownConfig.NPC.Coords.y, ClownConfig.NPC.Coords.z)
    
    for i = 1, ClownConfig.FlyingZombies.Amount do
        CreateThread(function()
            local angle = (i - 1) * (360 / ClownConfig.FlyingZombies.Amount)
            local radius = 15.0
            local x = centerCoords.x + radius * math.cos(math.rad(angle))
            local y = centerCoords.y + radius * math.sin(math.rad(angle))
            local z = centerCoords.z + ClownConfig.FlyingZombies.FlyHeight
            
            local model = ClownConfig.FlyingZombies.Model
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
            
            local zombie = CreatePed(4, model, x, y, z, 0.0, true, true)
            
            if DoesEntityExist(zombie) then
                SetEntityHealth(zombie, ClownConfig.FlyingZombies.Health)
                SetEntityMaxHealth(zombie, ClownConfig.FlyingZombies.Health)
                SetEntityAsMissionEntity(zombie, true, true)
                
                -- Fazer voar
                SetEntityInvincible(zombie, false)
                TaskSkydive(zombie)
                SetPedCanRagdoll(zombie, false)
                
                -- Dar arma
                GiveWeaponToPed(zombie, ClownConfig.FlyingZombies.Weapon, 1, false, true)
                
                SetPedCombatAttributes(zombie, 46, true)
                SetPedCombatRange(zombie, 2)
                SetPedRelationshipGroupHash(zombie, GetHashKey("HATES_PLAYER"))
                
                -- Criar vassoura (visual)
                local broomModel = ClownConfig.FlyingZombies.BroomModel
                RequestModel(broomModel)
                while not HasModelLoaded(broomModel) do
                    Wait(10)
                end
                
                local broom = CreateObject(broomModel, x, y, z, true, true, false)
                AttachEntityToEntity(broom, zombie, GetPedBoneIndex(zombie, 0), 0.0, 0.0, -0.5, 90.0, 0.0, 0.0, false, false, false, false, 2, true)
                
                table.insert(ClownMission.FlyingZombies, {zombie = zombie, broom = broom})
                
                -- Thread para seguir jogador
                CreateThread(function()
                    while DoesEntityExist(zombie) and not IsEntityDead(zombie) and ClownMission.Active do
                        Wait(1000)
                        
                        local playerPed = PlayerPedId()
                        local playerCoords = GetEntityCoords(playerPed)
                        local zombieCoords = GetEntityCoords(zombie)
                        local distance = #(zombieCoords - playerCoords)
                        
                        if distance < ClownConfig.FlyingZombies.FollowDistance then
                            -- Seguir jogador no ar
                            local targetCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z + ClownConfig.FlyingZombies.FlyHeight)
                            TaskGoToCoordAnyMeans(zombie, targetCoords.x, targetCoords.y, targetCoords.z, ClownConfig.FlyingZombies.Speed, 0, 0, 786603, 0xbf800000)
                            
                            -- Atacar se perto
                            if distance < 15.0 then
                                TaskCombatPed(zombie, playerPed, 0, 16)
                            end
                        end
                    end
                    
                    -- Limpar vassoura se zombie morreu
                    if DoesEntityExist(broom) then
                        DeleteEntity(broom)
                    end
                end)
            end
            
            SetModelAsNoLongerNeeded(model)
            SetModelAsNoLongerNeeded(broomModel)
        end)
        
        Wait(1000)
    end
end

-- SPAWN BOSS (MUITO MAIS FORTE)
function SpawnBoss()
    if ClownMission.BossSpawned then return end
    
    ClownMission.BossSpawned = true
    
    Notify("", ClownConfig.Locals.BossSpawned, 'error')
    
    local coords = vector3(ClownConfig.NPC.Coords.x + 15, ClownConfig.NPC.Coords.y, ClownConfig.NPC.Coords.z)
    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 100.0, false)
    
    local model = ClownConfig.Boss.Model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    local boss = CreatePed(4, model, coords.x, coords.y, groundZ, 0.0, true, true)
    
    if DoesEntityExist(boss) then
        ClownMission.BossEntity = boss
        
        SetEntityHealth(boss, ClownConfig.Boss.Health)
        SetEntityMaxHealth(boss, ClownConfig.Boss.Health)
        SetPedArmour(boss, ClownConfig.Boss.Armor)
        
        GiveWeaponToPed(boss, ClownConfig.Boss.Weapon, ClownConfig.Boss.Ammo, false, true)
        SetPedInfiniteAmmo(boss, true, ClownConfig.Boss.Weapon)
        
        SetEntityAsMissionEntity(boss, true, true)
        SetPedCombatAttributes(boss, 46, true)
        SetPedCombatAttributes(boss, 5, true)
        SetPedCombatAttributes(boss, 1, true)
        SetPedCombatRange(boss, 3)
        SetPedFleeAttributes(boss, 0, false)
        SetPedAccuracy(boss, ClownConfig.Boss.Accuracy)
        SetPedRelationshipGroupHash(boss, GetHashKey("HATES_PLAYER"))
        
        -- Blip no boss
        ClownMission.BossBlip = AddBlipForEntity(boss)
        SetBlipSprite(ClownMission.BossBlip, 487)
        SetBlipColour(ClownMission.BossBlip, 1)
        SetBlipScale(ClownMission.BossBlip, 1.5)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("👹 BOSS PAYASO")
        EndTextCommandSetBlipName(ClownMission.BossBlip)
        
        -- Thread para perseguir jogador
        CreateThread(function()
            while DoesEntityExist(boss) and not IsEntityDead(boss) do
                Wait(1000)
                
                local bossCoords = GetEntityCoords(boss)
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(bossCoords - playerCoords)
                
                if distance < ClownConfig.Boss.AggroRange then
                    TaskCombatPed(boss, playerPed, 0, 16)
                else
                    TaskCombatHatedTargetsAroundPed(boss, ClownConfig.Boss.AggroRange, 0)
                end
            end
            
            if DoesEntityExist(boss) and IsEntityDead(boss) then
                OnBossKilled()
            end
        end)
    end
    
    SetModelAsNoLongerNeeded(model)
end

-- Quando o boss morre
function OnBossKilled()
    Notify("", ClownConfig.Locals.BossKilled, 'success')
    
    -- Remover blip
    if ClownMission.BossBlip then
        RemoveBlip(ClownMission.BossBlip)
        ClownMission.BossBlip = nil
    end
    
    TriggerServerEvent('server:halloween:clownBossKilled')
    
    Wait(5000)
    CleanupClownMission()
end

-- Limpar missão
function CleanupClownMission()
    -- Limpar zombies terrestres
    for k, zombie in pairs(ClownMission.Zombies) do
        if DoesEntityExist(zombie) then
            DeleteEntity(zombie)
        end
    end
    
    -- Limpar zombies voadores
    for k, data in pairs(ClownMission.FlyingZombies) do
        if DoesEntityExist(data.zombie) then
            DeleteEntity(data.zombie)
        end
        if DoesEntityExist(data.broom) then
            DeleteEntity(data.broom)
        end
    end
    
    -- Limpar boss
    if ClownMission.BossEntity and DoesEntityExist(ClownMission.BossEntity) then
        DeleteEntity(ClownMission.BossEntity)
    end
    
    -- Remover blip
    if ClownMission.BossBlip then
        RemoveBlip(ClownMission.BossBlip)
    end
    
    ClownMission = {
        Active = false,
        BossSpawned = false,
        BossEntity = nil,
        Zombies = {},
        FlyingZombies = {},
        BossBlip = nil
    }
    
    Notify("", ClownConfig.Locals.AllKilled, 'success')
end

-- Limpar ao desconectar
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupClownMission()
    end
end)

print("^2[Halloween VRP]^0 Sistema del Payaso MELHORADO (4h cooldown, zombies voadores, mais difícil)")
