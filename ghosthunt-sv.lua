-- ============================================
-- SISTEMA DE CAÇA DE FANTASMAS - SERVIDOR CORRIGIDO
-- ============================================

-- Sistema de cooldown por jugador
local PlayerCooldowns = {}

-- Função para verificar cooldown
local function GetRemainingCooldown(identifier, missionType)
    if not PlayerCooldowns[identifier] then
        PlayerCooldowns[identifier] = {}
    end
    
    if not PlayerCooldowns[identifier][missionType] then
        return 0
    end
    
    local currentTime = os.time()
    local cooldownEnd = PlayerCooldowns[identifier][missionType]
    local remaining = cooldownEnd - currentTime
    
    if remaining <= 0 then
        PlayerCooldowns[identifier][missionType] = nil
        return 0
    end
    
    return math.ceil(remaining / 60)
end

-- Função para estabelecer cooldown
local function SetCooldown(identifier, missionType)
    if not PlayerCooldowns[identifier] then
        PlayerCooldowns[identifier] = {}
    end
    
    local cooldownSeconds = Config.Halloween.GlobalCooldown * 60
    PlayerCooldowns[identifier][missionType] = os.time() + cooldownSeconds
end

-- Callback para verificar si puede iniciar la misión
lib.callback.register('server:HG-Halloween:checkCooldown', function(source, missionType)
    local PlayerInfo = GetPlayerInfo(source)
    if not PlayerInfo then
        return false, "Error al obtener información del jugador"
    end
    
    local remainingTime = GetRemainingCooldown(PlayerInfo.identifier, missionType)
    
    if remainingTime > 0 then
        local message = string.format(Config.Halloween.Locals.GhostHunt['NotifyCooldown'], remainingTime)
        if missionType == 'pumpkin' then
            message = string.format(Config.Halloween.Locals.PumpkinHunt['NotifyCooldown'], remainingTime)
        end
        return false, message
    end
    
    return true, "Puede iniciar la misión"
end)

-- Callback para obtener información de participantes
lib.callback.register('server:HG-Halloween:ghosthuntinfo', function(source)
    local Result = MySQL.Sync.fetchAll('SELECT name, found, date FROM halloween_ghosthunt ORDER BY found DESC, date ASC', {})
    return Result or {}
end)

-- Callback para obtener ganadores
lib.callback.register('server:HG-Halloween:winners', function(source)
    local totalGhosts = #Config.Halloween.GhostHunt.GhostsLocation
    local Result = MySQL.Sync.fetchAll([[
        SELECT name, DATE_FORMAT(date, '%d/%m/%Y %H:%i') as date 
        FROM halloween_ghosthunt 
        WHERE found = ? AND date IS NOT NULL 
        ORDER BY date ASC
    ]], {totalGhosts})
    return Result or {}
end)

-- Função auxiliar para buscar em tabla
local function FindInTable(tbl, value)
    if not tbl then return false end
    for k, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Evento cuando un jugador encuentra un fantasma
