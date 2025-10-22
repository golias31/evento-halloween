-- ============================================
-- SISTEMA DE RECOMPENSA DE VEÍCULOS - CORRIGIDO
-- ============================================

-- Criar tabela para controlar veículos resgatados
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `halloween_vehicle_claims` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) NOT NULL,
            `name` varchar(100) DEFAULT NULL,
            `mission_type` varchar(50) NOT NULL,
            `vehicle` varchar(50) NOT NULL,
            `claimed_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_claim` (`identifier`, `mission_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        if success then
            print("^2[Halloween VRP]^0 Tabla 'halloween_vehicle_claims' creada/verificada")
        end
    end)
end)

-- Callback para verificar se pode resgatar veículo
lib.callback.register('server:HG-Halloween:checkVehicleClaim', function(source, missionType)
    local PlayerInfo = GetPlayerInfo(source)
    if not PlayerInfo then
        return false, "Error al obtener información del jugador"
    end
    
    -- Verificar se completou
    local missionCompleted = false
    local foundCount = 0
    local totalNeeded = 0
    
    if missionType == 'ghost' then
        totalNeeded = #Config.Halloween.GhostHunt.GhostsLocation
        
        local result = MySQL.Sync.fetchAll('SELECT found FROM halloween_ghosthunt WHERE identifier = ?', {
            PlayerInfo.identifier
        })
        
        if result and result[1] then
            foundCount = result[1].found or 0
            missionCompleted = foundCount >= totalNeeded
        end
        
        if not missionCompleted then
            return false, string.format("Necesitas completar TODOS los fantasmas! Progreso: %d/%d", foundCount, totalNeeded)
        end
        
    elseif missionType == 'pumpkin' then
        totalNeeded = #Config.Halloween.PumpkinHunt.Location
        
        local result = MySQL.Sync.fetchAll('SELECT pumpkins_opened FROM halloween_pumpkinhunt WHERE identifier = ?', {
            PlayerInfo.identifier
        })
        
        if result and result[1] then
            foundCount = result[1].pumpkins_opened or 0
            missionCompleted = foundCount >= totalNeeded
        end
        
        if not missionCompleted then
            return false, string.format("Necesitas completar TODAS las calabazas! Progreso: %d/%d", foundCount, totalNeeded)
        end
    end
    
    -- Verificar se já resgatou
    local alreadyClaimed = MySQL.Sync.fetchAll([[
        SELECT id FROM halloween_vehicle_claims 
        WHERE identifier = ? AND mission_type = ?
    ]], {PlayerInfo.identifier, missionType})
    
    if alreadyClaimed and #alreadyClaimed > 0 then
        return false, "Ya recogiste tu premio! No puedes recibir el vehículo de nuevo."
    end
    
    return true, "Puede recoger el vehículo"
end)

-- Callback para obter progresso (para o menu)
lib.callback.register('server:HG-Halloween:getProgress', function(source, missionType)
    local PlayerInfo = GetPlayerInfo(source)
    if not PlayerInfo then
        return {found = 0, total = 0, completed = false}
    end
    
    if missionType == 'ghost' then
        local total = #Config.Halloween.GhostHunt.GhostsLocation
        local result = MySQL.Sync.fetchAll('SELECT found FROM halloween_ghosthunt WHERE identifier = ?', {
            PlayerInfo.identifier
        })
        
        local found = result and result[1] and result[1].found or 0
        
        return {
            found = found,
            total = total,
            completed = found >= total
        }
        
    elseif missionType == 'pumpkin' then
        local total = #Config.Halloween.PumpkinHunt.Location
        local result = MySQL.Sync.fetchAll('SELECT pumpkins_opened FROM halloween_pumpkinhunt WHERE identifier = ?', {
            PlayerInfo.identifier
        })
        
        local found = result and result[1] and result[1].pumpkins_opened or 0
        
        return {
            found = found,
            total = total,
            completed = found >= total
        }
    end
    
    return {found = 0, total = 0, completed = false}
end)

-- Evento para resgatar veículo
RegisterNetEvent('server:HG-Halloween:claimVehicle', function(missionType)
    local src = source
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then 
        Notify(src, "Halloween", "Error al obtener información", 'error')
        return 
    end
    
    -- Verificar se pode (com todas as validações)
    local canClaim = false
    local message = ""
    
    -- Verificar completude
    local missionCompleted = false
    local foundCount = 0
    local totalNeeded = 0
    
    if missionType == 'ghost' then
        totalNeeded = #Config.Halloween.GhostHunt.GhostsLocation
        local result = MySQL.Sync.fetchAll('SELECT found FROM halloween_ghosthunt WHERE identifier = ?', {
            PlayerInfo.identifier
        })
        
        if result and result[1] then
            foundCount = result[1].found or 0
            missionCompleted = foundCount >= totalNeeded
        end
    elseif missionType == 'pumpkin' then
        totalNeeded = #Config.Halloween.PumpkinHunt.Location
        local result = MySQL.Sync.fetchAll('SELECT pumpkins_opened FROM halloween_pumpkinhunt WHERE identifier = ?', {
            PlayerInfo.identifier
        })
        
        if result and result[1] then
            foundCount = result[1].pumpkins_opened or 0
            missionCompleted = foundCount >= totalNeeded
        end
    end
    
    if not missionCompleted then
        Notify(src, "Halloween", string.format("Necesitas completar toda la misión! Progreso: %d/%d", foundCount, totalNeeded), 'error')
        return
    end
    
    -- Verificar se já resgatou
    local alreadyClaimed = MySQL.Sync.fetchAll([[
        SELECT id FROM halloween_vehicle_claims 
        WHERE identifier = ? AND mission_type = ?
    ]], {PlayerInfo.identifier, missionType})
    
    if alreadyClaimed and #alreadyClaimed > 0 then
        Notify(src, "Halloween", "Ya recogiste este premio!", 'error')
        return
    end
    
    -- TUDO OK - Dar veículo
    local vehicle = missionType == 'ghost' and 
        Config.Halloween.GhostHunt.CompletionReward.Vehicle or
        Config.Halloween.PumpkinHunt.CompletionReward.Vehicle
    
    -- Adicionar veículo
    local success = AddVehicleToPlayer(src, vehicle)
    
    if success then
        -- Registrar no banco
        MySQL.Async.insert([[
            INSERT INTO halloween_vehicle_claims (identifier, name, mission_type, vehicle) 
            VALUES (?, ?, ?, ?)
        ]], {PlayerInfo.identifier, PlayerInfo.name, missionType, vehicle}, function(insertId)
            if insertId then
                Notify(src, "🎃 Halloween", "¡Recogiste tu " .. vehicle .. "! Revisa tu garaje", 'success')
                
                -- Anúncio global
                TriggerClientEvent('chat:addMessage', -1, {
                    color = {255, 215, 0},
                    multiline = true,
                    args = {"🏆 PREMIO", PlayerInfo.name .. " recogió " .. vehicle .. "!"}
                })
                
                print(string.format("^2[Halloween]^0 %s recogió %s por completar %s", PlayerInfo.name, vehicle, missionType))
            else
                print("^1[Halloween]^0 Error al registrar vehículo en BD")
            end
        end)
    else
        Notify(src, "Halloween", "Error al entregar vehículo. Contacta un admin.", 'error')
        print("^1[Halloween]^0 Error al dar vehículo a " .. PlayerInfo.name)
    end
end)

-- Adicionar veículo (adaptar ao framework)
function AddVehicleToPlayer(src, vehicle)
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then return false end
    
    if Framework == "vrp" or Framework == "vrpex" then
        if vRP then
            local user_id = PlayerInfo.id
            
            -- Tentar método 1: vRP.giveVehicle
            local success, result = pcall(function()
                if vRP.giveVehicle then
                    vRP.giveVehicle({user_id = user_id, vehicle = vehicle})
                    return true
                elseif vRP.giveDlrVehicle then
                    vRP.giveDlrVehicle({user_id = user_id, vehicle = vehicle})
                    return true
                end
                return false
            end)
            
            if success and result then
                return true
            end
            
            -- Fallback: Inserir direto no banco
            MySQL.Async.execute([[
                INSERT INTO vrp_user_vehicles (user_id, vehicle) 
                VALUES (?, ?)
            ]], {user_id, vehicle}, function(affectedRows)
                if affectedRows > 0 then
                    print("^2[Halloween]^0 Vehículo insertado directo en BD para user_id: " .. user_id)
                end
            end)
            
            return true
        end
    elseif Framework == "esx" then
        MySQL.Async.execute([[
            INSERT INTO owned_vehicles (owner, plate, vehicle) 
            VALUES (?, ?, ?)
        ]], {PlayerInfo.identifier, GeneratePlate(), json.encode({model = GetHashKey(vehicle), plate = GeneratePlate()})})
        return true
    elseif Framework == "qb" then
        MySQL.Async.execute([[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {PlayerInfo.identifier, PlayerInfo.id, vehicle, GetHashKey(vehicle), '{}', GeneratePlate(), 'pillboxgarage'})
        return true
    end
    
    return false
end

-- Gerar placa aleatória
function GeneratePlate()
    local plate = ""
    for i = 1, 8 do
        if math.random(2) == 1 then
            plate = plate .. string.char(math.random(65, 90)) -- Letra
        else
            plate = plate .. math.random(0, 9) -- Número
        end
    end
    return plate
end

-- Comando admin para dar carro manualmente
RegisterCommand("darcarrohalloween", function(source, args)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        local targetId = tonumber(args[1])
        local vehicle = args[2] or "mx5halloween"
        
        if not targetId then
            if src == 0 then
                print("Uso: darcarrohalloween [ID] [veiculo]")
            else
                Notify(src, "Halloween", "Uso: /darcarrohalloween [ID] [veiculo]", 'error')
            end
            return
        end
        
        local success = AddVehicleToPlayer(targetId, vehicle)
        
        if success then
            Notify(src, "Halloween", "Vehículo " .. vehicle .. " entregado a ID " .. targetId, 'success')
            Notify(targetId, "Halloween", "Admin te dio " .. vehicle, 'success')
        else
            Notify(src, "Halloween", "Error al entregar vehículo", 'error')
        end
    end
end, false)

print("^2[Halloween VRP]^0 Sistema de recompensa de vehículos CORREGIDO")
