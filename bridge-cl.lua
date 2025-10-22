local NotifyType = Config.Halloween.Notify

--------------------------------[Sistema de Notificaciones]--------------------------------
function Notify(header, des, ntype)
    local msg = header ~= "" and (header .. ": " .. des) or des
    
    if NotifyType == 'vrp' then
        TriggerEvent('chat:addMessage', {
            color = {255, 140, 0},
            multiline = true,
            args = {"[Halloween]", msg}
        })
        
    elseif NotifyType == 'ox' then
        lib.notify({
            title = header,
            description = des,
            type = ntype or 'info'
        })
        
    elseif NotifyType == 'gta' then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(msg)
        DrawNotification(false, true)
        
    else
        TriggerEvent('chat:addMessage', {
            args = {"[Halloween]", msg}
        })
    end
end

-- Exportar
exports('Notify', Notify)

print("^2[Halloween VRP]^0 Bridge cliente cargado")
