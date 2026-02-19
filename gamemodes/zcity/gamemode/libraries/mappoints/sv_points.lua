-- Система точек, спавны и так далее, все для чего нужны какие либо координаты на карте.
zb = zb or {}

zb.Points = zb.Points or {}

zb.Points.Example = zb.Points.Example or {}

-- ============================================
-- FIX: Rejestracja wszystkich grup punktów
-- ============================================
zb.Points["Spawnpoint"] = zb.Points["Spawnpoint"] or {}
zb.Points["RandomSpawns"] = zb.Points["RandomSpawns"] or {}
zb.Points["HMCD_TDM_T"] = zb.Points["HMCD_TDM_T"] or {}
zb.Points["HMCD_TDM_CT"] = zb.Points["HMCD_TDM_CT"] or {}
zb.Points["HMCD_CRI_T"] = zb.Points["HMCD_CRI_T"] or {}
zb.Points["HMCD_CRI_CT"] = zb.Points["HMCD_CRI_CT"] or {}
zb.Points["RIOT_TDM_RIOTERS"] = zb.Points["RIOT_TDM_RIOTERS"] or {}
zb.Points["RIOT_TDM_LAW"] = zb.Points["RIOT_TDM_LAW"] or {}
zb.Points["HMCD_SWO_AZOV"] = zb.Points["HMCD_SWO_AZOV"] or {}
zb.Points["HMCD_SWO_WAGNER"] = zb.Points["HMCD_SWO_WAGNER"] or {}
zb.Points["BOMB_ZONE_A"] = zb.Points["BOMB_ZONE_A"] or {}
zb.Points["BOMB_ZONE_B"] = zb.Points["BOMB_ZONE_B"] or {}
zb.Points["HOSTAGE_DELIVERY_ZONE"] = zb.Points["HOSTAGE_DELIVERY_ZONE"] or {}
zb.Points["LootSpawns"] = zb.Points["LootSpawns"] or {}

function zb.CreateMapDir()
    local map = game.GetMap()
    if not file.Exists( "zbattle", "DATA" ) then file.CreateDir( "zbattle" ) end
    if not file.Exists( "zbattle/mappoints", "DATA" ) then file.CreateDir( "zbattle/mappoints" ) end
    if not file.Exists( "zbattle/mappoints/" .. map, "DATA" ) then file.CreateDir( "zbattle/mappoints/" .. map ) end
    if file.Exists( "zbattle/mappoints/" .. map, "DATA" ) then return true end
    return true
end

function zb.GetMapPoints( pointGroup, forceupdatepoints )
    if not zb.CreateMapDir() then 
        PrintMessage( HUD_PRINTTALK, "sv_points.lua: map folder dosen't exist?" ) 
        return {}
    end
    
    if not zb.Points[pointGroup] then 
        zb.Points[pointGroup] = {}
        print("[Z-CITY] Auto-registered point group: " .. pointGroup)
    end

    forceupdatepoints = forceupdatepoints or false
    if (not forceupdatepoints) and zb.Points[pointGroup].Points and #zb.Points[pointGroup].Points > 0 then
        local newTbl = {}
        table.CopyFromTo(zb.Points[pointGroup].Points, newTbl)
        return newTbl
    end

    local map = game.GetMap()
    local fileContent = file.Read( "zbattle/mappoints/" .. map .. "/" .. pointGroup .. ".json", "DATA" )
    
    if fileContent and fileContent ~= "" then
        zb.Points[pointGroup].Points = util.JSONToTable( fileContent ) or {}
    else
        zb.Points[pointGroup].Points = {}
    end
    
    local newTbl = {}
    if zb.Points[pointGroup].Points then
        table.CopyFromTo(zb.Points[pointGroup].Points, newTbl)
    end

    return newTbl
end

function zb.SaveMapPoints( pointGroup, pointsData )
    if not zb.CreateMapDir() then 
        PrintMessage( HUD_PRINTTALK, "sv_points.lua: map folder dosen't exists?" ) 
        return false 
    end
    
    if not zb.Points[pointGroup] then 
        zb.Points[pointGroup] = {}
    end

    local map = game.GetMap()
    file.Write( "zbattle/mappoints/" .. map .. "/" .. pointGroup .. ".json", util.TableToJSON( pointsData, true ) )
    
    zb.Points[pointGroup].Points = pointsData
    
    return true
