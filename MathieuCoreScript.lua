MESSAGE:New("Mathieu Core Loaded"):ToAll()

function findFirstUnit(grp)
    local group = Group.getByName(grp:GetName())
    if group then
        -- Obtenez la liste des unités du groupe
        local units = group:getUnits()
        if units and #units > 0 then
            -- Récupérez la première unité
            local firstUnit = units[1]
            if firstUnit and firstUnit:isExist() then
                local unitName = firstUnit:getName()
                -- Retourne le nom de la première unité
                env.info("Nom de la première unité du groupe [" .. group:getName() .. "] est : " .. unitName)
                return unitName
            else
                env.warning("La première unité du groupe [" .. group:getName() .. "] n'existe pas.")
            end
        else
            env.warning("Aucune unité trouvée dans le groupe [" .. group:getName() .. "].")
        end
    else
        env.warning("Groupe introuvable : " .. grp:GetName())
    end -- Fin du bloc `if group then`

    -- Si aucun nom d'unité n'est trouvé, retournez `nil`
    return nil
end

local routes_ = {} -- format {points, "nom du groupe qui fourni la route", "nom de la route"}

function getWaypoints(group)
    
    if group then
        local route = group:CopyRoute(0,9)
        if route ~= nil  then
            return route -- Renvoie les points de route (waypoints)
        end
    end
    env.warning("Impossible de récupérer les waypoints pour le groupe : " .. groupName)
    return nil
end

-- Stocker routes des groupes
function stockerRoute(groupName, nomRoute)
    local waypoints = getWaypoints(groupName) -- Récupérer les waypoints du groupe
    if waypoints then
        -- Ajouter à la table globale
        table.insert(routes_, { waypoints = waypoints, groupName = groupName, nomRoute = nomRoute })
        env.info("Route du groupe [" .. groupName .. "] stockée sous le nom : " .. nomRoute)

        -- Écrire dans le fichier
        local filePath = lfs.writedir() .. "routeStockee.lua"
        local file = io.open(filePath, "a") -- Ouvrir en mode ajout
        if file then
            file:write("-- Route stockée pour " .. groupName .. " (" .. nomRoute .. ")\n")
            file:write("return {\n")
            file:write("    groupName = \"" .. groupName .. "\",\n")
            file:write("    nomRoute = \"" .. nomRoute .. "\",\n")
            file:write("    waypoints = {\n")
            for _, waypoint in ipairs(waypoints) do
                file:write("        {\n")
                for key, value in pairs(waypoint) do
                    if type(value) == "string" then
                        file:write("            " .. key .. " = \"" .. value .. "\",\n")
                    else
                        file:write("            " .. key .. " = " .. tostring(value) .. ",\n")
                    end
                end
                file:write("        },\n")
            end
            file:write("    }\n")
            file:write("}\n")
            file:close()
            env.info("Route enregistrée dans le fichier : " .. filePath)
        else
            env.warning("Impossible d'ouvrir le fichier : " .. filePath)
        end
    else
        env.warning("Aucune route trouvée pour le groupe : " .. groupName)
    end
end


--pour utiliser les wpStocké
function setWaypoints(groupName, waypoints)
    local group = Group.getByName(groupName)
    if group and waypoints then
        local controller = group:getController()
        if controller then
            local mission = {
                id = 'Mission',
                params = {
                    route = {
                        points = waypoints
                    }
                }
            }
            controller:setTask(mission)
            env.info("Waypoints assignés au groupe : " .. groupName)
        else
            env.warning("Impossible d'obtenir le contrôleur pour le groupe : " .. groupName)
        end
    else
        env.warning("Groupe ou waypoints invalides pour le groupe : " .. groupName)
    end
end



