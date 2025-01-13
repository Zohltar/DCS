MESSAGE:New("KolaCore Loaded"):ToAll()
env.info("KolaCore Loaded")

kola = {} -- pour gérer tout les variable ou fonctions kola. 
kola.isInterceptorAlreadyAirborne = false -- variable pour vérifier la présence des F-14 dans les airs
kola.flagInstance = trigger.misc.getUserFlag("flagInstance") -- pour trapper l'instance de la mission. 0 = prod, 1 = QA, 2 = DEV
env.info("Valeur du flag instance: " .. kola.flagInstance)


-- Informe quelle type d'instance est en cours
if kola.flagInstance == 0 then
    -- Production: Moins de messages affichés
    env.info("Mode Production activé.")
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Mode actuel : Production", 20)
elseif kola.flagInstance == 1 then
    -- QA: Messages intermédiaires pour tests
    env.info("Mode QA activé. Messages supplémentaires affichés pour le débogage.")
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Mode actuel : QA (Quality Assurance)", 20)
    trigger.action.outText("Mode QA actif : validez le bon déroulement de la mission. Fine tuning.", 20)
elseif kola.flagInstance == 2 then
    -- Développement: Plus de détails pour débogage
    env.info("Mode Développement activé.")
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Mode actuel : Développement", 20)
    trigger.action.outText("Mode Dev actif : Développement, test et débogage", 20)
else
    -- Valeur inattendue
    env.warning("Valeur inattendue pour flagInstance : " .. tostring(flagInstance))
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Erreur : flagInstance a une valeur inattendue !", 10)
end

-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************
-- **							 Début section des fonctions                                          **
-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************
  

-- Variables globales pour les groupes à suivre
flagsToCheck = {}

-- Création de l'objet handler pour gérer les événements
kola.eventHandler = {}

-- Tableaux pour stocker les différentes informations d'abonnement
landingToMonitor = {}
unitlandingToMonitor = {}
grpToMonitor = {}

-- Définition de la méthode onEvent pour gérer les événements
function kola.eventHandler:onEvent(event)
    if event == nil then
        env.warning("L'événement est nul")
        return
    end

    -- Vérifie si l'événement est un atterrissage
    if event.id == world.event.S_EVENT_LAND then
        -- Vérifie si l'atterrissage se fait au bon endroit et si c'est l'unité spécifiée
        for i, place in ipairs(landingToMonitor) do
            if event.place and event.place:getName() == place and event.initiator:getName() == unitlandingToMonitor[i] then
                env.info("Le " .. event.initiator:getName() .. " a atterri sur la base " .. place)
                -- Détruire le groupe une fois l'atterrissage effectué
                
				local unitName = unitlandingToMonitor[i] -- Remplacez par le nom de l'unité.
				local unit = Unit.getByName(unitName) -- Obtenez l'objet de l'unité.

				if unit and unit:isExist() then
				local group = unit:getGroup() -- Obtenez le groupe de l'unité.
				if group then
					env.info("Le groupe de l'unité " .. unitName .. " est : " .. group:getName())
					group:destroy()
					return					
				else
					env.warning("L'unité " .. unitName .. " n'a pas de groupe.")
				end
				else
					env.warning("L'unité " .. unitName .. " n'existe pas.")
				end
                -- Retirer les données associées
                --table.remove(unitlandingToMonitor, i) --commented to verify if bugged after a while
                --table.remove(grpToMonitor, i)
            end
        end
    elseif event.id == world.event.S_EVENT_TAKEOFF then
    -- Vérifie si l'initiateur est un F-14B ou F-14A
    if event.initiator:getTypeName() == "F-14B" or event.initiator:getTypeName() == "F-14A" then
		
        -- Validation des paramètres pour AttackGroupTaskPush
        if spawnedBlueInterceptName ~= nil and spawnedRedStrikeGroupName ~= nil then
            -- Appel de la fonction avec des paramètres validés
            AttackGroupTaskPush(spawnedBlueInterceptName, spawnedRedStrikeGroupName, 0) -- demande au F-14 qui décolent d'attaquer les Bombardiers.
            env.info("AttackGroupTaskPush appelé avec les paramètres :")
            env.info("Attaquant : " .. tostring(spawnedBlueInterceptName) .. ", Cible : " .. tostring(spawnedRedStrikeGroupName))
			
        else
            -- Log pour identifier des paramètres invalides
            env.warning("Erreur : spawnedBlueInterceptName ou spawnedRedStrikeGroupName est nil.")
            env.info("spawnedBlueInterceptName : " .. tostring(spawnedBlueInterceptName))
            env.info("spawnedRedStrikeGroupName : " .. tostring(spawnedRedStrikeGroupName))
        end

        -- Gestion de l'état des intercepteurs
        if not kola.isInterceptorAlreadyAirborne then
            env.info("Un F-14 a décollé : " .. event.initiator:getName())
			if kola.flagInstance ~= 0 then
				trigger.action.outText("F-14 détecté dans le ciel !", 10)
			end
            Spawn_RedStrikeEscort:Spawn() -- Démarre l'escorte si un F-14 décolle
            kola.isInterceptorAlreadyAirborne = true
        end
    else
        -- Vérifie si des F-14 sont actifs
        if not detectActiveF14s() then
            if not kola.isInterceptorAlreadyAirborne then -- retirer le "not" si ça bug.
                kola.isInterceptorAlreadyAirborne = false
                env.info("Aucun F-14 actif. Arrêt de l'escorte.")
                Spawn_RedStrikeEscort:SpawnScheduleStop() -- Arrête l'escorte s'il n'y a plus de F-14
            end
        end
    end
	end
