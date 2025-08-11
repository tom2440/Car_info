Config = {
    Enabled = true,             -- Active ou désactive tout le script
    
    ShowAllVehicles = true,     -- Affiche les véh de tous les joueurs (ou juste owned veh)
    ShowNPCVehicles = false,     -- Affiche les véhicules des PNJ
    RefreshTime = 10000,        -- Temps en ms entre chaque rafraîchissement des données
    MaxDistance = 3.2,          -- Distance maximale pour afficher les informations des véhicules
    
    -- Informations à afficher
    ShowInfo = {
        Plate = false,           -- Affiche la plaque
        Model = true,           -- Affiche le modèle
        Owner = true,           -- Affiche le propriétaire
        LockStatus = true,      -- Affiche si le véhicule est verrouillé
        EngineHealth = false     -- Affiche la santé du moteur
    },
    
    BlacklistedVehicles = {     -- Véhicules qui ne seront pas affichés
        --"iak wheelch",
    }
}