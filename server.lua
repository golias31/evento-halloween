-- Verificação de segurança
if not Config or not Config.Halloween then
    print("^1[Halloween VRP]^0 ERRO CRÍTICO: Config.Halloween não encontrado!")
    print("^1[Halloween VRP]^0 Verifica se config.lua está em shared_scripts no fxmanifest.lua")
    return
end

-- Configuração padrão de notificações se não existir
if not Config.Halloween.Notifications then
    print("^3[Halloween VRP]^0 AVISO: Notifications não encontrado, usando configuração padrão")
    Config.Halloween.Notifications = {
        Type = 'chat',
        GlobalAnnouncement = false,
        SilentItemGive = true,
        Messages = {
            GhostReward = "🎃 ¡Encontraste un fantasma! Recibiste recompensas de Halloween",
            PumpkinReward = "🎃 ¡Calabaza premiada! Obtuviste golosinas de Halloween",
            CompletedGhosts = "👻 ¡FELICIDADES! Completaste la Caza de Fantasmas",
            CompletedPumpkins = "🎃 ¡INCREÍBLE! Completaste la Caza de Calabazas",
        }
    }
end

AddEventHandler("onResourceStart", function(resourceName)
    if (GetCurrentResourceName() ~= "halloween-vrp") then
        print("^8ERROR:^0 Renombra este recurso a ^2'halloween-vrp'^0 para que funcione correctamente.")
        return
    end
    print("^2========================================")
    print("^2[Halloween VRP]^0 Recurso iniciado correctamente")
    print("^2[Halloween VRP]^0 Framework: ^3" .. (Framework or "NINGUNO") .. "^0")
    print("^2[Halloween VRP]^0 Sistema de Inventario: ^3" .. Config.Halloween.Inventory .. "^0")
    print("^2[Halloween VRP]^0 Sistema de Notificaciones: ^3" .. Config.Halloween.Notifications.Type .. "^0")
    print("^2========================================^0")
end)

-- Función para enviar notificación personalizada de Halloween
local function SendHalloweenNotification(src, notifType, missionType)
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then return end
    
    local notifConfig = Config.Halloween.Notifications or {}
    local notifType = notifConfig.Type or 'chat'
    
    if notifType == 'none' then
        return -- No enviar notificaciones
    end
    
    if notifType == 'custom' then
        -- Notificación personalizada de Halloween
        local message = ""
        local messages = notifConfig.Messages or {}
        
        if notifType == 'reward' then
            if missionType == 'GhostHunt' then
                message = messages.GhostReward or "🎃 ¡Encontraste un fantasma!"
            elseif missionType == 'PumpkinHunt' then
                message = messages.PumpkinReward or "🎃 ¡Calabaza premiada!"
            end
        elseif notifType == 'completed' then
            if missionType == 'GhostHunt' then
                message = messages.CompletedGhosts or "👻 ¡Completaste la Caza de Fantasmas!"
            elseif missionType == 'PumpkinHunt' then
                message = messages.CompletedPumpkins or "🎃 ¡Completaste la Caza de Calabazas!"
            end
        end
        
        -- Enviar al jugador
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 140, 0},
            multiline = true,
            args = {"🎃 HALLOWEEN", message}
        })
        
        -- Anuncio global si está habilitado y es completado
        if notifConfig.GlobalAnnouncement and notifType == 'completed' then
            TriggerClientEvent('chat:addMessage', -1, {
                color = {255, 140, 0},
                multiline = true,
                args = {"🎃 EVENTO HALLOWEEN", PlayerInfo.name .. " completó " .. (missionType == 'GhostHunt' and "la Caza de Fantasmas" or "la Caza de Calabazas") .. "!"}
            })
        end
    elseif notifType == 'notify' then
        -- Usar sistema de notificación normal
        local msg = missionType == 'GhostHunt' and "Recompensa de Fantasma" or "Recompensa de Calabaza"
        Notify(src, "🎃 Halloween", msg, 'success')
    else
        -- chat por defecto
        TriggerClientEvent('chat:addMessage', src, {
            args = {"🎃 Halloween", "Recibiste recompensas de Halloween"}
        })
    end
end

-- Función para dar items silenciosamente (sin notificación de inventario)
local function GiveRewardsSilently(src, Type)
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then return false end
    
    local rewards = Config.Halloween[Type].Rewards
    
    -- Dar dinero si está configurado
    if rewards.Money and rewards.Money > 0 then
        ToggleMoney(src, 'add', 'cash', rewards.Money)
    end
    
    -- Dar items si están configurados
    if rewards.Items and next(rewards.Items) ~= nil then
        -- Verificar si el sistema debe ser silencioso
        local silentGive = Config.Halloween.Notifications.SilentItemGive
        if silentGive == nil then silentGive = true end
        
        if silentGive then
            -- Dar items sin notificación del inventario
            for item, amount in pairs(rewards.Items) do
                AddInvItem(src, item, amount)
            end
        else
            -- Dar items con notificación normal del inventario
            for item, amount in pairs(rewards.Items) do
                AddInvItem(src, item, amount)
            end
        end
    end
    
    return true