RegisterNetEvent('server:HG-Halloween:foundghost', function(ghostLocationNum)
    local src = source
    local PlayerInfo = GetPlayerInfo(src)
    
    if not PlayerInfo then
        print("^1[Halloween VRP]^0 Error: No se pudo obtener información del jugador " .. src)
        return
    end
    
    if not ghostLocationNum or ghostLocationNum < 1 or ghostLocationNum > #Config.Halloween.GhostHunt.GhostsLocation then
        print("^1[Halloween VRP]^0 Número de fantasma inválido: " .. tostring(ghostLocationNum))
        return
    end
    
    -- CORRIGIDO: Usar MySQL.Sync.fetchAll ao invés de MySQL.single.await
    local result = MySQL.Sync.fetchAll('SELECT found, foundGhosts, date FROM halloween_ghosthunt WHERE identifier = ?', {
        PlayerInfo.identifier
    })
    
    local foundGhosts = {}
    local currentFound = 0
    
    if result and result[1] then
        foundGhosts = json.decode(result[1].foundGhosts) or {}
        currentFound = result[1].found or 0
    else
        -- Criar registro inicial
        MySQL.Sync.execute('INSERT INTO halloween_ghosthunt (identifier, name, foundGhosts, found) VALUES (?, ?, ?, ?)', {
            PlayerInfo.identifier,
            PlayerInfo.name,
            json.encode({}),
            0
        })
    end
    
    -- Verificar se já encontrou este fantasma
    if FindInTable(foundGhosts, ghostLocationNum) then
        Notify(src, "", Config.Halloween.Locals.GhostHunt['NotifyAlreadyFound'], 'error')
        return
    end
    
    -- Adicionar fantasma encontrado
    table.insert(foundGhosts, ghostLocationNum)
    local newFoundCount = currentFound + 1
    
    -- Verificar se completou TODOS
    if newFoundCount >= #Config.Halloween.GhostHunt.GhostsLocation then
        local completionDate = os.date('%Y-%m-%d %H:%M:%S')
        
        MySQL.Sync.execute('UPDATE halloween_ghosthunt SET found = ?, foundGhosts = ?, date = ? WHERE identifier = ?', {
            newFoundCount,
            json.encode(foundGhosts),
            completionDate,
            PlayerInfo.identifier
        })
        
        -- Notificar completude
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 215, 0},
            multiline = true,
            args = {"🎃 HALLOWEEN", "¡FELICIDADES! Completaste la Caza de Fantasmas (" .. newFoundCount .. "/" .. #Config.Halloween.GhostHunt.GhostsLocation .. ")"}
        })
        
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 215, 0},
            multiline = true,
            args = {"🎃 HALLOWEEN", "Ve al NPC y elige 'Recoger Premio' para recibir tu mx5halloween!"}
        })
        
        -- Anúncio global
        TriggerClientEvent('chat:addMessage', -1, {
            color = {255, 140, 0},
            multiline = true,
            args = {"👻 CAZA DE FANTASMAS", PlayerInfo.name .. " completó la Caza de Fantasmas!"}
        })
        
        SetCooldown(PlayerInfo.identifier, 'ghost')
        Player(src).state:set('hg_ghost_started', false, true)
        
        print("^2[Halloween VRP]^0 " .. PlayerInfo.name .. " completó la Caza de Fantasmas")
    else
        -- Atualizar progresso
        MySQL.Sync.execute('UPDATE halloween_ghosthunt SET found = ?, foundGhosts = ? WHERE identifier = ?', {
            newFoundCount,
            json.encode(foundGhosts),
            PlayerInfo.identifier
        })
        
        -- Notificar progresso
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 140, 0},
            multiline = false,
            args = {"👻 Fantasma", string.format("Progreso: %d/%d fantasmas encontrados", newFoundCount, #Config.Halloween.GhostHunt.GhostsLocation)}
        })
    end
end)

-- Evento cuando un jugador abre una calabaza
RegisterNetEvent('server:HG-Halloween:openedPumpkin', function()
    local src = source
    local PlayerInfo = GetPlayerInfo(src)
    
    if not PlayerInfo then return end
    
    local result = MySQL.Sync.fetchAll('SELECT pumpkins_opened FROM halloween_pumpkinhunt WHERE identifier = ?', {
        PlayerInfo.identifier
    })
    
    local pumpkinsOpened = 0
    if result and result[1] then
        pumpkinsOpened = result[1].pumpkins_opened or 0
    end
    
    pumpkinsOpened = pumpkinsOpened + 1
    
    if result and result[1] then
        MySQL.Sync.execute('UPDATE halloween_pumpkinhunt SET pumpkins_opened = ? WHERE identifier = ?', {
            pumpkinsOpened,
            PlayerInfo.identifier
        })
    else
        MySQL.Sync.execute('INSERT INTO halloween_pumpkinhunt (identifier, name, pumpkins_opened) VALUES (?, ?, ?)', {
            PlayerInfo.identifier,
            PlayerInfo.name,
            pumpkinsOpened
        })
    end
    
    -- Verificar se completou
    if pumpkinsOpened >= #Config.Halloween.PumpkinHunt.Location then
        -- Completou! Atualizar com data de completude
        MySQL.Sync.execute('UPDATE halloween_pumpkinhunt SET last_completion = NOW() WHERE identifier = ?', {
            PlayerInfo.identifier
        })
        
        -- Completou!
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 215, 0},
            multiline = true,
            args = {"🎃 HALLOWEEN", "¡INCREÍBLE! Completaste la Caza de Calabazas (" .. pumpkinsOpened .. "/" .. #Config.Halloween.PumpkinHunt.Location .. ")"}
        })
        
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 215, 0},
            multiline = true,
            args = {"🎃 HALLOWEEN", "Ve al NPC y elige 'Recoger Premio' para recibir tu mx5halloween!"}
        })
        
        -- Anúncio global
        TriggerClientEvent('chat:addMessage', -1, {
            color = {255, 140, 0},
            multiline = true,
            args = {"🎃 CAZA DE CALABAZAS", PlayerInfo.name .. " completó la Caza de Calabazas!"}
        })
        
        SetCooldown(PlayerInfo.identifier, 'pumpkin')
        Player(src).state:set('hg_pumpkin_started', false, true)
        
        print("^2[Halloween VRP]^0 " .. PlayerInfo.name .. " completó la Caza de Calabazas")
    else
        -- Notificar progresso
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 140, 0},
            multiline = false,
            args = {"🎃 Calabaza", string.format("Progreso: %d/%d calabazas encontradas", pumpkinsOpened, #Config.Halloween.PumpkinHunt.Location)}
        })
    end
end)

-- ============================================
-- COMANDOS CORRIGIDOS
-- ============================================