end

-- Fonction de gestion des atterrissages des helicos ai pour dispawn
-- Fonction pour vérifier s'il y a des F-14B ou F-14A actifs
function detectActiveF14s()
    local blueUnits = coalition.getPlayers(coalition.side.BLUE) -- Récupère toutes les unités de la coalition bleue
    for _, unit in pairs(blueUnits) do
        if unit:isExist() and unit:getLife() > 0 then -- Vérifie que l'unité existe et est en vie
            local unitType = unit:getTypeName()
            local unitAltitude = unit:getPoint().y -- Récupère l'altitude de l'unité

            -- Vérifie si c'est un F-14 (A ou B) et si l'altitude est significative (au-dessus du sol)
            if (unitType == "F-14B" or unitType == "F-14A") and unitAltitude > 10 then -- Tolérance pour considérer "en vol"
                env.info("F-14 actif détecté : " .. unit:getName())
                return true
            end
        end
    end
    return false -- Aucun F-14 actif trouvé
end

-- Enregistrement du gestionnaire d'événements
world.addEventHandler(kola.eventHandler)


  -- Fonction pour s'abonner à l'événement LAND pour un lieu spécifique
function subscribeToLandEvent(placeToMonitor, unitToMonitor, Groupe)
    
    table.insert(landingToMonitor, placeToMonitor)
    table.insert(unitlandingToMonitor, unitToMonitor)
    table.insert(grpToMonitor, Groupe)
    
    
    -- Enregistre le gestionnaire d'événements
    world.addEventHandler(kola.eventHandler)
end 
 
-- Fonction pour détecter la présence de F-14B ou F-14A bleus dans le ciel


  
 function addFirstUnitNameToTransportTable(groupName)
    -- Vérifiez si le groupe existe
    local group = Group.getByName(groupName)
    if group then
        -- Obtenez la liste des unités du groupe
        local units = group:getUnits()
        if units and #units > 0 then
            -- Récupérez le nom de la première unité
            local firstUnit = units[1]
            if firstUnit and firstUnit:isExist() then
                local unitName = firstUnit:getName()
                
                -- Ajoutez ce nom à la table `ctld.transportPilotNames`
                table.insert(ctld.transportPilotNames, unitName)
                
                -- Log pour confirmation
                env.info("Nom de la première unité ajouté à ctld.transportPilotNames: " .. unitName)
            else
                env.warning("La première unité du groupe n'existe pas.")
            end
        else
            env.warning("Aucune unité trouvée dans le groupe : " .. groupName)
        end
    else
        env.warning("Groupe introuvable : " .. groupName)
    end
