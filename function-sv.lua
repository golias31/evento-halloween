-- Crear tablas de base de datos al iniciar
CreateThread(function()
    -- Tabla de Caza de Fantasmas
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `halloween_ghosthunt` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) NOT NULL,
            `name` varchar(100) DEFAULT NULL,
            `found` int DEFAULT 0,
            `foundGhosts` json DEFAULT '[]',
            `date` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`),
            KEY `idx_found` (`found`),
            KEY `idx_date` (`date`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        if success then
            print("^2[Halloween VRP]^0 Tabla 'halloween_ghosthunt' creada/verificada correctamente")
        else
            print("^1[Halloween VRP]^0 Error al crear tabla 'halloween_ghosthunt'")
        end
    end)
    
    -- Tabla de Caza de Calabazas
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `halloween_pumpkinhunt` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) NOT NULL,
            `name` varchar(100) DEFAULT NULL,
            `pumpkins_opened` int DEFAULT 0,
            `last_completion` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`),
            KEY `idx_pumpkins` (`pumpkins_opened`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        if success then
            print("^2[Halloween VRP]^0 Tabla 'halloween_pumpkinhunt' creada/verificada correctamente")
        else
            print("^1[Halloween VRP]^0 Error al crear tabla 'halloween_pumpkinhunt'")
        end
    end)
end)

-- Función para limpiar datos antiguos (opcional)
function CleanOldData(days)
    days = days or 30
    
    -- Limpiar fantasmas
    local queryGhosts = string.format([[
        DELETE FROM halloween_ghosthunt 
        WHERE date IS NOT NULL 
        AND date < DATE_SUB(NOW(), INTERVAL %d DAY)
    ]], days)
    
    MySQL.Async.execute(queryGhosts, {}, function(affectedRows)
        if affectedRows > 0 then
            print(string.format("^2[Halloween VRP]^0 Se eliminaron %d registros antiguos de fantasmas", affectedRows))
        end
    end)
    
    -- Limpiar calabazas
    local queryPumpkins = string.format([[
        DELETE FROM halloween_pumpkinhunt 
        WHERE last_completion IS NOT NULL 
        AND last_completion < DATE_SUB(NOW(), INTERVAL %d DAY)
    ]], days)
    
    MySQL.Async.execute(queryPumpkins, {}, function(affectedRows)
        if affectedRows > 0 then
            print(string.format("^2[Halloween VRP]^0 Se eliminaron %d registros antiguos de calabazas", affectedRows))
        end
    end)
end

-- Comando para limpiar datos (solo admin)
RegisterCommand("halloween_clean", function(source, args, rawCommand)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        local days = tonumber(args[1]) or 30
        CleanOldData(days)
        
        if src ~= 0 then
            Notify(src, "Halloween VRP", "Limpieza de datos iniciada (últimos " .. days .. " días)", 'success')
        end
    else
        Notify(src, "Halloween VRP", "No tienes permisos para usar este comando", 'error')
    end
end, false)

-- Comando para resetear progreso de un jugador (solo admin)
RegisterCommand("halloween_reset", function(source, args, rawCommand)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        local target = tonumber(args[1])
        local missionType = args[2] -- 'ghost' o 'pumpkin' (opcional)
        
        if not target then
            Notify(src, "Halloween VRP", "Uso: /halloween_reset [ID del jugador] [ghost/pumpkin]", 'error')
            return
        end
        
        local TargetInfo = GetPlayerInfo(target)
        if not TargetInfo then
            Notify(src, "Halloween VRP", "Jugador no encontrado", 'error')
            return
        end
        
        if not missionType or missionType == 'ghost' then
            MySQL.Async.execute('DELETE FROM halloween_ghosthunt WHERE identifier = ?', {
                TargetInfo.identifier
            }, function(affectedRows)
                if affectedRows > 0 then
                    Notify(src, "Halloween VRP", "Progreso de fantasmas de " .. TargetInfo.name .. " reseteado", 'success')
                    if target ~= src then
                        Notify(target, "Halloween VRP", "Tu progreso de Caza de Fantasmas ha sido reseteado", 'info')
                    end
                end
            end)
        end
        
        if not missionType or missionType == 'pumpkin' then
            MySQL.Async.execute('DELETE FROM halloween_pumpkinhunt WHERE identifier = ?', {
                TargetInfo.identifier
            }, function(affectedRows)
                if affectedRows > 0 then
                    Notify(src, "Halloween VRP", "Progreso de calabazas de " .. TargetInfo.name .. " reseteado", 'success')
                    if target ~= src then
                        Notify(target, "Halloween VRP", "Tu progreso de Caza de Calabazas ha sido reseteado", 'info')
                    end
                end
            end)
        end
        
        -- Resetear estados del jugador
        Player(target).state:set('hg_ghost_started', false, true)
        Player(target).state:set('hg_pumpkin_started', false, true)
    else
        Notify(src, "Halloween VRP", "No tienes permisos para usar este comando", 'error')
    end
end, false)

-- Comando para ver estadísticas globales (solo admin)
RegisterCommand("halloween_stats", function(source, args, rawCommand)
    local src = source
    
    if src == 0 or IsAdmin(src) then
        -- Estadísticas de fantasmas
        MySQL.Async.fetchAll('SELECT COUNT(*) as total, AVG(found) as promedio FROM halloween_ghosthunt', {}, function(resultGhosts)
            local totalGhosts = resultGhosts[1].total or 0
            local avgGhosts = math.floor(resultGhosts[1].promedio or 0)
            
            -- Estadísticas de calabazas
            MySQL.Async.fetchAll('SELECT COUNT(*) as total, AVG(pumpkins_opened) as promedio FROM halloween_pumpkinhunt', {}, function(resultPumpkins)
                local totalPumpkins = resultPumpkins[1].total or 0
                local avgPumpkins = math.floor(resultPumpkins[1].promedio or 0)
                
                if src == 0 then
                    print("^2========================================")
                    print("^2[Halloween VRP]^0 Estadísticas Globales")
                    print("^3Fantasmas:^0")
                    print("  - Jugadores participantes: " .. totalGhosts)
                    print("  - Promedio encontrados: " .. avgGhosts .. "/" .. #Config.Halloween.GhostHunt.GhostsLocation)
                    print("^3Calabazas:^0")
                    print("  - Jugadores participantes: " .. totalPumpkins)
                    print("  - Promedio abiertas: " .. avgPumpkins .. "/" .. #Config.Halloween.PumpkinHunt.Location)
                    print("^2========================================^0")
                else
                    Notify(src, "🎃 Halloween Stats", "Fantasmas: " .. totalGhosts .. " jugadores (avg: " .. avgGhosts .. ")", 'info')
                    Notify(src, "🎃 Halloween Stats", "Calabazas: " .. totalPumpkins .. " jugadores (avg: " .. avgPumpkins .. ")", 'info')
                end
            end)
        end)
    else
        Notify(src, "Halloween VRP", "No tienes permisos para usar este comando", 'error')
    end
end, false)

-- Exportar función de limpieza
exports('CleanOldData', CleanOldData)