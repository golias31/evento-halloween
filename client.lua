-- ============================================
-- CLIENT PRINCIPAL - HALLOWEEN VRP
-- COM VISUALIZAÇÃO DE PROGRESSO NO MENU
-- ============================================

-- Variáveis globais
MissionData = {
    HauntedHouseActive = false,
    BlackoutActive = false,
    StormActive = false,
}

-- Criar NPC principal
CreateThread(function()
    Wait(2000)
    
    if not Config.Halloween.GhostHunt.Enable then return end
    
    local Model = Config.Halloween.GhostHunt.NPC.Model
    RequestModel(Model)
    while not HasModelLoaded(Model) do
        Wait(10)
    end
    
    local NPC = CreatePed(4, Model, 
        Config.Halloween.GhostHunt.NPC.Coords.x, 
        Config.Halloween.GhostHunt.NPC.Coords.y, 
        Config.Halloween.GhostHunt.NPC.Coords.z, 
        Config.Halloween.GhostHunt.NPC.Coords.w, 
        false, true)
    
    SetEntityAsMissionEntity(NPC, true, true)
    SetBlockingOfNonTemporaryEvents(NPC, true)
    SetEntityInvincible(NPC, true)
    FreezeEntityPosition(NPC, true)
    
    -- Animação (braços cruzados)
    RequestAnimDict("amb@world_human_hang_out_street@female_arms_crossed@base")
    while not HasAnimDictLoaded("amb@world_human_hang_out_street@female_arms_crossed@base") do
        Wait(10)
    end
    TaskPlayAnim(NPC, "amb@world_human_hang_out_street@female_arms_crossed@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    SetModelAsNoLongerNeeded(Model)
    
    print("^2[Halloween VRP]^0 NPC principal criado")
end)

-- Criar blip
if Config.Halloween.GhostHunt.Blip.Enable then
    CreateThread(function()
        local blip = AddBlipForCoord(
            Config.Halloween.GhostHunt.NPC.Coords.x, 
            Config.Halloween.GhostHunt.NPC.Coords.y, 
            Config.Halloween.GhostHunt.NPC.Coords.z
        )
        SetBlipSprite(blip, Config.Halloween.GhostHunt.Blip.Sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Halloween.GhostHunt.Blip.Scale)
        SetBlipColour(blip, Config.Halloween.GhostHunt.Blip.Color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Halloween.GhostHunt.Blip.Name)
        EndTextCommandSetBlipName(blip)
    end)
end

-- Zona de interação com NPC principal
lib.zones.box({
    coords = vec3(
        Config.Halloween.GhostHunt.NPC.Coords.x, 
        Config.Halloween.GhostHunt.NPC.Coords.y, 
        Config.Halloween.GhostHunt.NPC.Coords.z
    ),
    size = vec3(3, 3, 3),
    rotation = Config.Halloween.GhostHunt.NPC.Coords.w,
    debug = false,
    onEnter = function()
        lib.showTextUI('[E] Misiones de Halloween', {
            position = "left-center",
            icon = 'hand'
        })
    end,
    inside = function()
        if IsControlJustReleased(0, 38) then -- E
            OpenMainMenu()
        end
    end,
    onExit = function()
        lib.hideTextUI()
    end,
})

-- MENU PRINCIPAL COM PROGRESSO E RESGATE
function OpenMainMenu()
    local menuOptions = {
        {
            title = "👻 " .. Config.Halloween.Locals.GhostHunt['MenuTitle'],
            description = Config.Halloween.Locals.GhostHunt['MenuDesc'],
            icon = 'ghost',
            onSelect = function()
                OpenGhostHuntMenu()
            end
        },
        {
            title = "🎃 " .. Config.Halloween.Locals.PumpkinHunt['MenuTitle'],
            description = Config.Halloween.Locals.PumpkinHunt['MenuDesc'],
            icon = 'cookie-bite',
            onSelect = function()
                OpenPumpkinHuntMenu()
            end
        },
        {
            title = "📊 Ver Mi Progreso",
            description = "Ver progreso de ambas misiones",
            icon = 'chart-line',
            onSelect = function()
                ViewMyProgress()
            end
        },
        {
            title = "🏆 Recoger Premio (mx5halloween)",
            description = "Recoge tu vehículo si completaste alguna misión",
            icon = 'car',
            onSelect = function()
                OpenVehicleClaimMenu()
            end
        }
    }
    
    lib.registerContext({
        id = 'halloween_main_menu',
        title = '🎃 Misiones de Halloween',
        options = menuOptions
    })
    
    lib.showContext('halloween_main_menu')
end

-- NOVO: Ver progresso
function ViewMyProgress()
    -- Buscar progresso do servidor
    lib.callback('server:HG-Halloween:getProgress', false, function(ghostProgress)
        lib.callback('server:HG-Halloween:getProgress', false, function(pumpkinProgress)
            
            local options = {
                {
                    title = "👻 Caza de Fantasmas",
                    description = string.format("Progreso: %d/%d\nfantasmas encontrados", 
                        ghostProgress.found, ghostProgress.total),
                    icon = ghostProgress.completed and 'check-circle' or 'ghost',
                    iconColor = ghostProgress.completed and 'green' or 'white',
                    progress = (ghostProgress.found / ghostProgress.total) * 100,
                    colorScheme = ghostProgress.completed and 'green' or 'orange'
                },
                {
                    title = "🎃 Caza de Calabazas",
                    description = string.format("Progreso: %d/%d\nCalabazas encontradas", 
                        pumpkinProgress.found, pumpkinProgress.total),
                    icon = pumpkinProgress.completed and 'check-circle' or 'cookie-bite',
                    iconColor = pumpkinProgress.completed and 'green' or 'white',
                    progress = (pumpkinProgress.found / pumpkinProgress.total) * 100,
                    colorScheme = pumpkinProgress.completed and 'green' or 'orange'
                },
                {
                    title = "⬅️ Volver",
                    icon = 'arrow-left',
                    onSelect = function()
                        OpenMainMenu()
                    end
                }
            }
            
            lib.registerContext({
                id = 'progress_menu',
                title = '📊 Mi Progreso',
                menu = 'halloween_main_menu',
                options = options
            })
            
            lib.showContext('progress_menu')
            
        end, 'pumpkin')
    end, 'ghost')
end

-- Menu de Fantasmas
function OpenGhostHuntMenu()
    lib.registerContext({
        id = 'ghost_hunt_menu',
        title = Config.Halloween.Locals.GhostHunt['MenuTitle'],
        menu = 'halloween_main_menu',
        options = {
            {
                title = Config.Halloween.Locals.GhostHunt['GHMenu1Title'],
                description = Config.Halloween.Locals.GhostHunt['GHMenu1Des'],
                icon = 'play',
                onSelect = function()
                    StartGhostHunt()
                end
            },
            {
                title = "📊 Ver Mi Progreso",
                description = "Ver cuántos fantasmas encontré",
                icon = 'chart-line',
                onSelect = function()
                    lib.callback('server:HG-Halloween:getProgress', false, function(progress)
                        local alert = lib.alertDialog({
                            header = '👻 Progreso de Fantasmas',
                            content = string.format([[
                                **Fantasmas Encontrados:** %d/%d
                                
                                **Estado:** %s
                                
                                %s
                            ]], 
                                progress.found, 
                                progress.total,
                                progress.completed and "✅ COMPLETADO" or "⏳ En progreso",
                                progress.completed and "¡Ve al menú principal y recoge tu premio!" or "Sigue buscando fantasmas de 17:00 a 06:00"
                            ),
                            centered = true,
                            labels = {
                                confirm = "Entendido"
                            }
                        })
                    end, 'ghost')
                end
            },
            {
                title = Config.Halloween.Locals.GhostHunt['GHMenu2Title'],
                description = Config.Halloween.Locals.GhostHunt['GHMenu2Des'],
                icon = 'users',
                onSelect = function()
                    ViewParticipants()
                end
            },
            {
                title = Config.Halloween.Locals.GhostHunt['GHMenu3Title'],
                description = Config.Halloween.Locals.GhostHunt['GHMenu3Des'],
                icon = 'trophy',
                onSelect = function()
                    ViewWinners()
                end
            }
        }
    })
    
    lib.showContext('ghost_hunt_menu')
end

-- Menu de Abóboras
function OpenPumpkinHuntMenu()
    lib.registerContext({
        id = 'pumpkin_hunt_menu',
        title = Config.Halloween.Locals.PumpkinHunt['MenuTitle'],
        menu = 'halloween_main_menu',
        options = {
            {
                title = "Iniciar Caza de Calabazas",
                description = "Busca calabazas por la ciudad",
                icon = 'play',
                onSelect = function()
                    StartPumpkinHunt()
                end
            },
            {
                title = "📊 Ver Mi Progreso",
                description = "Ver cuántas calabazas encontré",
                icon = 'chart-line',
                onSelect = function()
                    lib.callback('server:HG-Halloween:getProgress', false, function(progress)
                        local alert = lib.alertDialog({
                            header = '🎃 Progreso de Calabazas',
                            content = string.format(
    "**Calabazas Encontradas:** %d/%d\n\n**Estado:** %s\n\n%s",
    progress.found,
    progress.total,
    progress.completed and "✅ COMPLETADO" or "⏳ En progreso",
    progress.completed and "¡Ve al menú principal y recoge tu premio!" or "Sigue buscando las flechas naranjas"
),
centered = true,

                            labels = {
                                confirm = "Entendido"
                            }
                        })
                    end, 'pumpkin')
                end
            }
        }
    })
    
    lib.showContext('pumpkin_hunt_menu')
end

-- Menu de resgate de veículo
function OpenVehicleClaimMenu()
    lib.registerContext({
        id = 'vehicle_claim_menu',
        title = '🏆 Recoger Premio',
        menu = 'halloween_main_menu',
        options = {
            {
                title = "🚗 mx5halloween (Fantasmas)",
                description = "Recoge tu vehículo por completar la Caza de Fantasmas",
                icon = 'car',
                onSelect = function()
                    ClaimVehicle('ghost')
                end
            },
            {
                title = "🚗 mx5halloween (Calabazas)",
                description = "Recoge tu vehículo por completar la Caza de Calabazas",
                icon = 'car',
                onSelect = function()
                    ClaimVehicle('pumpkin')
                end
            }
        }
    })
    
    lib.showContext('vehicle_claim_menu')
end

-- Função para resgatar veículo
function ClaimVehicle(missionType)
    lib.callback('server:HG-Halloween:checkVehicleClaim', false, function(canClaim, message)
        if not canClaim then
            Notify("", message, 'error')
            return
        end
        
        local alert = lib.alertDialog({
            header = '🎃 Recoger mx5halloween',
            content = '¿Confirmas que quieres recoger tu vehículo mx5halloween? Solo puedes recibirlo UNA VEZ por esta misión.',
            centered = true,
            cancel = true,
            labels = {
                confirm = "Sí, recoger",
                cancel = "Cancelar"
            }
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('server:HG-Halloween:claimVehicle', missionType)
        end
    end, missionType)
end

-- Iniciar Caza de Fantasmas
function StartGhostHunt()
    lib.callback('server:HG-Halloween:checkCooldown', false, function(canStart, message)
        if not canStart then
            Notify("", message, 'error')
            return
        end
        
        Player(cache.serverId).state:set('hg_ghost_started', true, true)
        TriggerEvent('client:HG-Halloween:StartGhostHunt')
        Notify("", "Misión iniciada! Busca fantasmas de 17:00 a 06:00 y usa /tomarfoto", 'success')
    end, 'ghost')
end

-- Iniciar Caza de Abóboras
function StartPumpkinHunt()
    lib.callback('server:HG-Halloween:checkCooldown', false, function(canStart, message)
        if not canStart then
            Notify("", message, 'error')
            return
        end
        
        Player(cache.serverId).state:set('hg_pumpkin_started', true, true)
        TriggerEvent('client:HG-Halloween:StartPumpkinHunt')
    end, 'pumpkin')
end

-- Ver participantes
function ViewParticipants()
    lib.callback('server:HG-Halloween:ghosthuntinfo', false, function(participants)
        if not participants or #participants == 0 then
            Notify("", "No hay participantes aún", 'info')
            return
        end
        
        local options = {}
        for k, v in pairs(participants) do
            table.insert(options, {
                title = v.name or "Jugador",
                description = "Fantasmas encontrados: " .. (v.found or 0) .. "/" .. #Config.Halloween.GhostHunt.GhostsLocation,
                icon = 'user',
                progress = ((v.found or 0) / #Config.Halloween.GhostHunt.GhostsLocation) * 100
            })
        end
        
        lib.registerContext({
            id = 'participants_list',
            title = 'Participantes',
            menu = 'ghost_hunt_menu',
            options = options
        })
        
        lib.showContext('participants_list')
    end)
end

-- Ver ganadores
function ViewWinners()
    lib.callback('server:HG-Halloween:winners', false, function(winners)
        if not winners or #winners == 0 then
            Notify("", Config.Halloween.Locals.GhostHunt['GHMenu3NoWinner'], 'info')
            return
        end
        
        local options = {}
        for k, v in pairs(winners) do
            table.insert(options, {
                title = "🏆 " .. (v.name or "Jugador"),
                description = "Completado: " .. (v.date or "Fecha desconocida"),
                icon = 'trophy',
                iconColor = 'yellow'
            })
        end
        
        lib.registerContext({
            id = 'winners_list',
            title = 'Ganadores',
            menu = 'ghost_hunt_menu',
            options = options
        })
        
        lib.showContext('winners_list')
    end)
end

print("^2[Halloween VRP]^0 Client principal cargado (con visualización de progreso)")