-- Comando para ver progreso de fantasmas
RegisterCommand("progresso_fantasmas", function(source, args, rawCommand)
    local src = source
    local PlayerInfo = GetPlayerInfo(src)
    
    if not PlayerInfo then return end
    
    local result = MySQL.Sync.fetchAll('SELECT found FROM halloween_ghosthunt WHERE identifier = ?', {
        PlayerInfo.identifier
    })
    
    local found = 0
    if result and result[1] then
        found = result[1].found or 0
    end
    
    local total = #Config.Halloween.GhostHunt.GhostsLocation
    
    local remainingTime = GetRemainingCooldown(PlayerInfo.identifier, 'ghost')
    local cooldownMsg = remainingTime > 0 and (" | Cooldown: " .. remainingTime .. " min") or ""
    
    TriggerClientEvent('chat:addMessage', src, {
        color = {255, 140, 0},
        multiline = true,
        args = {"👻 Caça de Fantasmas", "Progresso: " .. found .. "/" .. total .. " fantasmas" .. cooldownMsg}
    })
end, false)

-- Alias
RegisterCommand("pf", function(source, args, rawCommand)
    ExecuteCommand("progresso_fantasmas")
end, false)

-- Comando para ver progreso de calabazas
RegisterCommand("progresso_calabazas", function(source, args, rawCommand)
    local src = source
    local PlayerInfo = GetPlayerInfo(src)
    
    if not PlayerInfo then return end
    
    local result = MySQL.Sync.fetchAll('SELECT pumpkins_opened FROM halloween_pumpkinhunt WHERE identifier = ?', {
        PlayerInfo.identifier
    })
    
    local opened = 0
    if result and result[1] then
        opened = result[1].pumpkins_opened or 0
    end
    
    local total = #Config.Halloween.PumpkinHunt.Location
    
    local remainingTime = GetRemainingCooldown(PlayerInfo.identifier, 'pumpkin')
    local cooldownMsg = remainingTime > 0 and (" | Cooldown: " .. remainingTime .. " min") or ""
    
    TriggerClientEvent('chat:addMessage', src, {
        color = {255, 140, 0},
        multiline = true,
        args = {"🎃 Caça de Calabazas", "Progresso: " .. opened .. "/" .. total .. " calabazas" .. cooldownMsg}
    })
end, false)

-- Alias
RegisterCommand("pc", function(source, args, rawCommand)
    ExecuteCommand("progresso_calabazas")
end, false)

-- Comando geral
RegisterCommand("progresso_halloween", function(source, args, rawCommand)
    ExecuteCommand("progresso_fantasmas")
    Wait(100)
    ExecuteCommand("progresso_calabazas")
end, false)

RegisterCommand("prog", function(source, args, rawCommand)
    ExecuteCommand("progresso_halloween")
end, false)

-- Comando admin para resetear cooldown
RegisterCommand("resetar_cooldown", function(source, args, rawCommand)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        local target = tonumber(args[1])
        local missionType = args[2]
        
        if not target then
            if src == 0 then
                print("^3Uso: resetar_cooldown [ID] [ghost/pumpkin]^0")
            else
                Notify(src, "Halloween VRP", "Uso: /resetar_cooldown [ID] [ghost/pumpkin]", 'error')
            end
            return
        end
        
        local TargetInfo = GetPlayerInfo(target)
        if not TargetInfo then
            Notify(src, "Halloween VRP", "Jugador no encontrado", 'error')
            return
        end
        
        if missionType and (missionType == 'ghost' or missionType == 'pumpkin') then
            if PlayerCooldowns[TargetInfo.identifier] then
                PlayerCooldowns[TargetInfo.identifier][missionType] = nil
            end
            
            if src == 0 then
                print("^2[Halloween VRP]^0 Cooldown de " .. missionType .. " resetado para " .. TargetInfo.name)
            else
                Notify(src, "Halloween VRP", "Cooldown de " .. missionType .. " resetado para " .. TargetInfo.name, 'success')
            end
        else
            PlayerCooldowns[TargetInfo.identifier] = {}
            
            if src == 0 then
                print("^2[Halloween VRP]^0 Todos os cooldowns resetados para " .. TargetInfo.name)
            else
                Notify(src, "Halloween VRP", "Todos os cooldowns resetados para " .. TargetInfo.name, 'success')
            end
        end
        
        if target ~= src then
            TriggerClientEvent('chat:addMessage', target, {
                color = {255, 140, 0},
                multiline = true,
                args = {"🎃 HALLOWEEN", "Tus cooldowns fueron resetados por un administrador"}
            })
        end
    else
        Notify(src, "Halloween VRP", "No tienes permiso para usar este comando", 'error')
    end
end, false)

print("^2[Halloween VRP]^0 Sistema de Caza de Fantasmas CORRIGIDO (SQL + Comandos)")
