MESSAGE:New("KolaCore Loaded"):ToAll()

kola = {}
kola.isInterceptorAlreadyAirborne = false
kola.dernierStrikeActif = nil

  NavalTargetSpawnZoneTable = { 	
				ZONE:New( "NavalTargetSpawnZone" )
			}
  --Naval Tanker Target
  Spawn_RedNavalTankerTarget = SPAWN:New("NavalTankerSpawn")
  :InitLimit(10, 0)
  :InitRandomizeZones( NavalTargetSpawnZoneTable ) 
  :OnSpawnGroup(function(grp)
    -- Message pour les joueurs
    --MESSAGE:New("Transport Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
    
    -- Log dans le dcs.log
    env.info("Spawned group name: " .. grp:GetName())
  end)
  :SpawnScheduled(180, 0.5)
  
  
--Spawns
kola.tableauSpawnedGroup = {}
  
  --Spawn les petits soldats
  ZoneTable = { 	
				ZONE:New( "SoldatSpawnZone-1" ), 
				ZONE:New( "SoldatSpawnZone-2" ),
				ZONE:New( "SoldatSpawnZone-3" ),
				ZONE:New( "SoldatSpawnZone-4" ), 
				ZONE:New( "SoldatSpawnZone-5" )
			}

Spawn_Rescue_1 = SPAWN:New( "SpawnSoldat" )
  :InitLimit( 20, 0 )
  :InitRandomizeZones( ZoneTable )    
  :OnSpawnGroup( function(grp)
    --MESSAGE:New("Soldat Spawn: "..string.sub(grp:GetName(),1,-5),15,"SPAWN"):ToAll()
  end)
:SpawnScheduled( 45, .5 )



--Spawn Bleu Manpad 
Spawn_BlueAirDef_1 = SPAWN:New( "BlueAirDef" )
	:InitLimit( 2, 0 )
	:SpawnScheduled( 180, .5 )


--Spawn Soldats Def Bleu
BlueDefZoneTable = { ZONE:New( "BlueDefSpawnZone" ) }

Spawn_BlueDef_1 = SPAWN:New( "BlueDefenderInfantry" )
	:InitLimit( 10, 0 )
	:InitRandomizeZones( BlueDefZoneTable )   
	:SpawnScheduled( 60, .2 )
	--S'il reste des liberators ils seront despawn.
	
-- Détruire les liberators restants, si défini
if spawnedLiberatorGroup and spawnedLiberatorGroup:IsAlive() then
  spawnedLiberatorGroup:Destroy()
end




--Liberators
Spawn_BlueLiberatrors = SPAWN:New( "LiberatorsSpawn" )
	:InitLimit( 3, 0 )
	:OnSpawnGroup(function(grp)
		spawnedLiberatorGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedLiberatorGroup = grp -- Stocke l'objet du groupe spawné
    
    env.info("Spawned group name: " .. spawnedLiberatorGroupName)
  end)


--Blue F14
Spawn_BlueIntercept = SPAWN:New("TomcatIntercept")
	:InitLimit(4, 0)
	:OnSpawnGroup(function(grp)
		spawnedBlueInterceptName = grp:GetName()-- Stocke le nom du groupe spawné
		spawnedBlueInterceptGroup = grp
		subscribeToLandEvent("CVN-75", findFirstUnit(grp), grp )
				env.info("Spawned group name: " .. grp:GetName())
		local flagName = "LifeTime_" .. grp:GetName()
		trigger.action.setUserFlag(flagName, 1)
		subscribeLifeTimeChecker(grp, 5400, flagName)
				
	end)
  :SpawnScheduled(120, 0.5)
  :SpawnScheduleStop()

  --Spawn BlueAttackChopper
  Spawn_BlueAttack = SPAWN:New("BlueSpawnAttack")
	:InitLimit(2, 0)
	:OnSpawnGroup(function(grp)
		spawnedBlueAttackGroupName = grp:GetName()-- Stocke le nom du groupe spawné
		spawnedBlueAttackGroup = grp
		subscribeToLandEvent("Invincible-1-1", findFirstUnit(grp), grp )
				env.info("Spawned group name: " .. grp:GetName())
		local flagName = "LifeTime_" .. grp:GetName()
		trigger.action.setUserFlag(flagName, 1)
		subscribeLifeTimeChecker(grp, 1100, flagName)
	end)
  :SpawnScheduled(30, 0.5)
  :SpawnScheduleStop()
 
 -- Spawn Red Vehicule Transport
Spawn_RedVehiculeTransport = SPAWN:New("RedVehiculeTransportSpawn")
  :InitLimit(1, 0)
  :OnSpawnGroup(function(grp)
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
  :SpawnScheduled(180, 0.6)
  :SpawnScheduleStop()

-- Ravitailleur (Blue Transport)
Spawn_Ravitailleur = SPAWN:New("BlueRenfortTroopTransport")
  :InitLimit(2, 0)
  :OnSpawnGroup(function(grp)
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
  :SpawnScheduled(180, 0.6)
  

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

-- Variables globales pour les groupes à suivre
flagsToCheck = {}

-- Fonction pour suivre la durée de vie d'une unité spawné et les détruire à la fin
function subscribeLifeTimeChecker(grp, esperanceVie, flagName) -- (group = Groupe d'unité, esperanceVie = en secondes, flagName = nom du flag)
    -- Vérifie si le groupe est déjà enregistré pour éviter les doublons
    for _, entry in ipairs(flagsToCheck) do
        if entry.group == grp then
            env.warning("Le groupe " .. grp:GetName() .. " est déjà enregistré dans flagsToCheck.")
            return
        end
    end

    -- Ajoute le groupe à la liste des groupes à surveiller
    table.insert(flagsToCheck, {group = grp, esperance = timer.getTime() + esperanceVie, flagName = flagName})

    -- Démarre une minuterie pour surveiller la durée de vie des groupes
    if not lifeTimeCheckerRunning then
        lifeTimeCheckerRunning = true
        timer.scheduleFunction(minuterieDeVie, nil, timer.getTime() + 1)
    end
end

-- Fonction appelée périodiquement pour vérifier les durées de vie
function minuterieDeVie()
    local currentTime = timer.getTime()

    for i = #flagsToCheck, 1, -1 do -- Parcourt la table en sens inverse pour supprimer les entrées
        local entry = flagsToCheck[i]
        local flagName = entry.flagName

        -- Vérifie la durée de vie ou le flag
        if currentTime >= entry.esperance or trigger.misc.getUserFlag(flagName) == 0 then
            local group = entry.group
            if group and group:IsAlive() then
                env.info("Destruction du groupe: " .. group:GetName() .. " après " .. entry.esperance - (entry.esperance - currentTime) .. " secondes.")
                group:Destroy()
            end

            -- Supprime l'entrée de la table et nettoie le flag
            table.remove(flagsToCheck, i)
            trigger.action.setUserFlag(flagName, 0)
        end
    end

    -- Relance la minuterie si des groupes restent à surveiller
    if #flagsToCheck > 0 then
        timer.scheduleFunction(minuterieDeVie, nil, timer.getTime() + 1)
    else
        lifeTimeCheckerRunning = false
        env.info("Aucun groupe restant à surveiller. Minuterie arrêtée.")
    end
end




-- Fonction de gestion des atterrissages des helicos ai pour dispawn
-- Fonction pour s'abonner à l'événement LAND pour un lieu spécifique
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
            AttackGroupTaskPush(spawnedBlueInterceptName, spawnedRedStrikeGroupName, 0)
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
            trigger.action.outText("F-14 détecté dans le ciel !", 10)
            Spawn_RedStrikeEscort:SpawnScheduleStart() -- Démarre l'escorte si un F-14 décolle
            kola.isInterceptorAlreadyAirborne = true
        end
    else
        -- Vérifie si des F-14 sont actifs
        if not detectActiveF14s() then
            if kola.isInterceptorAlreadyAirborne then
                kola.isInterceptorAlreadyAirborne = false
                env.info("Aucun F-14 actif. Arrêt de l'escorte.")
                Spawn_RedStrikeEscort:SpawnScheduleStop() -- Arrête l'escorte s'il n'y a plus de F-14
            end
        end
    end
	end
end

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



function isInTable(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--[[
-- Fonction pour s'abonner à l'événement LAND pour un lieu spécifique
function subscribeToLandEvent(placeToMonitor, unitToMonitor, Groupe)
    -- Validation pour éviter des doublons dans les tableaux
    if not isInTable(landingToMonitor, placeToMonitor) then
        table.insert(landingToMonitor, placeToMonitor)
    end
    if not isInTable(unitlandingToMonitor, unitToMonitor) then
        table.insert(unitlandingToMonitor, unitToMonitor)
    end
    if not isInTable(grpToMonitor, Groupe) then
        table.insert(grpToMonitor, Groupe)
    end
    
    -- Enregistre le gestionnaire d'événements
    world.addEventHandler(kola.eventHandler)
end
 ]]--
  -- Fonction pour s'abonner à l'événement LAND pour un lieu spécifique
function subscribeToLandEvent(placeToMonitor, unitToMonitor, Groupe)
    
    table.insert(landingToMonitor, placeToMonitor)
    table.insert(unitlandingToMonitor, unitToMonitor)
    table.insert(grpToMonitor, Groupe)
    
    
    -- Enregistre le gestionnaire d'événements
    world.addEventHandler(kola.eventHandler)
end
  
  
  --Spawn Les Speedboat
  ZoneTable = { ZONE:New( "NavalSpawnZone-1" ) }

Spawn_Rescue_1 = SPAWN:New( "NavalSpawn-1" )
  :InitLimit( 10, 0 )
  :InitRandomizeZones( ZoneTable )    
  :SpawnScheduled( 60, .5 )



--Red Troops
Spawn_RedTroop = SPAWN:New( "TroopTransportSpawn" )
	:InitLimit( 16, 0 )
	:InitArray( 90, 8, 3, 6 )
Spawn_RedManpadTroop = SPAWN:New( "RedManPadSpawn" )
	:InitLimit( 2, 0 )
	:InitArray( 90, 8, 3, 6 )
	

--Red Backup
Spawn_RedBackup = SPAWN:New( "RedBackupSpawn" )
	:InitLimit( 8, 0 )
	:OnSpawnGroup(function(grp)
		spawnedRedBackupGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedRedBackupGroup = grp -- Stocke l'objet du groupe spawné
		subscribeToLandEvent("Naval-3-1", findFirstUnit(grp), grp)
		    -- Message pour les joueurs
		--MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
    
    -- Log dans le dcs.log
    env.info("Spawned Backupgroup name: " .. spawnedRedBackupGroupName)
  end)
  
 Spawn_RedHeloBackup = SPAWN:New( "RedHeloBackup" )
	:InitLimit( 1, 0 )
	:OnSpawnGroup(function(grp)
		spawnedRedHeloBackupGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedRedHeloBackupGroup = grp -- Stocke l'objet du groupe spawné
		    -- Message pour les joueurs
		--MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
    
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
			
 Spawn_RedStrike = SPAWN:New( "RedStrike1" )
	:InitLimit( 4, 0 )
	:InitRandomizeZones( RedStrike_ZoneTable )
	:OnSpawnGroup(function(grp)
		spawnedRedStrikeGroupName = grp:GetName() -- Stocke le nom du groupe spawné
		spawnedRedStrikeGroup = grp -- Stocke l'objet du groupe spawné
		kola.dernierStrikeActif = spawnedRedStrikeGroupName
		    -- Message pour les joueurs
		--MESSAGE:New("Backup Spawn: " .. string.sub(grp:GetName(), 1, -5), 15, "SPAWN"):ToAll()
    
		-- Log dans le dcs.log
		env.info("Spawned Strikegroup name: " .. spawnedRedStrikeGroupName)
		if detectActiveF14s() then AttackGroupTaskPush(spawnedBlueInterceptName, spawnedRedStrikeGroupName, 0) end
  end) 
	:SpawnScheduled(180, 0.5)
	:SpawnScheduleStop()
 
 
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
			
 Spawn_RedStrikeEscort = SPAWN:New( "RedEscortSpawn" )
	:InitLimit( 2, 0 )
	:InitRandomizeZones( RedStrike_ZoneTable )
	:OnSpawnGroup(function(grp)
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
	:SpawnScheduled(60, 0.5)
	:SpawnScheduleStop()
 
 
 -- End of Red Strike Escort
 
   -- Endgame
    Endgame_ZoneTable = { 	
				ZONE:New( "EndgameSpawnZone-1" ), 
				ZONE:New( "EndgameSpawnZone-2" ),
				ZONE:New( "EndgameSpawnZone-3" ),
				ZONE:New( "EndgameSpawnZone-4" ), 
				ZONE:New( "EndgameSpawnZone-5" )
				
			}
 Spawn_Endgame = SPAWN:New( "Poseidon" )
	:InitLimit( 4, 0 )
	:InitRandomizeZones( Endgame_ZoneTable )
	:OnSpawnGroup(function(grp)
		spawnedEndgameGroupName = grp:GetName()
		spawnedEndgameGroup = grp
		--MESSAGE:New("Poseidons Spawned"):ToAll()
		
		-- Log dans le dcs.log
		env.info("Spawned EndGame name: " .. spawnedEndgameGroupName)
		end)
    :SpawnScheduled(180, 0.5)
	:SpawnScheduleStop()
 
 
 -- End of Red Strike
 
 
-- Fonction pour détecter la présence de F-14B ou F-14A bleus dans le ciel


  
  
function DropTroopsWithCTLD(grp, groupNameToSpawn)
    -- Log des paramètres
    env.info("Checking group: " .. grp:GetName())
	env.info("Checking group Size: " .. grp:GetSize())
	env.info("Checking group's unit name: " .. Group.getByName(grp:GetName()):getUnit(1):getName())
	env.info("Checking group's unit Coalition: " .. Group.getByName(grp:GetName()):getUnit(1):getCoalition())
	
    local heliUnit = Group.getByName(grp:GetName()):getUnit(1)  -- Utilise getUnits() pour obtenir toutes les unités du groupe
		if heliUnit then
			env.info("CTLD Debug: Heli unit found: " .. heliUnit:getName() .. " at position " .. tostring(heliUnit:getPoint()))
			-- Cherche le groupe dans ctld.loadableGroups
			local selectedGroup = nil
			for _, group in ipairs(ctld.loadableGroups) do
				if group.name == groupNameToSpawn then
					selectedGroup = group
					break
				end
			end

			if selectedGroup then
				local coalitionSide = heliUnit:getCoalition() == 1 and "red" or "blue"
				local numberOrDescription = {inf = 6, mg = 3, at = 4}
				local spawnPoint = heliUnit:getPoint()
				local searchRadius = 1500 
		
				ctld.spawnGroupAtPoint(coalitionSide, numberOrDescription, spawnPoint, searchRadius)
				trigger.action.outText("CTLD : Déploiement de " .. groupNameToSpawn .. " par " .. grp:GetName(), 10)
			else
                trigger.action.outText("Erreur CTLD : Groupe " .. groupNameToSpawn .. " introuvable.", 10)
			end
        else
            trigger.action.outText("Erreur CTLD : Aucune unité trouvée pour " .. grp:GetName(), 10)
        end
end

 

 
 
 
 
 
 
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


function stockerlesRoutes(grp, routeName)
    local nomGroup
    local nomRoute
    if grp ~= nil then
        nomGroup = grp:GetName()
    else
        if spawnedRavitailleurGroup then
            nomGroup = spawnedRavitailleurGroup:GetName()
        else
            env.warning("Aucun groupe valide pour stocker la route.")
            return
        end
    end

    if routeName ~= nil then
        nomRoute = routeName
    else
        nomRoute = "aucun nom"
    end

    -- Appel de la fonction principale pour stocker la route
    stockerRoute(grp, nomRoute)
end


-- Ajouter un menu radio pour afficher et enregistrer le score
MENU_COALITION_COMMAND:New(
    coalition.side.BLUE, -- Côté de la coalition (ici, BLUE)
    "Score", -- Nom de la commande
    nil, -- Pas de parent pour ce menu
    getMissionScore -- Appeler la fonction
)


local rebootMenu = missionCommands.addSubMenu("Menu Reboot", EODMenu)
local rebootSubMenu = missionCommands.addSubMenu("Reboot Mission", rebootMenu)
local rbtCmd = missionCommands.addCommand("Reboot", rebootSubMenu, function()
    trigger.action.setUserFlag("EndgameFlag", 66)
end)

local alliesMenu = missionCommands.addSubMenu("Allies Commands", EODMenu)

-- Sous-menu pour les intercepteurs F-14
local AllyInterceptSubMenu = missionCommands.addSubMenu("F-14 Interceptors", alliesMenu)
local allyInterceptStartCmd = missionCommands.addCommand("F-14 Intercept Start", AllyInterceptSubMenu, function()
    Spawn_BlueIntercept:SpawnScheduleStart() 
end)
local allyInterceptStopCmd = missionCommands.addCommand("F-14 Intercept Stop", AllyInterceptSubMenu, function()
    Spawn_BlueIntercept:SpawnScheduleStop() 
end)

-- Sous-menu pour le transport de troupes
local AllyBTTSubMenu = missionCommands.addSubMenu("Blue Troop Transport", alliesMenu)
local allyBTTStartCmd = missionCommands.addCommand("Start Spawn", AllyBTTSubMenu, function()
    Spawn_Ravitailleur:SpawnScheduleStart()
end)
local allyBTTStopCmd = missionCommands.addCommand("Stop Spawn", AllyBTTSubMenu, function()
    Spawn_Ravitailleur:SpawnScheduleStop()
end)

--[[MENU_COALITION_COMMAND:New(
    coalition.side.BLUE, -- Côté de la coalition (ici, BLUE)
    "Stocker Routes", -- Nom de la commande
    nil, -- Pas de parent pour ce menu
    function()
        stockerlesRoutes(nil, nil) -- Appel avec des valeurs par défaut
    end
)]]--



--[[MENU_COALITION_COMMAND:New(
    coalition.side.BLUE, -- Côté de la coalition (ici, BLUE)
    "Supprimer le Red Transport spawné", -- Nom de la commande
    nil, -- Pas de parent pour ce menu
    function()
        spawnedTransportGroup:Destroy()
    end
)

MENU_COALITION_COMMAND:New(
    coalition.side.BLUE, -- Côté de la coalition (ici, BLUE)
    "Supprimer le EndGame spawné", -- Nom de la commande
    nil, -- Pas de parent pour ce menu
    function()
        spawnedEndgameGroup:Destroy()
    end
)]]--

-- Définir la fonction pour obtenir le score de la mission


-- Ajouter un menu radio pour afficher le score
MENU_COALITION_COMMAND:New(
    coalition.side.BLUE, -- Côté de la coalition (ici, BLUE)
    "Score", -- Nom de la commande
    nil, -- Pas de parent pour ce menu
    getMissionScore -- Appeler la fonction
)



 
--EOF