end


-- Fonction pour obtenir et afficher le score
function getMissionScore()
    local blueScore = trigger.misc.getUserFlag("BlueScore") -- Lire le drapeau BlueScore
    local redScore = trigger.misc.getUserFlag("RedScore")   -- Lire le drapeau RedScore

    -- Construire le message
    local messageText = "Le score est de : " .. blueScore .. " pour les bleus et de : " .. redScore .. " pour les rouges"
	MESSAGE:New(messageText):ToAll() -- Envoyer le message en jeu
	

    -- Écrire le score dans un fichier
    writeScoreToFile(blueScore, redScore)
end

-- Fonction pour écrire le score dans un fichier
function writeScoreToFile(blueScore, redScore)
    local lfs = lfs -- LFS est déjà disponible dans DCS

    -- Obtenir le chemin du répertoire de la mission
    local missionDir = lfs.writedir() .. "Missions/"

    -- Générer le nom du fichier avec la date et l'heure actuelles
    local date = os.date("%Y-%m-%d-%H-%M") -- Format : aaaa-mm-jj-hh:mm
    local filename = missionDir .. "score_" .. date .. ".txt"

    -- Créer le contenu du fichier
    local content = "Scores de la mission :\n"
    content = content .. "Bleus : " .. blueScore .. "\n"
    content = content .. "Rouges : " .. redScore .. "\n"
    content = content .. "Enregistré à : " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"

    -- Ouvrir le fichier en mode écriture
    local file, err = io.open(filename, "w")
    if file then
        file:write(content) -- Écrire le contenu dans le fichier
        file:close() -- Fermer le fichier
        env.info("Score écrit dans le fichier : " .. filename) -- Log dans le fichier DCS
    else
        env.warning("Erreur lors de l'écriture du fichier : " .. err) -- Log en cas d'erreur
    end
end

function monitorEndgameFlag()
    local flagValue = trigger.misc.getUserFlag("EndgameFlag") -- Obtenir la valeur du flag
    if flagValue == 1 then
        -- Exécuter la fonction de changement du ROE
        env.info("EndgameFlag is ON, executing setAircraftGroupsROEToReturnFire...")
        setAircraftGroupsROEToReturnFire()
        
        -- Réinitialiser le flag pour éviter les répétitions
        trigger.action.setUserFlag("EndgameFlag", 0)
    end

    -- Répéter la vérification toutes les 2 secondes
    timer.scheduleFunction(monitorEndgameFlag, nil, timer.getTime() + 2)
end
monitorEndgameFlag()

-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************
-- **
-- **                            Section de définition des spawns.                                    **
-- **
-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************

  NavalTargetSpawnZoneTable = { 	
				ZONE:New( "NavalTargetSpawnZone" )
			}
  --Naval Tanker Target
  Spawn_RedNavalTankerTarget = genSpawn("NavalTankerSpawn",10,180, NavalTargetSpawnZoneTable)
  Spawn_RedNavalTankerTarget:SpawnScheduleStart()
 
  
--Spawns
kola.tableauSpawnedGroup = {}
  
  --Spawn les petits soldats
  petitsSoldatsZoneTable = { 	
				ZONE:New( "SoldatSpawnZone-1" ), 
				ZONE:New( "SoldatSpawnZone-2" ),
				ZONE:New( "SoldatSpawnZone-3" ),
				ZONE:New( "SoldatSpawnZone-4" ), 
				ZONE:New( "SoldatSpawnZone-5" )
			}

Spawn_Soldats = genSpawn ( "SpawnSoldat", 20, 45, petitsSoldatsZoneTable)
Spawn_RedNavalTankerTarget:SpawnScheduleStart()

