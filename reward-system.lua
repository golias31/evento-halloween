-- ============================================
-- SISTEMA DE RECOMPENSAS ALEATÓRIAS
-- COM NOTIFICAÇÕES INDIVIDUAIS
-- ============================================

-- Função para selecionar item aleatório baseado em chance
local function SelectRandomItem(itemsTable)
    local totalChance = 0
    
    for item, data in pairs(itemsTable) do
        totalChance = totalChance + (data.chance or 0)
    end
    
    local roll = math.random(1, totalChance)
    local currentChance = 0
    
    for item, data in pairs(itemsTable) do
        currentChance = currentChance + (data.chance or 0)
        if roll <= currentChance then
            return item, data.amount or 1
        end
    end
    
    local firstItem = next(itemsTable)
    return firstItem, itemsTable[firstItem].amount or 1
end

-- Função para enviar notificação de item individual
local function NotifyItemReceived(src, itemName, amount, money)
    local PlayerInfo = GetPlayerInfo(src)
    if not PlayerInfo then return end
    
    -- Construir mensagem
    local messages = {}
    
    if itemName and amount then
        table.insert(messages, string.format("📦 Item: %s x%d", itemName, amount))
    end
    
    if money and money > 0 then
        table.insert(messages, string.format("💰 Dinero: $%d", money))
    end
    
    -- Enviar cada notificação separadamente
    for _, msg in ipairs(messages) do
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 215, 0},
            multiline = false,
            args = {"🎃 Recompensa", msg}
        })
        Wait(100) -- Pequeno delay entre notificações
    end
    
    -- Som especial para items raros
    if itemName then
        local rewards = Config.Halloween.GhostHunt.Rewards.Items
        if not rewards then rewards = Config.Halloween.PumpkinHunt.Rewards.Items end
        
        if rewards[itemName] and rewards[itemName].chance and rewards[itemName].chance <= 5 then
            -- Anúncio global para item raro
            TriggerClientEvent('chat:addMessage', -1, {
                color = {255, 215, 0},
                multiline = true,
                args = {"⭐ ITEM RARO!", PlayerInfo.name .. " obtuvo " .. itemName .. "!"}
            })
        end
    end
end

-- Evento para dar recompensa com items aleatórios
RegisterNetEvent('server:HG-Halloween:RewardPlayer', function(Type)
    local src = source
    
    -- Verificação anti-cheat
    if not Player(src).state["hghalloween_rewardplayer"] then
        print("^1[Halloween VRP]^0 Jogador " .. src .. " tentou obter recompensa sem completar tarefa")
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
    
    local rewards = Config.Halloween[Type].Rewards
    
    local selectedItem = nil
    local amount = 0
    local money = rewards.Money or 0
    
    -- Dar item aleatório baseado em chance
    if rewards.Items and next(rewards.Items) ~= nil then
        selectedItem, amount = SelectRandomItem(rewards.Items)
        
        if selectedItem then
            AddInvItem(src, selectedItem, amount)
            print(string.format("^2[Halloween VRP]^0 %s recebeu: %s x%d", 
                PlayerInfo.name, selectedItem, amount))
        end
    end
    
    -- Dar dinero se está configurado
    if money > 0 then
        ToggleMoney(src, 'add', 'cash', money)
    end
    
    -- ENVIAR NOTIFICAÇÃO INDIVIDUAL DO ITEM
    NotifyItemReceived(src, selectedItem, amount, money)
end)

-- Exportar função para uso externo
exports('SelectRandomItem', SelectRandomItem)
exports('NotifyItemReceived', NotifyItemReceived)

print("^2[Halloween VRP]^0 Sistema de recompensas com notificações individuais carregado")
