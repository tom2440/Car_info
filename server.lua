-- server.lua
local ESX = exports["es_extended"]:getSharedObject()
local ownerCache = {}
local cacheDuration = 15 * 60000 -- 15 minutes en ms

-- Fonction pour récupérer les données du cache
local function getFromCache(plate)
    if ownerCache[plate] and (GetGameTimer() - ownerCache[plate].timestamp) < cacheDuration then
        return ownerCache[plate].data
    end
    return nil
end

-- Fonction pour stocker les données dans le cache
local function storeInCache(plate, data)
    ownerCache[plate] = {
        data = data,
        timestamp = GetGameTimer()
    }
end

-- Nettoyage périodique du cache
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- Nettoyage toutes les 5 minutes
        local currentTime = GetGameTimer()
        
        for plate, cacheData in pairs(ownerCache) do
            if (currentTime - cacheData.timestamp) > cacheDuration then
                ownerCache[plate] = nil
            end
        end
    end
end)

RegisterNetEvent('car_info:getVehicleInfo')
AddEventHandler('car_info:getVehicleInfo', function(plate)
    local _source = source
    
    -- Vérification du cache
    local cachedData = getFromCache(plate)
    if cachedData then
        TriggerClientEvent('car_info:setVehicleInfo', _source, plate, cachedData.ownerName, cachedData.isPlayerVehicle)
        return
    end
    
    -- Requête optimisée avec jointure
    exports.oxmysql:query('SELECT ov.owner, ov.job, u.firstname, u.lastname FROM owned_vehicles ov LEFT JOIN users u ON ov.owner = u.identifier WHERE ov.plate = ? LIMIT 1', 
    {plate}, function(result)
        local ownerName = "Inconnu"
        local isPlayerVehicle = false
        
        if result and result[1] and result[1].job == nil then
            if result[1].firstname and result[1].lastname then
                ownerName = result[1].firstname .. " " .. result[1].lastname
                isPlayerVehicle = true
            end
        end
        
        -- Stockage du résultat dans le cache
        storeInCache(plate, {
            ownerName = ownerName,
            isPlayerVehicle = isPlayerVehicle
        })
        
        TriggerClientEvent('car_info:setVehicleInfo', _source, plate, ownerName, isPlayerVehicle)
    end)
end)

-- Commande pour les administrateurs pour activer/désactiver l'affichage des véhicules PNJ
ESX.RegisterCommand('pnjcarinfo', 'admin', function(xPlayer, args, showError)
    -- Inverser la valeur actuelle
    Config.ShowNPCVehicles = not Config.ShowNPCVehicles
    
    -- Informer l'administrateur du changement
    local status = Config.ShowNPCVehicles and "activé" or "désactivé"
    TriggerClientEvent('esx:showNotification', xPlayer.source, "Affichage des véhicules PNJ " .. status)
    
    -- Synchroniser la configuration avec tous les clients
    TriggerClientEvent('car_info:syncConfig', -1, Config)
end, false, {help = 'Active/désactive l\'affichage des informations des véhicules PNJ'})