--Spawn Bleu Manpad 
Spawn_BlueAirDef_1 = genSpawn("BlueAirDef",2,180)

--Spawn Soldats Def Bleu
BlueDefZoneTable = { ZONE:New( "BlueDefSpawnZone" ) }
Spawn_BlueDef_1 = genSpawn("BlueDefenderInfantry",10,60,BlueDefZoneTable)

--Liberators
Spawn_BlueLiberatrors = genSpawn( "LiberatorsSpawn", 3, 0)
Spawn_BlueLiberatrors:OnSpawnGroup(function(grp)
		spawnedLiberatorGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedLiberatorGroup = grp -- Stocke l'objet du groupe spawné    
		end)
		
-- Détruire les liberators restants, si défini
if spawnedLiberatorGroup and spawnedLiberatorGroup:IsAlive() then
  spawnedLiberatorGroup:Destroy()
end

--Blue F14
Spawn_BlueIntercept = genSpawn("TomcatIntercept", 4, 120)
Spawn_BlueIntercept:SpawnScheduleStop()
Spawn_BlueIntercept:OnSpawnGroup(function(grp)
		spawnedBlueInterceptName = grp:GetName()-- Stocke le nom du groupe spawné
		spawnedBlueInterceptGroup = grp
		subscribeToLandEvent("CVN-75", findFirstUnit(grp), grp )
				env.info("Spawned group name: " .. grp:GetName())
		local flagName = "LifeTime_" .. grp:GetName()
		trigger.action.setUserFlag(flagName, 1)
		subscribeLifeTimeChecker(grp, 5400, flagName)				
		end)

--Spawn BlueAttackChopper
Spawn_BlueAttack = genSpawn("BlueSpawnAttack",2,30)
Spawn_BlueAttack:SpawnScheduleStop()
Spawn_BlueAttack:OnSpawnGroup(function(grp)
		spawnedBlueAttackGroupName = grp:GetName()-- Stocke le nom du groupe spawné
		spawnedBlueAttackGroup = grp
		subscribeToLandEvent("Invincible-1-1", findFirstUnit(grp), grp )
				env.info("Spawned group name: " .. grp:GetName())
		local flagName = "LifeTime_" .. grp:GetName()
		trigger.action.setUserFlag(flagName, 1)
		subscribeLifeTimeChecker(grp, 1100, flagName)
		end)
  
 -- Spawn Red Vehicule Transport
Spawn_RedVehiculeTransport = genSpawn("RedVehiculeTransportSpawn",1,180)
Spawn_RedVehiculeTransport:SpawnScheduleStop()
Spawn_RedVehiculeTransport:OnSpawnGroup(function(grp)
		local firstUnit = findFirstUnit(grp)
		if firstUnit then
			addFirstUnitNameToTransportTable(grp:GetName())
			table.insert(kola.tableauSpawnedGroup, {group = grp, unit = firstUnit})
			ctld.preLoadTransport(firstUnit, {inf = 8, at = 6, aa = 2}, true)
			subscribeToLandEvent("Naval-3-1", firstUnit, grp)

			-- Log dans le dcs.log
			env.info("Spawned group: " .. grp:GetName())

			local flagName = "LifeTime_" .. grp:GetName()
			trigger.action.setUserFlag(flagName, 1)
			subscribeLifeTimeChecker(grp, 1200, flagName)
		else
			env.warning("Aucune unité trouvée dans le groupe: " .. grp:GetName())
		end
	end)
  
  

-- Ravitailleur (Blue Transport)
Spawn_Ravitailleur = genSpawn("BlueRenfortTroopTransport",2,180)
Spawn_Ravitailleur:OnSpawnGroup(function(grp)
      local RavitailleurFirstUnit = findFirstUnit(grp)
      if RavitailleurFirstUnit then
          addFirstUnitNameToTransportTable(grp:GetName())
          subscribeToLandEvent("Invincible-1-1", RavitailleurFirstUnit, grp)

          local flagName = "LifeTime_" .. grp:GetName()
          trigger.action.setUserFlag(flagName, 1)
          subscribeLifeTimeChecker(grp, 1500, flagName) -- Automatise le dispawn au retour à la base
      else
          env.warning("Aucune unité trouvée dans le groupe: " .. grp:GetName())
      end
  end)

  

