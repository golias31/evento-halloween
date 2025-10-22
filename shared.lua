-- Solo detectar framework, SIN cargar interfaces aquí
Framework = nil

-- Detectar framework de forma simple
if GetResourceState("vrp") == "started" or GetResourceState("vRP") == "started" then
    Framework = "vrp"
    print("^2[Halloween VRP]^0 Framework detectado: VRP")
elseif GetResourceState("vrpex") == "started" then
    Framework = "vrpex"
    print("^2[Halloween VRP]^0 Framework detectado: VRPEX")
elseif GetResourceState("es_extended") == "started" then
    Framework = "esx"
    print("^2[Halloween VRP]^0 Framework detectado: ESX")
elseif GetResourceState("qb-core") == "started" then
    Framework = "qb"
    print("^2[Halloween VRP]^0 Framework detectado: QBCore")
else
    print("^1[Halloween VRP]^0 No se detectó framework compatible")
end

-- Função para obter URL de imagens
function GetImageUrl(fileName)
    local path = ('images/%s.png'):format(fileName)
    local data = LoadResourceFile(GetCurrentResourceName(), path)
    if data then
        return 'nui://' .. GetCurrentResourceName() .. '/images/' .. fileName .. '.png'
    end
    return ''
end