end

RegisterNetEvent('server:HG-Halloween:RewardPlayer', function(Type)
    local src = source
    
    -- Verificación anti-cheat
    if not Player(src).state["hghalloween_rewardplayer"] then
        print("^1[Halloween VRP]^0 Jugador " .. src .. " intentó obtener recompensa sin completar tarea")
        return
    end
    Player(src).state:set("hghalloween_rewardplayer", false, true)
    
    -- Verificar se as recompensas estão habilitadas
    if not Config.Halloween[Type] or not Config.Halloween[Type].Rewards.Enable then
        return
    end
    
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then
        print("^1[Halloween VRP]^0 No se pudo obtener información del jugador " .. src)
        return
    end
    
    -- Dar recompensas
    local success = GiveRewardsSilently(src, Type)
    
    if success then
        -- Enviar notificación personalizada de Halloween
        SendHalloweenNotification(src, 'reward', Type)
        
        print("^2[Halloween VRP]^0 " .. PlayerInfo.name .. " recibió recompensas de " .. Type)
    end
end)

-- Evento para notificar cuando completa la misión
RegisterNetEvent('server:HG-Halloween:MissionCompleted', function(missionType)
    local src = source
    local PlayerInfo = GetPlayerInfo(src)
    
    if not PlayerInfo then return end
    
    -- Enviar notificación de misión completada
    SendHalloweenNotification(src, 'completed', missionType)
    
    print("^2[Halloween VRP]^0 " .. PlayerInfo.name .. " completó " .. missionType)
end)

-- Comando para verificar estado del script
RegisterCommand("halloween_info", function(source, args, rawCommand)
    local src = source
    
    if src == 0 then
        print("^2========================================")
        print("^2[Halloween VRP]^0 Información del Script")
        print("^2[Halloween VRP]^0 Framework: ^3" .. (Framework or "NINGUNO") .. "^0")
        print("^2[Halloween VRP]^0 Notificaciones: ^3" .. (Config.Halloween.Notifications and Config.Halloween.Notifications.Type or "CHAT") .. "^0")
        print("^2[Halloween VRP]^0 Silencioso: ^3" .. (Config.Halloween.Notifications and Config.Halloween.Notifications.SilentItemGive and "SI" or "NO") .. "^0")
        print("^2[Halloween VRP]^0 Caza de Fantasmas: ^3" .. (Config.Halloween.GhostHunt.Enable and "ACTIVADO" or "DESACTIVADO") .. "^0")
        print("^2[Halloween VRP]^0 Caza de Calabazas: ^3" .. (Config.Halloween.PumpkinHunt.Enable and "ACTIVADO" or "DESACTIVADO") .. "^0")
        print("^2========================================^0")
    else
        if IsAdmin(src) then
            Notify(src, "Halloween VRP", "Framework: " .. (Framework or "NINGUNO"), 'info')
            Notify(src, "Halloween VRP", "Notificaciones: " .. (Config.Halloween.Notifications and Config.Halloween.Notifications.Type or "CHAT"), 'info')
            Notify(src, "Halloween VRP", "Caza de Fantasmas: " .. (Config.Halloween.GhostHunt.Enable and "ACTIVADO" or "DESACTIVADO"), 'info')
            Notify(src, "Halloween VRP", "Caza de Calabazas: " .. (Config.Halloween.PumpkinHunt.Enable and "ACTIVADO" or "DESACTIVADO"), 'info')
        else
            Notify(src, "Halloween VRP", "No tienes permisos para usar este comando", 'error')
        end
    end
end, false)

-- Comando para cambiar tipo de notificación (admin)
RegisterCommand("halloween_notif", function(source, args, rawCommand)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        local newType = args[1]
        
        if not newType or (newType ~= 'custom' and newType ~= 'notify' and newType ~= 'chat' and newType ~= 'none') then
            if src == 0 then
                print("^3Uso: halloween_notif [custom/notify/chat/none]^0")
            else
                Notify(src, "Halloween VRP", "Uso: /halloween_notif [custom/notify/chat/none]", 'error')
            end
            return
        end
        
        if not Config.Halloween.Notifications then
            Config.Halloween.Notifications = {}
        end
        
        Config.Halloween.Notifications.Type = newType
        
        if src == 0 then
            print("^2[Halloween VRP]^0 Tipo de notificación cambiado a: ^3" .. newType .. "^0")
        else
            Notify(src, "Halloween VRP", "Tipo de notificación cambiado a: " .. newType, 'success')
        end
    else
        Notify(src, "Halloween VRP", "No tienes permisos para usar este comando", 'error')
    end
end, false)