--Changement de waypoint
function switchWP(grpName, wpNum1, wpNum2)
    -- grpName est le nom du groupe qui doit exécuter l'action
    -- wpNum1 est l'index du waypoint initial (pas nécessaire ici mais peut être utile pour des contrôles supplémentaires)
    -- wpNum2 est l'index du waypoint vers lequel rediriger le groupe

    local group = Group.getByName(grpName)  -- Récupère le groupe par son nom
	if not group or not group:isExist() then
        env.warning("TriggerAction: Le groupe '" .. grpName .. "' n'existe pas ou est invalide.")
        return
    end
	
    if not group or not group:isExist() then
        env.warning("TriggerAction: Le groupe '" .. grpName .. "' n'existe pas ou est invalide.")
        return
    end

    local controller = group:getController()  -- Récupère le contrôleur du groupe

    -- Créez une tâche pour que le groupe change de waypoint
    local task = {
        id = 'WrappedAction',
        params = {
            action = {
                id = 'SwitchWaypoint',
                params = {
                    fromWaypointIndex = wpNum1,  -- Index du waypoint de départ
                    goToWaypointIndex = wpNum2,  -- Index du waypoint de destination
                }
            }
        }
    }

    -- Applique la tâche au contrôleur du groupe
    controller:setTask(task)

    -- Log pour le débogage
    env.info("Le groupe '" .. grpName .. "' a été redirigé du waypoint " .. wpNum1 .. " vers le waypoint " .. wpNum2 .. ".")
	--MESSAGE:New("Le groupe '" .. grpName .. "' a été redirigé du waypoint " .. wpNum1 .. " vers le waypoint " .. wpNum2 .. "."):ToAll()
end

--AttackGroupTaskPush / set
function AttackGroupTaskPush(attackerGroupName, attackedGroupName, typePush)
    -- attackerGroupName : le groupe qui va exécuter la tâche d'attaque.
    -- attackGroup : le groupe cible de l'attaque à planifier.
    -- typePush : 0 = push, 1 = set.

    local group = Group.getByName(attackerGroupName)
    local groupOfTarget = Group.getByName(attackedGroupName)
	local typeDePush = 0
	typeDePush = typePush

    if not group or not group:isExist() then
        env.warning("TriggerAction: Le groupe attaquant '" .. attackerGroupName .. "' n'existe pas ou est invalide.")
        return
    end

    if not groupOfTarget or not groupOfTarget:isExist() then
        env.warning("TriggerAction: Le groupe cible '" .. attackedGroupName .. "' n'existe pas ou est invalide.")
        return
    end

    local controller = group:getController() -- Récupère le contrôleur du groupe.

    -- Crée la tâche pour attaquer le groupe cible.
    local taskAttack = {
        id = 'AttackGroup',
        params = {
            groupId = groupOfTarget:getID(), -- Utilisation correcte de l'ID.
            weaponType = "ALL",
        }
    }

    -- Applique la tâche au contrôleur du groupe.
    if typeDePush == 0 then
        controller:pushTask(taskAttack)
    elseif typeDePush == 1 then
        controller:setTask(taskAttack)
    else
        env.warning("TriggerAction: Mauvais type de tâche passé. Utilisez 0 (push) ou 1 (set).")
        return
    end

    -- Log pour le débogage.
    env.info("Le groupe '" .. attackerGroupName .. "' a reçu la tâche '" .. taskAttack.id .. "' pour attaquer '" .. attackedGroupName .. "'.")
    MESSAGE:New("Le groupe '" .. attackerGroupName .. "' attaque le groupe '" .. attackedGroupName .. "'."):ToAll()
end



-- Flag ON ou OFF
function setFlagValue(flagName, value)
    if type(flagName) == "string" and (value == 0 or value == 1) then
        trigger.action.setUserFlag(flagName, value) -- Définit la valeur du flag (0 pour OFF, 1 pour ON)
        if value == 0 then
            env.info("FLAG OFF exécuté pour : " .. flagName) -- Log pour FLAG OFF
        elseif value == 1 then
            env.info("FLAG ON exécuté pour : " .. flagName) -- Log pour FLAG ON
        end
    else
        env.warning("Le paramètre passé à setFlagOff n'est pas valide.")
    end
end


function DestroyUnit( unitName )
	local group = Group.findByUnit( unitName )

end