-- Spawn Red Transport
Spawn_RedTransport = SPAWN:New("RedTransportSpawn")
  :InitLimit(2, 0)
  :OnSpawnGroup(function(grp)
      local firstUnit = findFirstUnit(grp)
      if firstUnit then
          --table.insert(ctld.transportPilotNames, firstUnit)
		  addFirstUnitNameToTransportTable(grp:GetName())
          table.insert(kola.tableauSpawnedGroup, {group = grp, unit = firstUnit})
          ctld.preLoadTransport(firstUnit, 10, true)
          subscribeToLandEvent("Naval-3-1", firstUnit, grp)

          -- Log dans le dcs.log
          env.info("Spawned group name: " .. grp:GetName())

          -- Associe un flag nommé au groupe pour sa gestion
          local flagName = "LifeTime_" .. grp:GetName()
          trigger.action.setUserFlag(flagName, 1)
          subscribeLifeTimeChecker(grp, 1200, flagName)
      else
          env.warning("Aucune unité trouvée dans le groupe: " .. grp:GetName())
      end
  end)
  :SpawnScheduled(180, 0.6)
  :SpawnScheduleStop()
  
  
--Spawn Les Speedboat
ZoneSpeedBoatTable = { ZONE:New( "NavalSpawnZone-1" ) }
Spawn_Rescue_1 = genSpawn( "NavalSpawn-1", 10, 60 , ZoneSpeedBoatTable )

--Red Drop Troops
Spawn_RedTroop = genSpawn( "TroopTransportSpawn", 16, 0 )		
Spawn_RedManpadTroop = genSpawn( "RedManPadSpawn", 2, 0 )

--Red Backup
Spawn_RedBackup = genSpawn( "RedBackupSpawn", 8, 0 )
Spawn_RedBackup:OnSpawnGroup(function(grp)
		spawnedRedBackupGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedRedBackupGroup = grp -- Stocke l'objet du groupe spawné
		subscribeToLandEvent("Naval-3-1", findFirstUnit(grp), grp)
		    -- Message pour les joueurs
		if kola.flagInstance ~= 0 then
			MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
		end
    
		-- Log dans le dcs.log
		env.info("Spawned Backupgroup name: " .. spawnedRedBackupGroupName)
	end)
  
 Spawn_RedHeloBackup = genSpawn( "RedHeloBackup", 1, 0 )
	
Spawn_RedHeloBackup:OnSpawnGroup(function(grp)
		spawnedRedHeloBackupGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedRedHeloBackupGroup = grp -- Stocke l'objet du groupe spawné
		if kola.flagInstance ~= 0 then
			MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
		end
    
		-- Log dans le dcs.log
		env.info("Spawned Backupgroup name: " .. spawnedRedHeloBackupGroupName)
	end) 
 --End of Red Backup
 
 -- Red Strike
 RedStrike_ZoneTable = { 	
				ZONE:New( "RedStrikeSpawnZone-1" ), 
				ZONE:New( "RedStrikeSpawnZone-2" ),
				ZONE:New( "RedStrikeSpawnZone-3" ),
				ZONE:New( "RedStrikeSpawnZone-4" ), 
				ZONE:New( "RedStrikeSpawnZone-5" ),
				ZONE:New( "RedStrikeSpawnZone-6" )
			}
			
