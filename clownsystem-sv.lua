-- ============================================
-- SERVIDOR DO SISTEMA DO PALHAÇO - MELHORADO
-- COOLDOWN 4 HORAS + BLOQUEIO SE BOSS VIVO
-- ============================================

local ClownCooldowns = {}
local ActiveEvent = {
    IsActive = false,
    BossAlive = false,
    StartedBy = nil
}

-- Callback para verificar cooldown E se evento está ativo
lib.callback.register('server:halloween:checkClownCooldown', function(source)
    local PlayerInfo = GetPlayerInfo(source)
    if not PlayerInfo then
        return false, "Error al obtener información del jugador"
    end
    
    -- VERIFICAR SE JÁ TEM EVENTO ATIVO
    if ActiveEvent.IsActive and ActiveEvent.BossAlive then
        return false, "Ya hay un evento activo! Espera a que terminen de matar al boss"
    end
    
    -- Verificar cooldown individual
    if ClownCooldowns[PlayerInfo.identifier] then
        local currentTime = os.time()
        local cooldownEnd = ClownCooldowns[PlayerInfo.identifier]
        local remaining = cooldownEnd - currentTime
        
        if remaining > 0 then
            local hours = math.floor(remaining / 3600)
            local minutes = math.ceil((remaining % 3600) / 60)
            
            local message
            if hours > 0 then
                message = string.format("Ya jugaste conmigo recientemente. Vuelve en %d horas y %d minutos", hours, minutes)
            else
                message = string.format("Ya jugaste conmigo recientemente. Vuelve en %d minutos", minutes)
            end
            
            return false, message
        else
            ClownCooldowns[PlayerInfo.identifier] = nil
        end
    end
    
    return true, "Puede iniciar"
end)

-- Evento para iniciar evento do palhaço
RegisterNetEvent('server:halloween:startClownEvent', function()
    local src = source
    local PlayerInfo = GetPlayerInfo(src)
    
    if not PlayerInfo then return end
    
    -- Verificar se já tem evento ativo
    if ActiveEvent.IsActive and ActiveEvent.BossAlive then
        Notify(src, "", "Ya hay un evento activo! Espera a que terminen", 'error')
        return
    end
    
    -- Verificar se tem o item
    local hasItem = HasInvItem(src, "chocolate", 1)
    
    if not hasItem then
        Notify(src, "", "¡No tienes el dulce que quiero!", 'error')
        return
    end
    
    -- Remover item
    RemoveInvItem(src, "chocolate", 1)
    
    -- Estabelecer cooldown (4 HORAS = 240 minutos)
    local cooldownSeconds = 240 * 60  -- 4 horas em segundos
    ClownCooldowns[PlayerInfo.identifier] = os.time() + cooldownSeconds
    
    -- Marcar evento como ativo
    ActiveEvent.IsActive = true
    ActiveEvent.BossAlive = true
    ActiveEvent.StartedBy = PlayerInfo.name
    
    -- Iniciar evento no cliente
    TriggerClientEvent('client:halloween:startClownEvent', src)
    
    -- Anúncio global
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 140, 0},
        multiline = true,
        args = {"🎪 EVENTO", PlayerInfo.name .. " iniciou o Evento do Payaso no Cemitério!"}
    })
    
    print(string.format("^2[Halloween]^0 %s iniciou evento do Payaso (cooldown: 4 horas)", PlayerInfo.name))
end)

-- Evento quando o boss é morto
RegisterNetEvent('server:halloween:clownBossKilled', function()
    local src = source
    local PlayerInfo = GetPlayerInfo(src)
    
    if not PlayerInfo then return end
    
    -- Marcar boss como morto
    ActiveEvent.BossAlive = false
    
    -- Limpar evento após 30 segundos
    SetTimeout(30000, function()
        ActiveEvent.IsActive = false
        ActiveEvent.BossAlive = false
        ActiveEvent.StartedBy = nil
    end)
    
    -- Dar recompensas
    local rewards = {
        ['dinheirosujer'] = {amount = 25000, chance = 100},
        ['c4'] = {amount = 3, chance = 50},
        ['antibiotico'] = {amount = 2, chance = 75},
    }
    
    -- Dar cada item com base na chance
    for item, data in pairs(rewards) do
        local roll = math.random(100)
        if roll <= data.chance then
            AddInvItem(src, item, data.amount)
            
            TriggerClientEvent('chat:addMessage', src, {
                color = {255, 215, 0},
                multiline = false,
                args = {"🎪 Payaso", string.format("Recibiste: %s x%d", item, data.amount)}
            })
            
            Wait(100)
        end
    end
    
    -- Dar dinheiro
    ToggleMoney(src, 'add', 'cash', 5000)
    
    TriggerClientEvent('chat:addMessage', src, {
        color = {255, 215, 0},
        multiline = false,
        args = {"🎪 Payaso", "Recibiste: $5000"}
    })
    
    -- Anúncio global
    TriggerClientEvent('chat:addMessage', -1, {
        color = {0, 255, 0},
        multiline = true,
        args = {"🎪 EVENTO", PlayerInfo.name .. " derrotó al Boss Payaso del Cemitério!"}
    })
    
    print(string.format("^2[Halloween]^0 %s derrotó al Boss Payaso", PlayerInfo.name))
end)

