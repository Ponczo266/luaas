zb = zb or {}
hg = hg or {}
zb.ROUND_STATE = zb.ROUND_STATE or 0
--0 = players can join, 1 = round is active, 2 = endround

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("loader.lua")
include("loader.lua")

local PLAYER = FindMetaTable("Player")
function PLAYER:CanSpawn()
	return ( CurrentRound and CurrentRound() and CurrentRound().CanSpawn and CurrentRound():CanSpawn(self)) or (zb.ROUND_STATE == 0)
end

util.AddNetworkString("ZB_SpectatePlayer")

function PLAYER:GiveEquipment(team_)
end

local default_spawns = {
	"info_player_deathmatch", "info_player_combine", "info_player_rebel",
	"info_player_counterterrorist", "info_player_terrorist", "info_player_axis",
	"info_player_allies", "gmod_player_start", "info_player_teamspawn",
	"ins_spawnpoint", "aoc_spawnpoint", "dys_spawn_point", "info_player_pirate",
	"info_player_viking", "info_player_knight", "diprip_start_team_blue", "diprip_start_team_red",
	"info_player_red", "info_player_blue", "info_player_coop", "info_player_human", "info_player_zombie",
	"info_player_zombiemaster", "info_player_fof", "info_player_desperado", "info_player_vigilante", "info_survivor_rescue"
}

local vecup = Vector(0, 0, 64)

local spawners = {}