Spawn_RedStrike = genSpawn( "RedStrike1", 4 , 180, RedStrike_ZoneTable )
Spawn_RedStrike:OnSpawnGroup(function(grp)
		spawnedRedStrikeGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedRedStrikeGroup = grp -- Stocke l'objet du groupe spawné
		subscribeToLandEvent("Severomorsk-1", findFirstUnit(grp), grp)
		local flagName = "LifeTime_" .. grp:GetName()
          trigger.action.setUserFlag(flagName, 1)
          --subscribeLifeTimeChecker(grp, 5400, flagName)-- 1h30 lifespan max, à voir
		if kola.flagInstance ~= 0 then
			MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
		end
		-- Log dans le dcs.log
		env.info("Spawned Strikegroup name: " .. spawnedRedStrikeGroupName)
		if detectActiveF14s() then AttackGroupTaskPush(spawnedBlueInterceptName, spawnedRedStrikeGroupName, 0) end
	end) 
Spawn_RedStrike:SpawnScheduleStop()
 
 
 -- End of Red Strike
 
 --Red Strike Escort
 RedStrike_ZoneTable = { 	
				ZONE:New( "RedStrikeSpawnZone-1" ), 
				ZONE:New( "RedStrikeSpawnZone-2" ),
				ZONE:New( "RedStrikeSpawnZone-3" ),
				ZONE:New( "RedStrikeSpawnZone-4" ), 
				ZONE:New( "RedStrikeSpawnZone-5" ),
				ZONE:New( "RedStrikeSpawnZone-6" )
			}
			
Spawn_RedStrikeEscort = genSpawn( "RedEscortSpawn", 2, 0, RedStrike_ZoneTable )
Spawn_RedStrikeEscort:OnSpawnGroup(function(grp)
			local spawnedRedEscortSpawnStrikeGroupName = grp:GetName() -- Stocke le nom du groupe spawné
			local spawnedRedEscortSpawnStrikeGroup = grp -- Stocke l'objet du groupe spawné
			if not detectActiveF14s() then
				kola.isInterceptorAlreadyAirborne = false
				if not kola.isInterceptorAlreadyAirborne then
					env.info("Su-27: Aucun F-14 actif. Arrêt de l'escorte.")
					Spawn_RedStrikeEscort:SpawnScheduleStop()	-- Arrête l'escorte s'il n'y a plus de F-14
				end
			else
				MESSAGE:New("Su-27: Враг обнаружен!"):ToAll()
			end
		-- Log dans le dcs.log
			env.info("Spawned Strikegroup name: " .. grp:GetName())
			if detectActiveF14s() then AttackGroupTaskPush(spawnedRedEscortSpawnStrikeGroupName, spawnedBlueInterceptName, 1) end
		end) 
	 
 -- End of Red Strike Escort
 
 -- Red Interceptors Mig-25
Spawn_RedInterceptor = genSpawn( "Foxbat-1", 2, 240 )
Spawn_RedInterceptor:OnSpawnGroup(function(grp)
			local spawnedRedInterceptorGroupName = grp:GetName() -- Stocke le nom du groupe spawné
			local spawnedRedInterceptorGroup = grp -- Stocke l'objet du groupe spawné
			--Log dans le dcs.log
			env.info("Spawned Strikegroup name: " .. grp:GetName())
			if kola.flagInstance ~= 0 then
				MESSAGE:New("Foxbat Spawned"):ToAll()
			end
			subscribeToLandEvent("Olenya", findFirstUnit(grp), grp)
		end) 

	
-- Blue AirPatrol F-16
Spawn_BluePatrol = genSpawn( "IceVenom-1" , 2 , 240)	
Spawn_BluePatrol:OnSpawnGroup(function(grp)
		local spawnedBluePatrolGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		local spawnedBluePatrolGroup = grp -- Stocke l'objet du groupe spawné
	    --Log dans le dcs.log
		env.info("Spawned Strikegroup name: " .. grp:GetName())
		if kola.flagInstance ~= 0 then
			MESSAGE:New("IceVenom Spawned"):ToAll()
		end
		subscribeToLandEvent("Kiruna", findFirstUnit(grp), grp)
	end) 
	
 
   -- Endgame
    Endgame_ZoneTable = { 	
				ZONE:New( "EndgameSpawnZone-1" ), 
				ZONE:New( "EndgameSpawnZone-2" ),
				ZONE:New( "EndgameSpawnZone-3" ),
				ZONE:New( "EndgameSpawnZone-4" ), 
				ZONE:New( "EndgameSpawnZone-5" )
				
			}