-- Função para verificar se tem item no inventário
function HasInvItem(src, item, amount)
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then return false end
    
    if Framework == "vrp" or Framework == "vrpex" then
        if vRP and vRP.getInventoryItemAmount then
            local user_id = PlayerInfo.id
            local hasAmount = vRP.getInventoryItemAmount(user_id, item)
            return hasAmount >= amount
        end
        return true
    elseif Framework == "esx" then
        local Player = ESX.GetPlayerFromId(src)
        local item = Player.getInventoryItem(item)
        return item and item.count >= amount
    elseif Framework == "qb" then
        local Player = QBCore.Functions.GetPlayer(src)
        local item = Player.Functions.GetItemByName(item)
        return item and item.amount >= amount
    end
    
    return false
end

-- Comando admin para resetar evento (se bugar)
RegisterCommand("resetar_evento_payaso", function(source, args)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        ActiveEvent.IsActive = false
        ActiveEvent.BossAlive = false
        ActiveEvent.StartedBy = nil
        
        -- Limpar todos os cooldowns
        ClownCooldowns = {}
        
        if src == 0 then
            print("^2[Halloween]^0 Evento do Payaso resetado")
        else
            Notify(src, "Halloween", "Evento do Payaso resetado completamente", 'success')
        end
        
        -- Anúncio
        TriggerClientEvent('chat:addMessage', -1, {
            color = {255, 0, 0},
            multiline = true,
            args = {"🎪 SISTEMA", "El evento del Payaso fue resetado por un administrador"}
        })
    else
        Notify(src, "Halloween", "No tienes permiso", 'error')
    end
end, false)

-- Comando para ver status do evento
RegisterCommand("status_payaso", function(source, args)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        local status = ActiveEvent.IsActive and "ATIVO" or "INATIVO"
        local bossStatus = ActiveEvent.BossAlive and "VIVO" or "MORTO"
        
        if src == 0 then
            print("^2========================================")
            print("^2[Halloween]^0 Status do Evento do Payaso")
            print("  Evento: " .. status)
            print("  Boss: " .. bossStatus)
            print("  Iniciado por: " .. (ActiveEvent.StartedBy or "Ninguém"))
            print("  Cooldowns ativos: " .. #ClownCooldowns)
            print("^2========================================^0")
        else
            Notify(src, "🎪 Status Payaso", "Evento: " .. status, 'info')
            Notify(src, "🎪 Status Payaso", "Boss: " .. bossStatus, 'info')
        end
    end
end, false)

-- Comando admin para remover cooldown de jogador
RegisterCommand("remover_cooldown_payaso", function(source, args)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        local targetId = tonumber(args[1])
        
        if not targetId then
            if src == 0 then
                print("Uso: remover_cooldown_payaso [ID]")
            else
                Notify(src, "Halloween", "Uso: /remover_cooldown_payaso [ID]", 'error')
            end
            return
        end
        
        local TargetInfo = GetPlayerInfo(targetId)
        if not TargetInfo then
            Notify(src, "Halloween", "Jugador no encontrado", 'error')
            return
        end
        
        ClownCooldowns[TargetInfo.identifier] = nil
        
        if src == 0 then
            print("^2[Halloween]^0 Cooldown removido para " .. TargetInfo.name)
        else
            Notify(src, "Halloween", "Cooldown removido para " .. TargetInfo.name, 'success')
        end
        
        Notify(targetId, "Halloween", "Tu cooldown del Payaso fue removido por un admin", 'success')
    end
end, false)

print("^2[Halloween VRP]^0 Servidor do Payaso MELHORADO (4h cooldown + bloqueio por boss vivo)")