end

function zb.CreateMapPoint( pointGroup, pointData, needsave )
    if not zb.CreateMapDir() then 
        PrintMessage( HUD_PRINTTALK, "sv_points.lua: map folder dosen't exists?" ) 
        return false 
    end
    
    if not zb.Points[pointGroup] then 
        zb.Points[pointGroup] = {}
    end

    zb.Points[pointGroup].Points = zb.Points[pointGroup].Points or zb.GetMapPoints( pointGroup )
    
    if not zb.Points[pointGroup].Points then
        zb.Points[pointGroup].Points = {}
    end

    zb.Points[pointGroup].Points[ #zb.Points[pointGroup].Points + 1 ] = pointData
    
    needsave = needsave or true
    if needsave then
        zb.SaveMapPoints( pointGroup, zb.Points[pointGroup].Points )
    end
    
    return true
end

function zb.RemoveMapPoint( pointGroup, pointNum, needsave, removeall )
    if not zb.CreateMapDir() then 
        PrintMessage( HUD_PRINTTALK, "sv_points.lua: map folder dosen't exists?" ) 
        return false 
    end
    
    if not zb.Points[pointGroup] then 
        zb.Points[pointGroup] = {}
    end

    zb.Points[pointGroup].Points = zb.Points[pointGroup].Points or zb.GetMapPoints( pointGroup )
    
    if not zb.Points[pointGroup].Points then
        zb.Points[pointGroup].Points = {}
    end
    
    removeall = removeall or false
    if removeall then 
        zb.Points[pointGroup].Points = {} 
    else
        if not zb.Points[pointGroup].Points[ math.Clamp(pointNum or 0, 1, math.max(1, #zb.Points[pointGroup].Points)) ] then 
            PrintMessage( HUD_PRINTTALK, "sv_points.lua: point dosen't exist." ) 
            return false 
        end
        table.remove( zb.Points[pointGroup].Points, math.Clamp(pointNum or 0, 1, #zb.Points[pointGroup].Points) )
    end
    
    needsave = needsave or true
    if needsave then
        zb.SaveMapPoints( pointGroup, zb.Points[pointGroup].Points )
    end
    return true
end

function zb.SetMapPoint( pointGroup, pointNum, pointData, needsave )
    if not zb.CreateMapDir() then 
        PrintMessage( HUD_PRINTTALK, "sv_points.lua: map folder couldn't be created." ) 
        return false 
    end
    
    if not zb.Points[pointGroup] then 
        zb.Points[pointGroup] = {}
    end

    zb.Points[pointGroup].Points = zb.Points[pointGroup].Points or zb.GetMapPoints( pointGroup )
    
    if not zb.Points[pointGroup].Points or #zb.Points[pointGroup].Points == 0 then
        PrintMessage( HUD_PRINTTALK, "sv_points.lua: no points exist in group." ) 
        return false
    end
    
    if not zb.Points[pointGroup].Points[ math.Clamp(pointNum, 1, #zb.Points[pointGroup].Points) ] then 
        PrintMessage( HUD_PRINTTALK, "sv_points.lua: point dosen't exist." ) 
        return false 
    end

    zb.Points[pointGroup].Points[ math.Clamp(pointNum, 1, #zb.Points[pointGroup].Points) ] = pointData

    if needsave then
        zb.SaveMapPoints( pointGroup, zb.Points[pointGroup].Points )
    end
    return true
end

function zb.GetAllPoints(forceupdate)
    forceupdate = forceupdate or true
    local allpoints = {}
    
    for k, pointGroup in pairs(zb.Points) do
        local pointgroups = zb.GetMapPoints( k, forceupdate ) 
        if not pointgroups then continue end
        allpoints[k] = pointgroups
    end

    hook.Run("ZB_AfterAllPoints", zb.Points)
    
    return allpoints
end

hook.Add("InitPostEntity", "inithuyOwOs", function()
    zb.GetAllPoints(true)
end)

hook.Add( "Initialize", "LoadMapPoints", zb.CreateMapDir )

COMMANDS.pointnew = {function(ply,args)
    local ang = ply:EyeAngles()
    ang.x = 0
    local pointData = {
        pos = ply:GetPos(),
        ang = ang
    }

    zb.CreateMapPoint( args[1], pointData )
    ply:ConCommand("zb_pointsupdate")
end,1,"Creates a new point on the map\nArgs - pointGroup"}

COMMANDS.pointset = {function(ply,args)
    zb.SetMapPoint( args[1], args[2], args[3] )
    ply:ConCommand("zb_pointsupdate")
end,1,"Sets a point on the map\nArgs - pointGroup, pointNumber"}

COMMANDS.pointremove = {function(ply,args)
    zb.RemoveMapPoint( args[1], args[2], true, args[2] == "*" )
    ply:ConCommand("zb_pointsupdate")
end,1,"Remove point (points) on the map\nArgs - pointGroup, pointNumber ( * - allpoints )"}

function zb.SendPointsToPly(ply, shouldprint)
    net.Start("zb_getallpoints")
        net.WriteTable(zb.GetAllPoints())
    net.Send(ply)

    if shouldprint then
        ply:ChatPrint("Points: Points transferred")
    end
end

function zb.SendPoints()
    local rf = RecipientFilter()
    
    for k, v in player.Iterator() do
        rf:AddPlayer(v)
    end

    net.Start("zb_getallpoints")
        net.WriteTable(zb.GetAllPoints())
    net.Send(rf)
end

function zb.SendSpecificPointsToPly(ply, pointGroup, shouldprint)
    net.Start("zb_getspecificpoints")
        net.WriteString(pointGroup)
        net.WriteTable(zb.GetAllPoints()[pointGroup] or {})
    if IsValid(ply) then    
        net.Send(ply)
        
        if shouldprint then
            ply:ChatPrint("Points: Points transferred")
        end
    else
        net.Broadcast()
    end
end

local angZero = Angle(0,0,0)

function zb.TranslateVectorsToPoints(tbl)
    local newtbl = {}
    for i,val in pairs(tbl) do
        if istable(val) then
            if val.pos and val.ang and isvector(val.pos) and isangle(val.ang) then 
                table.insert(newtbl, val) 
            end
        end
        if isvector(val) then 
            table.insert(newtbl, {pos = val, ang = angZero}) 
        end
    end
    return newtbl
end

function zb.TranslatePointsToVectors(tbl)
    local newtbl = {}
    
    for i,val in pairs(tbl) do
        if istable(val) then
            if val.pos and val.ang and isvector(val.pos) and isangle(val.ang) then
                table.insert(newtbl, val.pos)
            end
        end

        if isvector(val) then 
            table.insert(newtbl, val) 
        end
    end

    return newtbl
end

net.Receive("zb_getallpoints",function(len,ply)
    if not ply:IsAdmin() then 
        ply:ChatPrint("Points: Access denied") 
        return 
    end

    zb.SendPointsToPly(ply, true)
end)

function zb.tdm_checkpoints()
    local vecs = {}
    local points = zb.GetMapPoints( "HMCD_TDM_T" )
    for i,ent in pairs(ents.FindByClass("info_player_terrorist")) do
        table.insert(vecs, ent:GetPos())
    end

    local points = #points == 0 and zb.TranslateVectorsToPoints(vecs) or points

    if #zb.GetMapPoints( "HMCD_TDM_T" ) == 0 then
        zb.SaveMapPoints( "HMCD_TDM_T", points )
    end
    if #zb.GetMapPoints( "RIOT_TDM_RIOTERS" ) == 0 then
        zb.SaveMapPoints( "RIOT_TDM_RIOTERS", points )
    end
    if #zb.GetMapPoints( "HMCD_SWO_AZOV" ) == 0 then
        zb.SaveMapPoints( "HMCD_SWO_AZOV", points )
    end
    if #zb.GetMapPoints( "HMCD_CRI_T" ) == 0 then
        zb.SaveMapPoints( "HMCD_CRI_T", points )
    end
    
    local vecs = {}
    local points = zb.GetMapPoints( "HMCD_TDM_CT" )
    for i, ent in pairs(ents.FindByClass("info_player_counterterrorist")) do
        table.insert(vecs, ent:GetPos())
    end
   
    local points = #points == 0 and zb.TranslateVectorsToPoints(vecs) or points
    
    if #zb.GetMapPoints( "HMCD_TDM_CT" ) == 0 then
        zb.SaveMapPoints( "HMCD_TDM_CT", points )
    end
    if #zb.GetMapPoints( "HMCD_CRI_CT" ) == 0 then
        zb.SaveMapPoints( "HMCD_CRI_CT", points )
    end
    if #zb.GetMapPoints( "RIOT_TDM_LAW" ) == 0 then
        zb.SaveMapPoints( "RIOT_TDM_LAW", points )
    end
    if #zb.GetMapPoints( "HMCD_SWO_WAGNER" ) == 0 then
        zb.SaveMapPoints( "HMCD_SWO_WAGNER", points )
    end

    local foundA
    local foundB
    for i, ent in ipairs(ents.FindByClass("func_bomb_target")) do
        local vecs = {}
        local min, max = ent:WorldSpaceAABB()

        vecs[1] = min
        vecs[2] = max

        if not foundB then
            local points = zb.TranslateVectorsToPoints(vecs)
            zb.SaveMapPoints( "BOMB_ZONE_B", points )
            foundB = true
            continue
        end

        if not foundA then
            local points = zb.TranslateVectorsToPoints(vecs)
            zb.SaveMapPoints( "BOMB_ZONE_A", points )
            foundA = true
            continue
        end
    end

    local points = {}
    for i, ent in pairs(ents.FindByClass("func_hostage_rescue")) do
        local vecs = {}
        local min, max = ent:WorldSpaceAABB()
        table.insert(points, min)
        table.insert(points, max)
    end

    points = zb.TranslateVectorsToPoints(points)

    if #zb.GetMapPoints( "HOSTAGE_DELIVERY_ZONE" ) == 0 then
        zb.SaveMapPoints( "HOSTAGE_DELIVERY_ZONE", points )
    end
end

hook.Add("PostCleanupMap", "no_t_ct_spawns", function()
    zb.tdm_checkpoints()
end)

-- ============================================
-- FIX: Funkcja do znajdowania PRAWDZIWYCH miejsc na mapie
-- ============================================

-- Sprawdza czy pozycja jest poprawnym miejscem do spawnu
local function IsValidSpawnPosition(pos)
    if not pos or not isvector(pos) then return false end
    
    -- Sprawdź czy nie w void (skybox)
    local contents = util.PointContents(pos)
    if bit.band(contents, CONTENTS_SOLID) ~= 0 then return false end
    if bit.band(contents, CONTENTS_WINDOW) ~= 0 then return false end
    
    -- Sprawdź czy jest podłoga pod spodem
    local trDown = util.TraceLine({
        start = pos + Vector(0, 0, 10),
        endpos = pos - Vector(0, 0, 500),
        mask = MASK_SOLID_BRUSHONLY
    })
    
    if not trDown.Hit then return false end
    if trDown.HitSky then return false end
    if trDown.HitNoDraw then return false end
    
    -- Sprawdź czy jest miejsce na gracza (hull trace)
    local trHull = util.TraceHull({
        start = trDown.HitPos + Vector(0, 0, 5),
        endpos = trDown.HitPos + Vector(0, 0, 80),
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_PLAYERSOLID
    })
    
    if trHull.StartSolid then return false end
    
    -- Sprawdź czy nie w wodzie
    if bit.band(util.PointContents(trDown.HitPos), CONTENTS_WATER) == CONTENTS_WATER then
        return false
    end
    
    return true, trDown.HitPos + Vector(0, 0, 5)
end

-- Znajduje spawn używając NavMesh
local function FindSpawnsFromNavMesh()
    local spawns = {}
    local navAreas = navmesh.GetAllNavAreas()
    
    if not navAreas or #navAreas == 0 then
        print("[Z-CITY] Brak NavMesh na mapie")
        return spawns
    end
    
    print("[Z-CITY] Znaleziono " .. #navAreas .. " NavMesh areas")
    
    -- Wybierz losowe obszary NavMesh jako spawny
    local maxSpawns = math.min(50, #navAreas)
    local usedAreas = {}
    
    for i = 1, maxSpawns * 2 do -- Próbuj więcej razy żeby znaleźć dobre miejsca
        if #spawns >= maxSpawns then break end
        
        local randomArea = navAreas[math.random(#navAreas)]
        if usedAreas[randomArea:GetID()] then continue end
        
        local center = randomArea:GetCenter()
        local isValid, adjustedPos = IsValidSpawnPosition(center)
        
        if isValid then
            usedAreas[randomArea:GetID()] = true
            table.insert(spawns, {
                pos = adjustedPos,
                ang = Angle(0, math.random(0, 360), 0)
            })
        end
    end
    
    print("[Z-CITY] Znaleziono " .. #spawns .. " spawnów z NavMesh")
    return spawns
end

-- Znajduje spawn z istniejących entity na mapie
local function FindSpawnsFromEntities()
    local spawns = {}
    
    -- Lista klas entity które mogą być użyte jako spawn
    local spawnClasses = {
        "info_player_start",
        "info_player_deathmatch",
        "info_player_combine",
        "info_player_rebel",
        "info_player_counterterrorist",
        "info_player_terrorist",
        "info_player_axis",
        "info_player_allies",
        "gmod_player_start",
        "info_player_teamspawn",
        "ins_spawnpoint",
        "info_player_coop",
        "info_player_human",
        "info_player_zombie",
        "info_player_fof",
        "info_player_desperado",
        "info_player_vigilante",
    }
    
    for _, class in ipairs(spawnClasses) do
        for _, ent in pairs(ents.FindByClass(class)) do
            local pos = ent:GetPos()
            local isValid, adjustedPos = IsValidSpawnPosition(pos)
            
            if isValid then
                local ang = ent:GetAngles()
                ang.x = 0
                ang.z = 0
                table.insert(spawns, {
                    pos = adjustedPos or pos,
                    ang = ang
                })
            end
        end
    end
    
    print("[Z-CITY] Znaleziono " .. #spawns .. " spawnów z entity")
    return spawns
end

-- Znajduje spawn z prop_physics i innych obiektów
local function FindSpawnsFromProps()
    local spawns = {}
    local checkedPositions = {}
    
    -- Szukaj przy różnych obiektach na mapie
    local entityClasses = {
        "prop_physics",
        "prop_dynamic",
        "prop_static",
        "func_door",
        "func_door_rotating",
        "light",
        "light_spot",
        "info_node",
        "info_node_hint",
        "weapon_*",
        "item_*",
    }
    
    for _, class in ipairs(entityClasses) do
        for _, ent in pairs(ents.FindByClass(class)) do
            local pos = ent:GetPos()
            
            -- Nie sprawdzaj tej samej pozycji wielokrotnie
            local posKey = math.floor(pos.x / 200) .. "_" .. math.floor(pos.y / 200)
            if checkedPositions[posKey] then continue end
            checkedPositions[posKey] = true
            
            local isValid, adjustedPos = IsValidSpawnPosition(pos)
            
            if isValid then
                table.insert(spawns, {
                    pos = adjustedPos,
                    ang = Angle(0, math.random(0, 360), 0)
                })
            end
            
            if #spawns >= 30 then break end
        end
        if #spawns >= 30 then break end
    end
    
    print("[Z-CITY] Znaleziono " .. #spawns .. " spawnów z props")
    return spawns
end

-- Znajduje spawn od aktualnych graczy
local function FindSpawnsFromPlayers()
    local spawns = {}
    
    for _, ply in player.Iterator() do
        if ply:Alive() then
            local pos = ply:GetPos()
            local isValid, adjustedPos = IsValidSpawnPosition(pos)
            
            if isValid then
                local ang = ply:EyeAngles()
                ang.x = 0
                ang.z = 0
                table.insert(spawns, {
                    pos = adjustedPos or pos,
                    ang = ang
                })
                
                -- Dodaj też punkty wokół gracza
                for i = 1, 4 do
                    local angle = i * 90
                    local offset = Vector(math.cos(math.rad(angle)) * 150, math.sin(math.rad(angle)) * 150, 0)
                    local nearPos = pos + offset
                    local isNearValid, adjustedNearPos = IsValidSpawnPosition(nearPos)
                    
                    if isNearValid then
                        table.insert(spawns, {
                            pos = adjustedNearPos,
                            ang = Angle(0, angle + 180, 0)
                        })
                    end
                end
            end
        end
    end
    
    print("[Z-CITY] Znaleziono " .. #spawns .. " spawnów od graczy")
    return spawns
end

-- ============================================
-- FIX: Główna funkcja automatycznego tworzenia spawnów
-- ============================================

local function AutoCreateSpawnpoints()
    local spawnpoints = zb.GetMapPoints("Spawnpoint", true)
    
    if spawnpoints and #spawnpoints > 0 then
        print("[Z-CITY] Załadowano " .. #spawnpoints .. " spawn pointów z pliku.")
        return
    end
    
    print("[Z-CITY] ========================================")
    print("[Z-CITY] Brak Spawnpoint - szukam automatycznie...")
    print("[Z-CITY] ========================================")
    
    local newSpawns = {}
    
    -- METODA 1: Szukaj entity spawn pointów
    local entitySpawns = FindSpawnsFromEntities()
    for _, spawn in ipairs(entitySpawns) do
        table.insert(newSpawns, spawn)
    end
    
    -- METODA 2: Jeśli za mało, użyj NavMesh
    if #newSpawns < 5 then
        local navSpawns = FindSpawnsFromNavMesh()
        for _, spawn in ipairs(navSpawns) do
            table.insert(newSpawns, spawn)
        end
    end
    
    -- METODA 3: Jeśli nadal za mało, szukaj przy props
    if #newSpawns < 5 then
        local propSpawns = FindSpawnsFromProps()
        for _, spawn in ipairs(propSpawns) do
            table.insert(newSpawns, spawn)
        end
    end
    
    -- METODA 4: Jeśli nadal za mało, użyj pozycji graczy
    if #newSpawns < 3 then
        local playerSpawns = FindSpawnsFromPlayers()
        for _, spawn in ipairs(playerSpawns) do
            table.insert(newSpawns, spawn)
        end
    end
    
    -- Zapisz jeśli znaleziono cokolwiek
    if #newSpawns > 0 then
        zb.Points["Spawnpoint"].Points = newSpawns
        zb.SaveMapPoints("Spawnpoint", newSpawns)
        print("[Z-CITY] Utworzono " .. #newSpawns .. " spawn pointów automatycznie!")
        
        -- Skopiuj do RandomSpawns
        zb.Points["RandomSpawns"].Points = newSpawns
        zb.SaveMapPoints("RandomSpawns", newSpawns)
        print("[Z-CITY] Skopiowano do RandomSpawns.")
    else
        print("[Z-CITY] !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print("[Z-CITY] KRYTYCZNY BŁĄD: Nie znaleziono żadnych spawnów!")
        print("[Z-CITY] Użyj komendy: zb_addspawn (stojąc na mapie)")
        print("[Z-CITY] !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    end
end

hook.Add("InitPostEntity", "ZB_AutoCreateSpawnpoints", function()
    timer.Simple(3, function()
        AutoCreateSpawnpoints()
    end)
end)

hook.Add("PostCleanupMap", "ZB_CheckSpawnpoints", function()
    timer.Simple(1, function()
        local spawnpoints = zb.GetMapPoints("Spawnpoint", true)
        if not spawnpoints or #spawnpoints == 0 then
            AutoCreateSpawnpoints()
        end
    end)
end)

-- ============================================
-- FIX: Komendy do zarządzania spawnami
-- ============================================

concommand.Add("zb_addspawn", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then 
        if IsValid(ply) then ply:ChatPrint("Brak uprawnień!") end
        return 
    end
    
    local ang = ply:EyeAngles()
    ang.x = 0
    ang.z = 0
    
    local pointData = {
        pos = ply:GetPos(),
        ang = ang
    }
    
    zb.CreateMapPoint("Spawnpoint", pointData, true)
    zb.CreateMapPoint("RandomSpawns", pointData, true)
    
    local count = #zb.GetMapPoints("Spawnpoint", true)
    ply:ChatPrint("Dodano spawn point! Łącznie: " .. count)
    print("[Z-CITY] " .. ply:Name() .. " dodał spawn point. Łącznie: " .. count)
end)

concommand.Add("zb_checkspawns", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local spawnpoints = zb.GetMapPoints("Spawnpoint", true)
    local randomspawns = zb.GetMapPoints("RandomSpawns", true)
    
    ply:ChatPrint("=== SPAWN DIAGNOSTYKA ===")
    ply:ChatPrint("Mapa: " .. game.GetMap())
    ply:ChatPrint("Spawnpoint: " .. (spawnpoints and #spawnpoints or 0))
    ply:ChatPrint("RandomSpawns: " .. (randomspawns and #randomspawns or 0))
    ply:ChatPrint("info_player_start: " .. #ents.FindByClass("info_player_start"))
    ply:ChatPrint("NavMesh areas: " .. #navmesh.GetAllNavAreas())
    
    print("=== SPAWN DIAGNOSTYKA ===")
    print("Mapa: " .. game.GetMap())
    print("Spawnpoint: " .. (spawnpoints and #spawnpoints or 0))
    print("RandomSpawns: " .. (randomspawns and #randomspawns or 0))
    print("info_player_start: " .. #ents.FindByClass("info_player_start"))
    print("NavMesh areas: " .. #navmesh.GetAllNavAreas())
    
    if spawnpoints and #spawnpoints > 0 then
        ply:ChatPrint("Pierwsze 5 spawnów:")
        for i = 1, math.min(5, #spawnpoints) do
            local sp = spawnpoints[i]
            ply:ChatPrint("  " .. i .. ": " .. tostring(sp.pos))
        end
    end
end)

concommand.Add("zb_clearspawns", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then 
        if IsValid(ply) then ply:ChatPrint("Tylko SuperAdmin!") end
        return 
    end
    
    zb.RemoveMapPoint("Spawnpoint", nil, true, true)
    zb.RemoveMapPoint("RandomSpawns", nil, true, true)
    ply:ChatPrint("Usunięto wszystkie spawn pointy!")
    print("[Z-CITY] " .. ply:Name() .. " usunął wszystkie spawn pointy.")
end)

concommand.Add("zb_regeneratespawns", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then 
        if IsValid(ply) then ply:ChatPrint("Brak uprawnień!") end
        return 
    end
    
    -- Wyczyść istniejące
    zb.Points["Spawnpoint"].Points = {}
    zb.Points["RandomSpawns"].Points = {}
    
    -- Wygeneruj nowe
    AutoCreateSpawnpoints()
    
    local count = #zb.GetMapPoints("Spawnpoint", true)
    ply:ChatPrint("Zregenerowano spawn pointy! Łącznie: " .. count)
end)

concommand.Add("zb_tpspawn", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local spawnNum = tonumber(args[1]) or 1
    local spawnpoints = zb.GetMapPoints("Spawnpoint", true)
    
    if not spawnpoints or #spawnpoints == 0 then
        ply:ChatPrint("Brak spawn pointów!")
        return
    end
    
    spawnNum = math.Clamp(spawnNum, 1, #spawnpoints)
    ply:SetPos(spawnpoints[spawnNum].pos)
    ply:ChatPrint("Teleportowano do spawna " .. spawnNum .. "/" .. #spawnpoints)
end)

-- Dodaj spawn od gracza automatycznie gdy admin chodzi po mapie
concommand.Add("zb_addspawnhere", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local pos = ply:GetPos()
    local isValid, adjustedPos = IsValidSpawnPosition(pos)
    
    if isValid then
        local ang = ply:EyeAngles()
        ang.x = 0
        ang.z = 0
        
        local pointData = {
            pos = adjustedPos or pos,
            ang = ang
        }
        
        zb.CreateMapPoint("Spawnpoint", pointData, true)
        zb.CreateMapPoint("RandomSpawns", pointData, true)
        
        ply:ChatPrint("Spawn dodany! (pozycja zweryfikowana)")
    else
        ply:ChatPrint("Ta pozycja nie jest odpowiednia na spawn!")
    end
end)

print("[Z-CITY] System spawn pointów załadowany (sv_points.lua)")