Spawn_Endgame = genSpawn( "Poseidon", 4, 180, Endgame_ZoneTable )
Spawn_Endgame:SpawnScheduleStop()
Spawn_Endgame:OnSpawnGroup(function(grp)
		spawnedEndgameGroupName = grp:GetName()
		spawnedEndgameGroup = grp
		if kola.flagInstance ~= 0 then
			MESSAGE:New("Poseidons Spawned"):ToAll()
		end
		subscribeToLandEvent("Murmansk International", findFirstUnit(grp), grp)
		
		-- Log dans le dcs.log
		env.info("Spawned EndGame name: " .. spawnedEndgameGroupName)
		end)
	
  
  
-- *****************************************************************************************************
-- *****************************************************************************************************
-- *****************************************************************************************************
-- **																								  **	
-- **                            FIN Section de définition des spawns.                                **



-- Menu principal
local kolaMenu = missionCommands.addSubMenu("Mission Commands", EODMenu)
	missionCommands.addCommand("Score", kolaMenu, getMissionScore)			
	local alliesMenu = missionCommands.addSubMenu("Allies Commands", kolaMenu)
		-- Sous-menu pour les intercepteurs F-14
		local allyInterceptSubMenu = missionCommands.addSubMenu("F-14 Interceptors", alliesMenu)
			missionCommands.addCommand("Start F-14 Interceptors", allyInterceptSubMenu, function()
				Spawn_BlueIntercept:SpawnScheduleStart()
				end)
			missionCommands.addCommand("Stop F-14 Interceptors", allyInterceptSubMenu, function()
				Spawn_BlueIntercept:SpawnScheduleStop()
				end)

		-- Sous-menu pour le transport de troupes
		local allyTroopTransportSubMenu = missionCommands.addSubMenu("Blue Troop Transport", alliesMenu)
			missionCommands.addCommand("Start Troop Transport", allyTroopTransportSubMenu, function()
				Spawn_Ravitailleur:SpawnScheduleStart()
				end)
				missionCommands.addCommand("Stop Troop Transport", allyTroopTransportSubMenu, function()
				Spawn_Ravitailleur:SpawnScheduleStop()
				end)
		-- Sous-menu pour le Rescue
		local rescueSubMenu = missionCommands.addSubMenu("Rescue Spawn Options", alliesMenu)
			missionCommands.addCommand("Spawn Close Rescue", rescueSubMenu, function()
				trigger.action.setUserFlag("CloseRescueFlag", 1)
			end)
			missionCommands.addCommand("Spawn Far Rescue", rescueSubMenu, function()
				trigger.action.setUserFlag("FarRescueFlag", 1)
			end)				
	-- Sous-menu pour les options de mission
	local missionSubMenu = missionCommands.addSubMenu("Mission Options", kolaMenu)
		-- Sous-menu pour le redémarrage de la mission
		local missionRestartSubMenu = missionCommands.addSubMenu("Mission Reload and Options", missionSubMenu)
		missionCommands.addCommand("Reboot Mission", missionRestartSubMenu, function()
			trigger.action.setUserFlag("EndgameFlag", 66)
		end)
		missionCommands.addCommand("Return Fire All", missionRestartSubMenu,setAircraftGroupsROEToReturnFire)
		-- Sous-menu pour les options de fin de partie
		local endgameSubMenu = missionCommands.addSubMenu("Endgame Options", missionSubMenu)
		missionCommands.addCommand("Spawn Poseidon Flight", endgameSubMenu, function()
			trigger.action.setUserFlag("EndgameSpawnFlag", 5)
		end)
		missionCommands.addCommand("Stop Poseidon Spawning", endgameSubMenu, function()
			trigger.action.setUserFlag("EndgameSpawnFlag", 100)
		end) 
		
--EOF
