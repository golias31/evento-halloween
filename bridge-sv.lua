local NotifyType = Config.Halloween.Notify
local vRP = nil

-- Cargar VRP usando exports (sin module)
if Framework == "vrp" or Framework == "vrpex" then
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        
        -- Intentar cargar vRP por exports
        local success = pcall(function()
            vRP = exports.vrp:getSharedObject()
        end)
        
        if success and vRP then
            print("^2[Halloween VRP]^0 VRP cargado via exports")
        else
            print("^1[Halloween VRP]^0 VRP no disponible via exports")
            print("^3[Halloween VRP]^0 Usando modo compatible...")
        end
    end)
end

--------------------------------[Obtener Información del Jugador]--------------------------------
function GetPlayerInfo(source)
    if Framework == "vrp" or Framework == "vrpex" then
        -- Método 1: Intentar con vRP exports
        if vRP and vRP.getUserId then
            local user_id = vRP.getUserId(source)
            if user_id then
                local identity = vRP.getUserIdentity and vRP.getUserIdentity(user_id) or {}
                return {
                    id = user_id,
                    name = (identity.name and identity.firstname) and (identity.name .. " " .. identity.firstname) or "Jugador",
                    identifier = "user_id:"..user_id
                }
            end
        end
        
        -- Método 2: Fallback - usar identificadores directos
        local identifiers = GetPlayerIdentifiers(source)
        for _, v in pairs(identifiers) do
            if string.find(v, 'license:') then
                return {
                    id = source,
                    name = GetPlayerName(source),
                    identifier = v
                }
            end
        end
        
    elseif Framework == "esx" then
        local Player = ESX.GetPlayerFromId(source)
        if Player then
            return {
                id = Player.identifier,
                name = Player.getName(),
                identifier = Player.identifier
            }
        end
        
    elseif Framework == "qb" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return {
                id = Player.PlayerData.citizenid,
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                identifier = Player.PlayerData.citizenid
            }
        end
    end
    
    -- Fallback final
    return {
        id = source,
        name = GetPlayerName(source),
        identifier = "player:"..source
    }
end

--------------------------------[Sistema de Dinero]--------------------------------
function ToggleMoney(source, Toggle, Type, Amount)
    local PlayerInfo = GetPlayerInfo(source)
    if not PlayerInfo then return false end
    
    if Framework == "vrp" or Framework == "vrpex" then
        if vRP then
            local user_id = PlayerInfo.id
            
            if Toggle == 'has' then
                if vRP.getMoney then
                    return vRP.getMoney(user_id)
                end
            elseif Toggle == 'add' then
                if vRP.giveMoney then
                    vRP.giveMoney(user_id, Amount)
                    return true
                end
            elseif Toggle == 'remove' then
                if vRP.tryPayment then
                    return vRP.tryPayment(user_id, Amount)
                end
            end
        end
        print("^3[Halloween VRP]^0 Operación de dinero: " .. Toggle .. " - $" .. Amount)
        return true
        
    elseif Framework == "esx" then
        local Player = ESX.GetPlayerFromId(source)
        Type = 'money'
        
        if Toggle == 'has' then
            return Player.getMoney()
        elseif Toggle == 'add' then
            Player.addAccountMoney(Type, Amount)
            return true
        elseif Toggle == 'remove' then
            Player.removeMoney(Amount)
            return true
        end
        
    elseif Framework == "qb" then
        local Player = QBCore.Functions.GetPlayer(source)
        
        if Toggle == 'has' then
            return Player.Functions.GetMoney(Type)
        elseif Toggle == 'add' then
            Player.Functions.AddMoney(Type, Amount)
            return true
        elseif Toggle == 'remove' then
            Player.Functions.RemoveMoney(Type, Amount)
            return true
        end
    end
    
    return false
end

--------------------------------[Sistema de Notificaciones]--------------------------------
function Notify(src, header, des, ntype)
    local msg = header ~= "" and (header .. ": " .. des) or des
    
    if NotifyType == 'vrp' then
        -- Fallback simple para VRP
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 140, 0},
            multiline = true,
            args = {"[Halloween]", msg}
        })
        
    elseif NotifyType == 'ox' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = header,
            description = des,
            type = (ntype or 'info')
        })
    else
        TriggerClientEvent('chat:addMessage', src, {
            args = {"[Halloween]", msg}
        })
    end
end

--------------------------------[Sistema de Inventario]--------------------------------
function AddInvItem(src, item, amount, info)
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then 
        print("^1[Halloween VRP]^0 No se pudo obtener PlayerInfo")
        return false 
    end
    
    if Framework == "vrp" or Framework == "vrpex" then
        if vRP and vRP.giveInventoryItem then
            local user_id = PlayerInfo.id
            local success = pcall(function()
                vRP.giveInventoryItem(user_id, item, amount, true)
            end)
            
            if success then
                print("^2[Halloween VRP]^0 Item dado: " .. item .. " x" .. amount .. " a user_id " .. user_id)
                return true
            end
        end
        
        print("^3[Halloween VRP]^0 Intentando dar item: " .. item .. " x" .. amount)
        return true
        
    elseif Framework == "esx" then
        local Player = ESX.GetPlayerFromId(src)
        Player.addInventoryItem(item, amount)
        return true
        
    elseif Framework == "qb" then
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddItem(item, amount, false, info)
        return true
    end
    
    return false
end

function RemoveInvItem(src, item, amount)
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then return false end
    
    if Framework == "vrp" or Framework == "vrpex" then
        if vRP and vRP.tryGetInventoryItem then
            local user_id = PlayerInfo.id
            return vRP.tryGetInventoryItem(user_id, item, amount, true)
        end
        return true
    end
    
    return false
end

--------------------------------[Sistema de Permisos Admin]--------------------------------
function IsAdmin(source)
    -- Por ahora retornar true para testing
    -- Cambia esto según tu sistema de permisos
    return true
end

print("^2[Halloween VRP]^0 Bridge servidor cargado (modo compatible)")