-- ============================================
-- FIX: Naprawiona funkcja ładowania spawnów
-- ============================================
local function getRandSpawn()
	spawners = {}
	
	-- NAJPIERW ładuj spawny z entity mapy (info_player_start itp.)
	for i, ent in RandomPairs(ents.FindByClass("info_player_start")) do
		if IsValid(ent) then
			spawners[#spawners + 1] = ent:GetPos()
		end
	end
	
	-- Ładuj z innych typów spawn entity
	for i, str in ipairs(default_spawns) do
		for k, v in RandomPairs(ents.FindByClass(str)) do
			if IsValid(v) then
				spawners[#spawners + 1] = v:GetPos()
			end
		end
	end
	
	-- POTEM dodaj custom punkty z systemu zb.Points (jeśli są)
	if zb.GetMapPoints then
		local success, customPoints = pcall(function()
			return zb.GetMapPoints("Spawnpoint")
		end)
		
		if success and customPoints and type(customPoints) == "table" and #customPoints > 0 then
			for k, v in RandomPairs(customPoints) do
				if v and v.pos and isvector(v.pos) then
					spawners[#spawners + 1] = v.pos
				end
			end
		end
	end
	
	-- Usuń duplikaty (spawny które są bardzo blisko siebie)
	local uniqueSpawners = {}
	for i, pos in ipairs(spawners) do
		local isDuplicate = false
		for j, existingPos in ipairs(uniqueSpawners) do
			if pos:DistToSqr(existingPos) < 100 * 100 then -- 100 jednostek
				isDuplicate = true
				break
			end
		end
		if not isDuplicate then
			uniqueSpawners[#uniqueSpawners + 1] = pos
		end
	end
	spawners = uniqueSpawners
	
	print("[Z-CITY] Załadowano " .. #spawners .. " spawn pointów z mapy")
	
	-- Debug - pokaż pierwsze spawny
	if #spawners > 0 then
		for i = 1, math.min(3, #spawners) do
			print("[Z-CITY]   Spawn " .. i .. ": " .. tostring(spawners[i]))
		end
	else
		print("[Z-CITY] UWAGA: Brak spawn pointów!")
	end
end

getRandSpawn()

hook.Add("InitPostEntity", "OwOmooooove", function()
	timer.Simple(1, function()
		getRandSpawn()
	end)
end)

hook.Add("ZB_PreRoundStart", "reset_spawns", function()
	zb.ctspawn = nil
	zb.tspawn = nil
	
	-- Odśwież spawny przy każdej rundzie
	getRandSpawn()
end)

-- ============================================
-- FIX: Fallback spawn gdy wszystko inne zawiedzie
-- ============================================
function zb:GetFallbackSpawn()
	-- Najpierw sprawdź czy spawners nie jest pusty
	if spawners and #spawners > 0 then
		return spawners[math.random(#spawners)]
	end
	
	-- Szukaj jakiegokolwiek spawn entity na mapie
	local fallbackClasses = {
		"info_player_start",
		"info_player_deathmatch",
		"info_player_combine",
		"info_player_rebel",
		"info_player_counterterrorist",
		"info_player_terrorist",
	}
	
	for _, class in ipairs(fallbackClasses) do
		local ents_found = ents.FindByClass(class)
		if ents_found and #ents_found > 0 then
			local ent = ents_found[math.random(#ents_found)]
			if IsValid(ent) then
				return ent:GetPos()
			end
		end
	end
	
	-- Szukaj żywego gracza
	for _, ply in player.Iterator() do
		if ply:Alive() then
			return ply:GetPos() + Vector(math.random(-50, 50), math.random(-50, 50), 10)
		end
	end
	
	-- Absolutna ostateczność - szukaj jakiegokolwiek entity
	for _, ent in pairs(ents.GetAll()) do
		if IsValid(ent) and ent:GetPos() ~= Vector(0,0,0) then
			local pos = ent:GetPos()
			-- Sprawdź czy to nie jest w void
			local tr = util.TraceLine({
				start = pos + Vector(0, 0, 100),
				endpos = pos - Vector(0, 0, 100),
				mask = MASK_SOLID_BRUSHONLY
			})
			if tr.Hit and not tr.HitSky then
				return tr.HitPos + Vector(0, 0, 10)
			end
		end
	end
	
	print("[Z-CITY] KRYTYCZNY BŁĄD: Nie znaleziono żadnego spawna!")
	return Vector(0, 0, 100)
end

function zb:GetTeamSpawn(ply)
	local team_ = ply:Team()

	local team0spawns, team1spawns
	
	-- Bezpieczne wywołanie GetTeamSpawn
	if CurrentRound and CurrentRound() and CurrentRound().GetTeamSpawn then
		local success, t0, t1 = pcall(function()
			return CurrentRound():GetTeamSpawn()
		end)
		if success then
			team0spawns = t0
			team1spawns = t1
		end
	end
	
	-- FIX: Jeśli brak team spawnów, użyj losowych
	if not team0spawns or not next(team0spawns) then
		local randSpawn = zb:GetRandomSpawn()
		team0spawns = {randSpawn or zb:GetFallbackSpawn()}
	end

	if not team1spawns or not next(team1spawns) then
		local randSpawn = zb:GetRandomSpawn()
		team1spawns = {randSpawn or zb:GetFallbackSpawn()}
	end

	local pos
	
	if team_ == 0 then
		if not zb.tspawn then
			zb.tspawn = table.Random(team0spawns)
			pos = zb.tspawn
		else
			pos = hg.tpPlayer(zb.tspawn, ply, math.Clamp(ply:EntIndex() % 24 + 1, 1, 24), 0)
		end

		-- FIX: Zawsze zwróć coś
		if not pos or not isvector(pos) then
			pos = zb:GetFallbackSpawn()
		end
		return pos
	else
		if not zb.ctspawn then
			zb.ctspawn = table.Random(team1spawns)
			pos = zb.ctspawn
		else
			pos = hg.tpPlayer(zb.ctspawn, ply, math.Clamp(ply:EntIndex() % 24 + 1, 1, 24), 0)
		end

		-- FIX: Zawsze zwróć coś
		if not pos or not isvector(pos) then
			pos = zb:GetFallbackSpawn()
		end
		return pos
	end

	ErrorNoHalt("TEAM SPAWN COULDN'T BE FOUND. INVALID TEAM")
	return zb:GetFallbackSpawn()
end

local check_playerspawns = function(SpawnPos, ply, tolerance)
	if not IsValid(ply) then return true end
	if not ply:Alive() then return true end
	
	local usedPos = ply:GetPos()

	local checkdist = (1024 / (math.pow(2, tolerance)))
	if usedPos:DistToSqr(SpawnPos) < checkdist * checkdist then
		return false
	end
	
	return true
end

function zb:GetRandomSpawn(target, spawns)
	-- Użyj podanych spawnów lub globalnych
	if not spawns or table.IsEmpty(spawns) then
		spawns = spawners
	end
	
	-- FIX: Jeśli nadal puste, przeładuj spawny
	if not spawns or #spawns == 0 then
		getRandSpawn()
		spawns = spawners
	end
	
	-- FIX: Jeśli nadal puste, użyj fallback
	if not spawns or #spawns == 0 then
		return zb:GetFallbackSpawn()
	end
	
	local result = zb:FurthestFromEveryone(spawns, player.GetAll(), check_playerspawns)
	
	-- FIX: Sprawdź wynik
	if not result or not isvector(result) then
		return zb:GetFallbackSpawn()
	end
	
	return result
end

function zb:FurthestFromEveryone(chooseTbl, restrictTbl, func, iStart, iEnd)
	-- FIX: Sprawdź czy chooseTbl jest poprawne
	if not chooseTbl or type(chooseTbl) ~= "table" or #chooseTbl == 0 then
		chooseTbl = spawners
	end
	
	-- FIX: Jeśli nadal puste, zwróć fallback
	if not chooseTbl or #chooseTbl == 0 then
		return zb:GetFallbackSpawn()
	end

	if not restrictTbl then
		restrictTbl = player.GetAll()
		func = check_playerspawns
	end
	
	-- Szukaj spawna najdalej od graczy
	for tolerance = (iStart or 1), (iEnd or 5) do
		for i, SpawnPos in RandomPairs(chooseTbl) do
			if not SpawnPos or not isvector(SpawnPos) then continue end
			
			local allow = true

			for _, value in ipairs(restrictTbl) do
				if IsValid(value) then
					allow = func(SpawnPos, value, tolerance)
					if allow == false then break end
				end
			end
			
			if allow then
				return SpawnPos
			end
		end
	end
	
	-- Jeśli nie znaleziono, zwróć losowy spawn
	local SpawnPos = table.Random(chooseTbl)
	
	-- FIX: Sprawdź czy nie nil
	if not SpawnPos or not isvector(SpawnPos) then
		return zb:GetFallbackSpawn()
	end
	
	return SpawnPos
end

function PLAYER:GetRandomSpawn()
	local spawnPos = zb:GetRandomSpawn(self)
	
	-- FIX: Zawsze ustaw pozycję
	if not spawnPos or not isvector(spawnPos) then
		spawnPos = zb:GetFallbackSpawn()
	end
	
	if spawnPos and isvector(spawnPos) then
		self:SetPos(spawnPos)
	end
end

function GM:PlayerSelectSpawn(ply, transition)
end

-- ============================================
-- FIX: Główna funkcja spawnu gracza
-- ============================================
local function PlayerSelectSpawn(ply, transition)
	if not IsValid(ply) then return end
	
	local spawnPos = nil
	
	-- Sprawdź czy tryb używa losowych spawnów
	local useRandomSpawns = false
	if CurrentRound and CurrentRound() then
		useRandomSpawns = CurrentRound().randomSpawns
	end
	
	if useRandomSpawns then
		spawnPos = zb:GetRandomSpawn()
	else
		spawnPos = zb:GetTeamSpawn(ply)
		
		if not spawnPos or not isvector(spawnPos) then
			spawnPos = zb:GetRandomSpawn()
		end
	end
	
	-- FIX: Ostateczna ochrona przed nil
	if not spawnPos or not isvector(spawnPos) then
		spawnPos = zb:GetFallbackSpawn()
		print("[Z-CITY] UWAGA: Użyto fallback spawn dla " .. ply:Name())
	end
	
	-- Ustaw pozycję gracza
	if spawnPos and isvector(spawnPos) then
		ply:SetPos(spawnPos)
	else
		print("[Z-CITY] BŁĄD KRYTYCZNY: Nie można ustawić pozycji dla " .. ply:Name())
		ply:SetPos(Vector(0, 0, 100))
	end
end

function PLAYER:SetupTeam(team_)
	self:SetTeam(team_)
	
	hg.CreateInv(self)

	PlayerSelectSpawn(self)
end

function GM:PlayerSpawn(ply)
    ply:SuppressHint("OpeningMenu")
    ply:SuppressHint("Annoy1")
    ply:SuppressHint("Annoy2")

    if OverrideSpawn then return end

    ply.viewmode = 3
    ply:UnSpectate()
    ply:SetMoveType(MOVETYPE_WALK)

    if ply.initialspawn then
        ply:KillSilent()
        ply:SetTeam(1001)
        ply.initialspawn = nil
        return
    end

    if CurrentRound() and not CurrentRound().OverrideSpawn then
        ply:SetTeam(1001)
        ApplyAppearance(ply,nil,nil,nil,true)
        ply:SetTeam(zb:BalancedChoice(0, 1))
    end
end

function GM:PlayerDisconnected()
end

RunConsoleCommand("mp_show_voice_icons", "0")

local hullscale = Vector(1, 1, 1)

util.AddNetworkString("ZB_ChooseSpecPly")

net.Receive("ZB_ChooseSpecPly",function(len,ply)
	if ply:Alive() then return end
	
	local key = net.ReadInt(32)
	local tbl = zb:CheckAlive()
	
	if #tbl == 0 then return end
	
	ply.chosenspect = ply.chosenspect and isnumber(ply.chosenspect) and ply.chosenspect or 1
	ply.viewmode = ply.viewmode or 1
	
	ply.chosenspect = math.Clamp(ply.chosenspect, 1, #tbl)
	
	if key == IN_ATTACK then
		ply.chosenspect = ply.chosenspect + 1
		if ply.chosenspect > #tbl then ply.chosenspect = 1 end
		
		net.Start("ZB_SpectatePlayer")
		net.WriteEntity(tbl[ply.chosenspect] or NULL)
		net.WriteEntity(tbl[ply.chosenspect == 1 and #tbl or ply.chosenspect - 1] or NULL)
		net.WriteInt(ply.viewmode, 4)
		net.Send(ply)
	end

	if key == IN_ATTACK2 then
		ply.chosenspect = ply.chosenspect - 1
		if ply.chosenspect < 1 then ply.chosenspect = #tbl end
		
		net.Start("ZB_SpectatePlayer")
		net.WriteEntity(tbl[ply.chosenspect] or NULL)
		net.WriteEntity(tbl[ply.chosenspect == #tbl and 1 or ply.chosenspect + 1] or NULL)
		net.WriteInt(ply.viewmode, 4)
		net.Send(ply)
	end

	if key == IN_RELOAD then
		ply.viewmode = (ply.viewmode % 3) + 1  
		
		net.Start("ZB_SpectatePlayer")
		net.WriteEntity(tbl[ply.chosenspect] or NULL)
		net.WriteEntity(tbl[ply.chosenspect == 1 and #tbl or ply.chosenspect - 1] or NULL)
		net.WriteInt(ply.viewmode, 4)
		net.Send(ply)
	end
	
	ply.chosenspect = math.Clamp(ply.chosenspect, 1, #tbl)
	ply.chosenSpectEntity = tbl[ply.chosenspect]
	
	if ply.lastSpectTarget ~= ply.chosenSpectEntity then
		ply.lastSpectTarget = ply.chosenSpectEntity
	end
end)

hook.Add("SetupPlayerVisibility", "spectPVS", function(ply, viewent)
	if ply:Alive() then return end

	local entity = ply.chosenSpectEntity

	if IsValid(entity) and not entity:TestPVS(ply) then
		AddOriginToPVS(entity:GetPos())
	end
end)

hook.Add("PlayerDeathThink", "spectNetwork", function(ply)
	if ply:Alive() then return end

	local ent = ply.chosenSpectEntity or player.GetAll()[1]
	if IsValid(ply) then
		ply:SetNWEntity("spect", ent)
		ply:SetNWInt("viewmode", ply.viewmode or 1)
		if IsValid(ent) then
			if ent.organism and ply.viewmode == 1 then
				if (ply.netsendtime or 0) < CurTime() then
					ply.netsendtime = CurTime() + 1

					hg.send_organism(ent.organism, ply)
				end
			end
			local entr = hg.GetCurrentCharacter(ent)
			local pos = ent:GetPos()
			
			if ply.viewmode ~= 3 then
				local currentPos = ply:GetPos()
				local targetPos = pos
				local distance = currentPos:Distance(targetPos)
				
				if distance > 100 or ply.lastSpectTarget ~= ent then
					ply:SetPos(targetPos)
					ply.lastSpectTarget = ent
				end
			end
		end
		
		if ply.viewmode == 3 then
			if ply:GetMoveType() ~= MOVETYPE_NOCLIP then
				ply:SetMoveType(MOVETYPE_NOCLIP)
			end
			if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
				ply:Spectate(OBS_MODE_ROAMING)
			end
		else
			if ply:GetMoveType() == MOVETYPE_NOCLIP then
				ply:SetMoveType(MOVETYPE_WALK)
			end
		end
	end
end)

function GM:PlayerDeathThink(ply)
	if not ply:CanSpawn() then return false end
end

function GM:PlayerDeath(ply)
	ply.lastSpectTarget = nil
	ply.chosenSpectEntity = nil
	
	ply:Spectate(OBS_MODE_ROAMING)
	ply:SetHull(-hullscale,hullscale)
	ply:SetHullDuck(-hullscale,hullscale)
	
	ply.chosenspect = ply:EntIndex()
	ply.viewmode = 1 
	
	timer.Simple(0.1, function()
		if IsValid(ply) and not ply:Alive() then
			local alivePlayers = zb:CheckAlive()
			if #alivePlayers > 0 then
				ply.chosenSpectEntity = alivePlayers[1]
				ply.chosenspect = 1
			end
		end
	end)
end

hg.addbot = hg.addbot or false

function GM:PlayerInitialSpawn(ply)
	ply.initialspawn = true

	if #player.GetAll() == 1 then
		RunConsoleCommand("bot")
		hg.addbot = true
		zb:EndRound()
	end

	if #player.GetHumans() > 1 and hg.addbot then
		for i,bot in pairs(player.GetListByName("bot")) do
			RunConsoleCommand("kick",bot:Name())
		end
		hg.addbot = false
	end
end

function GM:IsSpawnpointSuitable( pl, spawnpointent, bMakeSuitable )
	return true
end

util.AddNetworkString("ZB_SpecMode")
net.Receive("ZB_SpecMode",function(len,ply)
	local bool = net.ReadBool()

	local enable = not hook.Run("ZB_JoinSpectators", ply)

	if enable and bool and ply:Team() ~= TEAM_SPECTATOR then 
		if ply:Alive() then ply:Kill() end 
		ply:SetTeam(TEAM_SPECTATOR) 
		PrintMessage(HUD_PRINTTALK, ply:Name() .. " joined the spectators.") 
	elseif ply:Team() ~= 1 then
		ply:SetTeam(1) 
		PrintMessage(HUD_PRINTTALK, ply:Name() .. " joined the players.")  
	end
end)

util.AddNetworkString("updtime")

function hg.UpdateRoundTime(time, time2, time3)
	zb.ROUND_TIME = time or zb.ROUND_TIME
	zb.ROUND_START = time2 or zb.ROUND_START or CurTime()
	zb.ROUND_BEGIN = time3 or zb.ROUND_BEGIN or CurTime() + 5
	net.Start("updtime")
	net.WriteFloat(zb.ROUND_TIME)
	net.WriteFloat(zb.ROUND_START)
	net.WriteFloat(zb.ROUND_BEGIN)
	net.Broadcast()
end

local function getspawnpos()
    local tab = {}
    local tbl = ents.FindByClass("info_player_start")
    for k, v in pairs(tbl) do
        if not v:HasSpawnFlags(1) then continue end
        tab[#tab + 1] = v:GetPos()
    end
    
    -- FIX: Bezpieczne zwracanie
    if tab[1] then
        return tab[1]
    elseif tbl[1] and IsValid(tbl[1]) then
        return tbl[1]:GetPos()
    else
        return zb:GetFallbackSpawn()
    end
end

local maps = {}

hook.Add("PostCleanupMap","changelevel_generate",function()
	-- Odśwież spawny po wyczyszczeniu mapy
	timer.Simple(0.5, function()
		getRandSpawn()
	end)
	
	if not CurrentRound() or CurrentRound().name ~= "coop" then return end
	
	local player_pos = getspawnpos()
    local dist = 0
    local map
    
    local maps = {}
    for i, map in pairs(ents.FindByClass("trigger_changelevel")) do
        local min, max = map:WorldSpaceAABB()
        local tdmlPos = max - ((max - min) / 2)

        maps[map] = tdmlPos
    end
    
    for ent, pos in pairs(maps) do
		if ent.map == game.GetMap() then continue end
        local dist2 = pos:Distance(player_pos)
        if dist2 > dist then
            dist = dist2
            map = ent
        end
    end

    if not IsValid(map) then 
		local randomMap = table.Random(maps)
		if randomMap then
			map = select(2, randomMap)
		end
	end
    
	if not map then return end
	
    print("Next map is: " .. (map.map or "unknown"))

    local min, max = map:WorldSpaceAABB()
    local tdmlPos = max - ((max - min) / 2)
    local tdml = ents.Create("coop_mapend")
    tdml:SetPos(tdmlPos)
	tdml:SetAngles(map:GetAngles())
    tdml.min = min
    tdml.max = max
    tdml.map = map.map
    tdml:Spawn()
    tdml:Activate()
end)

function GM:EntityKeyValue( ent, key, value )

	if ( ( ent:GetClass() == "trigger_changelevel" ) and ( key == "map" ) ) then
		ent.map = value
		ent:AddEFlags(2)
		ent:AddFlags(2)
	end

	if ( ent:GetClass() == "npc_combine_s" ) then
		ent:SetLagCompensated(true)
	end

	if ( ( ent:GetClass() == "npc_combine_s" ) and ( key == "additionalequipment" ) and ( value == "weapon_shotgun" ) ) then
		ent:SetSkin( 1 )
	end

end

hook.Add("CanProperty", "AntiExploit", function(ply, property, ent)
	if not ply:IsAdmin() then
		return false
	end
end)

-- ============================================
-- FIX: Komendy diagnostyczne
-- ============================================

concommand.Add("zb_debugspawns", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	print("=== SPAWN DEBUG ===")
	print("Spawners count: " .. #spawners)
	print("info_player_start: " .. #ents.FindByClass("info_player_start"))
	print("info_player_deathmatch: " .. #ents.FindByClass("info_player_deathmatch"))
	print("info_player_combine: " .. #ents.FindByClass("info_player_combine"))
	print("info_player_rebel: " .. #ents.FindByClass("info_player_rebel"))
	print("info_player_terrorist: " .. #ents.FindByClass("info_player_terrorist"))
	print("info_player_counterterrorist: " .. #ents.FindByClass("info_player_counterterrorist"))
	
	ply:ChatPrint("=== SPAWN DEBUG ===")
	ply:ChatPrint("Spawners: " .. #spawners)
	ply:ChatPrint("info_player_start: " .. #ents.FindByClass("info_player_start"))
	
	if #spawners > 0 then
		ply:ChatPrint("Pierwsze 5 spawnów:")
		for i = 1, math.min(5, #spawners) do
			ply:ChatPrint("  " .. i .. ": " .. tostring(spawners[i]))
			print("  Spawn " .. i .. ": " .. tostring(spawners[i]))
		end
	end
end)

concommand.Add("zb_reloadspawns", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	getRandSpawn()
	ply:ChatPrint("Przeładowano spawny! Znaleziono: " .. #spawners)
end)

concommand.Add("zb_tptospawn", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local spawnNum = tonumber(args[1]) or 1
	
	if #spawners == 0 then
		ply:ChatPrint("Brak spawnów!")
		return
	end
	
	spawnNum = math.Clamp(spawnNum, 1, #spawners)
	ply:SetPos(spawners[spawnNum])
	ply:ChatPrint("Teleportowano do spawna " .. spawnNum .. "/" .. #spawners)
end)

print("[Z-CITY] init.lua załadowany - system spawnów naprawiony")