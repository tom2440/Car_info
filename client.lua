-- Import de la configuration
local ESX = exports["es_extended"]:getSharedObject()
local playerVehicles = {}
local lastChecked = {}
local nearbyVehicles = {}
local isNearVehicles = false
local isInSpectateMode = false -- Nouvelle variable pour détecter le mode spectateur

-- Fonction pour dessiner le texte 3D optimisée
local function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    
    local dist = #(GetGameplayCamCoords() - vector3(x, y, z))
    local scale = (1 / dist) * 5
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    SetTextScale(0.0 * scale, 0.15 * scale)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- Fonction pour vérifier si le joueur est en mode spectateur
local function CheckSpectateMode()
    return NetworkIsInSpectatorMode()
end

local function IsVehicleLocked(vehicle)
    return GetVehicleDoorLockStatus(vehicle) == 2
end

local function GetVehicleModelName(vehicle)
    local model = GetEntityModel(vehicle)
    return GetDisplayNameFromVehicleModel(model)
end

local function IsVehicleBlacklisted(vehicle)
    local modelName = GetVehicleModelName(vehicle):lower()
    for _, blacklistedModel in ipairs(Config.BlacklistedVehicles) do
        if string.find(modelName, blacklistedModel:lower()) then
            return true
        end
    end
    return false
end

local function IsPlayerVehicle(plate)
    return playerVehicles[plate] and playerVehicles[plate].isPlayerVehicle
end

local function IsNPCVehicle(plate)
    return not playerVehicles[plate] or playerVehicles[plate].owner == "Inconnu"
end

-- Fonction pour vérifier si nous devons rafraîchir les informations
local function ShouldRefreshInfo(plate)
    if not lastChecked[plate] then
        return true
    end
    return (GetGameTimer() - lastChecked[plate]) > Config.RefreshTime
end

RegisterNetEvent('car_info:setVehicleInfo')
AddEventHandler('car_info:setVehicleInfo', function(plate, ownerName, isPlayerVehicle)
    playerVehicles[plate] = {
        owner = ownerName,
        isPlayerVehicle = isPlayerVehicle
    }
    lastChecked[plate] = GetGameTimer()
end)

-- Événement pour synchroniser la configuration entre serveur et clients
RegisterNetEvent('car_info:syncConfig')
AddEventHandler('car_info:syncConfig', function(newConfig)
    Config = newConfig
end)

-- Thread de recherche de véhicules optimisé
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Vérification toutes les secondes
        
        -- Vérifier si le joueur est en mode spectateur
        isInSpectateMode = CheckSpectateMode()
        
        if not Config.Enabled or isInSpectateMode then
            isNearVehicles = false
            nearbyVehicles = {}
            Citizen.Wait(5000)
            goto continue
        end
        
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            isNearVehicles = false
            nearbyVehicles = {}
            Citizen.Wait(1000)
            goto continue
        end
        
        local coords = GetEntityCoords(playerPed)
        local vehicles = GetGamePool('CVehicle')
        local tempNearby = {}
        local found = false
        
        for _, vehicle in ipairs(vehicles) do
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(coords - vehCoords)
            
            if distance <= Config.MaxDistance and not IsVehicleBlacklisted(vehicle) then
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate then
                    tempNearby[vehicle] = {
                        plate = plate,
                        coords = vehCoords,
                        distance = distance
                    }
                    found = true
                    
                    if ShouldRefreshInfo(plate) then
                        TriggerServerEvent('car_info:getVehicleInfo', plate)
                        if not playerVehicles[plate] then
                            playerVehicles[plate] = { owner = "Recherche...", isPlayerVehicle = false }
                        end
                    end
                end
            end
        end
        
        nearbyVehicles = tempNearby
        isNearVehicles = found
        
        if not found then
            Citizen.Wait(1000)
        end
        
        ::continue::
    end
end)

-- Thread d'affichage séparé
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Ne pas afficher les informations si le joueur est en mode spectateur
        if not Config.Enabled or isInSpectateMode or not isNearVehicles then
            Citizen.Wait(500)
            goto continue
        end
        
        for vehicle, data in pairs(nearbyVehicles) do
            local plate = data.plate
            
            -- Détermine si on doit afficher le véhicule
            local shouldDisplay = false
            
            if Config.ShowAllVehicles and IsPlayerVehicle(plate) then
                shouldDisplay = true
            elseif Config.ShowNPCVehicles and IsNPCVehicle(plate) then
                shouldDisplay = true
            elseif playerVehicles[plate] and playerVehicles[plate].isPlayerVehicle then
                shouldDisplay = true
            end
            
            if shouldDisplay then
                local vehCoords = data.coords
                local text = ""
                
                -- Préparation du texte à afficher (uniquement si nécessaire)
                if Config.ShowInfo.Plate then
                    text = text .. "Plaque: " .. plate .. "\n"
                end
                
                if Config.ShowInfo.Model then
                    text = text .. "Modèle: " .. GetVehicleModelName(vehicle) .. "\n"
                end
                
                if Config.ShowInfo.Owner then
                    if IsNPCVehicle(plate) and Config.ShowNPCVehicles then
                        text = text .. "Propriétaire: Inconnu\n"
                    else
                        text = text .. "Propriétaire: " .. (playerVehicles[plate] and playerVehicles[plate].owner or "Recherche...") .. "\n"
                    end
                end
                
                if Config.ShowInfo.LockStatus then
                    text = text .. (IsVehicleLocked(vehicle) and "🔒" or "🔓") .. "\n"
                end
                
                if Config.ShowInfo.EngineHealth then
                    text = text .. "Santé moteur: " .. math.floor(GetVehicleEngineHealth(vehicle)) .. " points"
                end
                
                Draw3DText(vehCoords.x, vehCoords.y, vehCoords.z + 1.5, text)
            end
        end
        
        ::continue::
    end
end)

-- Thread de nettoyage des données anciennes
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- Nettoie toutes les 5 minutes
        
        local currentTime = GetGameTimer()
        for plate, lastTime in pairs(lastChecked) do
            if (currentTime - lastTime) > 600000 then -- 10 minutes
                lastChecked[plate] = nil
                playerVehicles[plate] = nil
            end
        end
    end
end)