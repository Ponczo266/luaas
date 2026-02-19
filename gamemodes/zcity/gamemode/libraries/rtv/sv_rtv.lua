util.AddNetworkString("ZB_RockTheVote_start")
util.AddNetworkString("ZB_RockTheVote_vote")
util.AddNetworkString("ZB_RockTheVote_voteCLreg")
util.AddNetworkString("ZB_RockTheVote_end")
util.AddNetworkString("RTVMenu")

zb = zb or {}
zb.votestarted  = zb.votestarted or false
zb.rtvtime      = zb.rtvtime or 0
zb.currentMaps  = zb.currentMaps or {}

local cooldown         = {}
local votes            = {}
local playervote       = {}
local playerVoteWeight = {}
local mappull          = {}
local endStarted       = false
local rtvVotes         = {}
local rtvTimeout       = nil

local RTV_REQUIRED_PERCENT = 0.51
local RTV_MIN_PLAYERS      = 2

function zb.ClearRTVVotes()
    rtvVotes   = {}
    endStarted = false
    if rtvTimeout then
        timer.Remove("RTVTimeout")
        rtvTimeout = nil
    end
end

function zb.CheckRTVVotes(needPrint)
    local totalPlayers = #player.GetAll()
    local needed = math.max(RTV_MIN_PLAYERS, math.ceil(totalPlayers * RTV_REQUIRED_PERCENT))
    local count  = table.Count(rtvVotes)

    if count >= needed then
        if needPrint then
            for _, v in player.Iterator() do
                v:ChatPrint("Wystarczająco głosów za zmianą mapy. RTV rozpocznie się w następnej rundzie.")
            end
        end
        return true
    end
    return false
end

local function GetMapFamily(map)
    if string.find(string.lower(map), "smalltown") then
        return "smalltown"
    end
    return nil
end

local function GetFamilyMaps(family)
    local familyMaps = {}
    for _, map in ipairs(mappull) do
        if GetMapFamily(map) == family then
            table.insert(familyMaps, map)
        end
    end
    return familyMaps
end

local blacklist = {
    ["gm_construct"] = true, ["gm_flatgrass"] = true,
    ["gm_altarskforest"] = true, ["gm_renostruct_v2"] = true,
    ["gm_renostruct_v2_night"] = true, ["gm_city_of_silence"] = true,
    ["ttt_hogwarts"] = true,
}

local allowedPrefix = {
    ["ttt"] = true,  ["hmcd"] = true, ["mu"]  = true,  ["ze"]  = false,
    ["zs"]  = true,  ["tdm"]  = true, ["zb"]  = false, ["zbattle"] = false,
    ["gm"]  = true,  ["ph"]   = true, ["cs"]  = true,  ["de"]  = true,
    ["rp"]  = true,  ["aim"]  = true, ["awp"] = true,  ["fy"]  = true,
    ["surf"] = true, ["bhop"] = true,
}

local prefixWeights = {
    ["ttt"] = 18, ["hmcd"] = 19, ["mu"]  = 18, ["ze"]  = 0,
    ["zs"]  = 9,  ["tdm"]  = 5,  ["zb"]  = 0,  ["zbattle"] = 0,
    ["gm"]  = 20, ["ph"]   = 11, ["cs"]  = 5,  ["de"]  = 5,
    ["rp"]  = 15, ["aim"]  = 5,  ["awp"] = 5,  ["fy"]  = 5,
    ["surf"] = 5, ["bhop"] = 5,
}

local function GetSafeServerName()
    local hostname = GetConVar("hostname"):GetString() or "unknown"
    hostname = hostname:gsub("[^%w_-]", "_"):sub(1, 20)
    return hostname
end

local function GetDataPath(fileName)
    return "zbattle/" .. GetSafeServerName() .. "/" .. fileName
end

local function EnsureDataDirectory()
    local serverName = GetSafeServerName()
    if not file.Exists("zbattle", "DATA") then
        file.CreateDir("zbattle")
    end
    if not file.Exists("zbattle/" .. serverName, "DATA") then
        file.CreateDir("zbattle/" .. serverName)
    end
end

EnsureDataDirectory()

local mapPopularity  = {}
local popularityPath = GetDataPath("MapPopularity.json")
if file.Exists(popularityPath, "DATA") then
    mapPopularity = util.JSONToTable(file.Read(popularityPath, "DATA")) or {}
end

local function getmaps()
    table.Empty(mappull)
    local found = file.Find("maps/*.bsp", "GAME")
    for _, map in ipairs(found) do
        map = map:sub(1, -5)
        local mapstr = map:Split("_")
        if (allowedPrefix[mapstr[1]] or mapstr[1]) and not blacklist[map] then
            table.insert(mappull, map)
        end
    end
end

local function getWeightedRandomMapPrefix()
    local totalWeight = 0
    for _, weight in pairs(prefixWeights) do
        totalWeight = totalWeight + weight
    end
    local randomWeight = math.random() * totalWeight
    for prefix, weight in pairs(prefixWeights) do
        if randomWeight < weight then return prefix end
        randomWeight = randomWeight - weight
    end
    return "gm"
end

local function getMapsByPrefix(prefix)
    local out = {}
    for _, map in ipairs(mappull) do
        if map:StartWith(prefix) then table.insert(out, map) end
    end
    return out
end

hook.Add("InitPostEntity", "zb_GetMaps", function()
    zb.votestarted = false
    getmaps()
end)

net.Receive("ZB_RockTheVote_vote", function(len, ply)
    if not zb.votestarted then return end
    if cooldown[ply:EntIndex()] and cooldown[ply:EntIndex()] > CurTime() then return end

    cooldown[ply:EntIndex()] = CurTime() + 1
    local playerIdx = ply:EntIndex()

    if playervote[playerIdx] and votes[playervote[playerIdx]] then
        votes[playervote[playerIdx]] = votes[playervote[playerIdx]]
            - (playerVoteWeight[playerIdx] or 1)
    end

    local map = net.ReadString()
    if not map or map == "" then return end
    if map ~= "random" and not table.HasValue(mappull, map) then return end

    playervote[playerIdx]       = map
    playerVoteWeight[playerIdx] = 1
    votes[map] = (votes[map] or 0) + playerVoteWeight[playerIdx]

    net.Start("ZB_RockTheVote_voteCLreg")
        net.WriteTable(votes)
    net.Broadcast()
end)

function zb.EndRTV()
    if endStarted then return end

    local winmap = table.GetWinningKey(votes)

    if not winmap then
        if zb.currentMaps and #zb.currentMaps > 0 then
            local pool = {}
            for _, m in ipairs(zb.currentMaps) do
                if m ~= "random" then table.insert(pool, m) end
            end
            if #pool > 0 then
                winmap = pool[math.random(#pool)]
            end
        end
        if not winmap then
            winmap = mappull[math.random(#mappull)]
        end
    end

    if winmap == "random" then
        winmap = mappull[math.random(#mappull)]
    end
    if not winmap then winmap = game.GetMap() end

    local mapFamily = GetMapFamily(winmap)
    mapPopularity[winmap] = math.min((mapPopularity[winmap] or 0) + 5, 100)

    local PlayedMaps     = {}
    local playedMapsPath = GetDataPath("PlayedMaps.json")
    if file.Exists(playedMapsPath, "DATA") then
        PlayedMaps = util.JSONToTable(file.Read(playedMapsPath, "DATA")) or {}
    end

    if not table.HasValue(PlayedMaps, winmap) then
        table.insert(PlayedMaps, 1, winmap)
        if mapFamily then
            local familyMaps = GetFamilyMaps(mapFamily)
            for _, familyMap in ipairs(familyMaps) do
                if familyMap ~= winmap and not table.HasValue(PlayedMaps, familyMap) then
                    table.insert(PlayedMaps, 1, familyMap)
                    mapPopularity[familyMap] = math.min((mapPopularity[familyMap] or 0) + 5, 100)
                end
            end
        end
        if #PlayedMaps > 2 then
            local newPlayed = {}
            for i = 1, 2 do
                if PlayedMaps[i] then table.insert(newPlayed, PlayedMaps[i]) end
            end
            PlayedMaps = newPlayed
        end
        file.Write(playedMapsPath, util.TableToJSON(PlayedMaps))
    end

    for map, pop in pairs(mapPopularity) do
        if map ~= winmap and not table.HasValue(PlayedMaps, map) then
            mapPopularity[map] = math.max(pop - 2, 0)
        end
    end
    file.Write(popularityPath, util.TableToJSON(mapPopularity))

    net.Start("ZB_RockTheVote_end")
        net.WriteString(winmap)
    net.Broadcast()

    endStarted = true

    timer.Simple(3, function()
        table.Empty(votes)
        table.Empty(playervote)
        table.Empty(playerVoteWeight)
        zb.votestarted = false
        zb.ClearRTVVotes()
        RunConsoleCommand("changelevel", winmap)
    end)
end

function zb.ThinkRTV()
    if not zb.votestarted then return end
    if zb.rtvtime < CurTime() then
        zb.EndRTV()
    end
end

local function getUniquePrefixes(playedMaps)
    local chosen, attempts = {}, 0
    while #chosen < 3 do
        local prefix = getWeightedRandomMapPrefix()
        if prefix and not table.HasValue(chosen, prefix) then
            local prefixMaps = getMapsByPrefix(prefix)
            local validCount = 0
            for _, m in ipairs(prefixMaps) do
                if not table.HasValue(playedMaps, m) then
                    validCount = validCount + 1
                end
            end
            if validCount >= 1 then
                table.insert(chosen, prefix)
            end
        end
        attempts = attempts + 1
        if attempts > 300 then break end
    end
    return chosen
end

local function getMapWeight(map)
    local pop = mapPopularity[map] or 0
    return 1 - (pop / 100)
end

function zb.StartRTV(time)
    if zb.votestarted then return end

    getmaps()
    zb.rtvtime = CurTime() + (time or 45)

    local PlayedMaps     = {}
    local playedMapsPath = GetDataPath("PlayedMaps.json")
    if file.Exists(playedMapsPath, "DATA") then
        PlayedMaps = util.JSONToTable(file.Read(playedMapsPath, "DATA"))
    end
    if not PlayedMaps then PlayedMaps = {} end

    local selectedPrefixes = getUniquePrefixes(PlayedMaps)

    if #selectedPrefixes < 3 then
        local possible = {}
        for prefix, weight in pairs(prefixWeights) do
            if weight > 0 then
                local prefixMaps = getMapsByPrefix(prefix)
                local validCount = 0
                for _, m in ipairs(prefixMaps) do
                    if not table.HasValue(PlayedMaps, m) then
                        validCount = validCount + 1
                    end
                end
                if validCount >= 1 then
                    table.insert(possible, prefix)
                end
            end
        end
        selectedPrefixes = {}
        for i = 1, 3 do
            if possible[i] then table.insert(selectedPrefixes, possible[i]) end
        end
    end
    if #selectedPrefixes == 0 then selectedPrefixes = {"gm"} end

    local finalmaps = {}
    for _, prefix in ipairs(selectedPrefixes) do
        local prefixMaps = getMapsByPrefix(prefix)
        local validMaps  = {}
        for _, m in ipairs(prefixMaps) do
            if not table.HasValue(PlayedMaps, m) then
                table.insert(validMaps, m)
            end
        end
        for i = 1, 4 do
            if #validMaps == 0 then break end
            local totalWeight = 0
            for _, m in ipairs(validMaps) do
                totalWeight = totalWeight + getMapWeight(m)
            end
            local rnd = math.random() * totalWeight
            local selectedIndex
            for idx, m in ipairs(validMaps) do
                local weight = getMapWeight(m)
                if rnd < weight then selectedIndex = idx; break
                else rnd = rnd - weight end
            end
            if not selectedIndex then selectedIndex = math.random(#validMaps) end
            if selectedIndex and validMaps[selectedIndex] then
                table.insert(finalmaps, validMaps[selectedIndex])
                table.remove(validMaps, selectedIndex)
            end
        end
    end

    if #finalmaps < 12 then
        local fallback = table.Copy(mappull)
        local filtered = {}
        for _, m in ipairs(fallback) do
            if not table.HasValue(PlayedMaps, m)
               and not table.HasValue(finalmaps, m) then
                table.insert(filtered, m)
            end
        end
        if #filtered == 0 then
            for _, m in ipairs(fallback) do
                if not table.HasValue(finalmaps, m) then
                    table.insert(filtered, m)
                end
            end
        end
        local att = 0
        while #finalmaps < 12 and #filtered > 0 do
            att = att + 1
            if att > 300 then break end
            local idx = math.random(#filtered)
            table.insert(finalmaps, filtered[idx])
            table.remove(filtered, idx)
        end
    end

    if #finalmaps == 0 then
        local rndMap = mappull[math.random(#mappull)]
        if rndMap then table.insert(finalmaps, rndMap) end
    end

    table.insert(finalmaps, "random")

    zb.currentMaps = finalmaps

    net.Start("ZB_RockTheVote_start")
        net.WriteTable(finalmaps)
        net.WriteFloat(zb.rtvtime)
    net.Broadcast()

    zb.votestarted = true
    endStarted     = false

    hook.Add("Think", "RTVThink", zb.ThinkRTV)
end

function zb.RTVMenu(ply)
    net.Start("RTVMenu")
        net.WriteTable(zb.currentMaps or {})
        net.WriteFloat(zb.rtvtime or 0)
        net.WriteTable(votes)
    net.Send(ply)
end

COMMANDS.forcertv = {function(ply, args)
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("Tylko Super Admini mogą wymusić głosowanie.")
        return
    end
    if zb.votestarted then
        ply:ChatPrint("Głosowanie już trwa!")
        return
    end

    local dur = math.Clamp(tonumber(args[1]) or 30, 10, 120)

    for _, v in player.Iterator() do
        v:ChatPrint("[ADMIN] " .. ply:Nick() .. " wymusił głosowanie na mapę! (" .. dur .. "s)")
    end

    zb.StartRTV(dur)
end, 0}

COMMANDS.forcemap = {function(ply, args)
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("Tylko Super Admini mogą wymusić zmianę mapy.")
        return
    end

    local query = args[1]
    if not query or query == "" then
        ply:ChatPrint("Użycie: !forcemap <nazwa_mapy>")
        return
    end

    local allBsp = file.Find("maps/*.bsp", "GAME")
    local found

    for _, f in ipairs(allBsp) do
        local name = f:sub(1, -5)
        if name == query then found = name; break end
    end

    if not found then
        for _, f in ipairs(allBsp) do
            local name = f:sub(1, -5)
            if string.find(name, query, 1, true) then
                found = name; break
            end
        end
    end

    if not found then
        ply:ChatPrint("Nie znaleziono mapy: " .. query)
        return
    end

    for _, v in player.Iterator() do
        v:ChatPrint("[ADMIN] " .. ply:Nick() .. " zmienia mapę na: " .. found)
    end

    timer.Simple(3, function()
        RunConsoleCommand("changelevel", found)
    end)
end, 0}

COMMANDS.endvote = {function(ply, args)
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("Tylko Super Admini mogą zakończyć głosowanie.")
        return
    end
    if not zb.votestarted then
        ply:ChatPrint("Żadne głosowanie nie trwa.")
        return
    end

    for _, v in player.Iterator() do
        v:ChatPrint("[ADMIN] " .. ply:Nick() .. " zakończył głosowanie wcześniej.")
    end

    zb.EndRTV()
end, 0}

COMMANDS.rtv = {function(ply, args)
    if zb.votestarted then
        zb.RTVMenu(ply)
        return
    end

    local totalPlayers = #player.GetAll()

    if totalPlayers < RTV_MIN_PLAYERS then
        ply:ChatPrint("Za mało graczy na serwerze! Potrzeba minimum " .. RTV_MIN_PLAYERS .. " graczy.")
        return
    end

    local needed = math.max(RTV_MIN_PLAYERS, math.ceil(totalPlayers * RTV_REQUIRED_PERCENT))
    local sid    = ply:SteamID()

    if rtvVotes[sid] then
        rtvVotes[sid] = nil
        local count     = table.Count(rtvVotes)
        local remaining = needed - count
        ply:ChatPrint("Anulowałeś swój głos na zmianę mapy. Potrzeba jeszcze " .. remaining .. " głosów.")
        return
    end

    rtvVotes[sid] = true

    local count     = table.Count(rtvVotes)
    local remaining = needed - count

    if remaining > 0 then
        for _, v in player.Iterator() do
            v:ChatPrint(
                ply:Nick() .. " zagłosował za zmianą mapy. ["
                .. count .. "/" .. needed .. "] "
                .. "Potrzeba jeszcze " .. remaining .. ". (!rtv żeby anulować)"
            )
        end
    end

    if zb.CheckRTVVotes(true) then
        return
    end
end, 0}

hook.Add("ShutDown",            "ResetRTVVotesOnMapChange", zb.ClearRTVVotes)
hook.Add("PostGamemodeLoaded",  "InitializeRTVSystem",      function() zb.ClearRTVVotes() end)
hook.Add("PlayerDisconnected",  "CheckRTVAfterDisconnect",  function(ply)
    if rtvVotes[ply:SteamID()] then
        rtvVotes[ply:SteamID()] = nil
        timer.Simple(0.1, zb.CheckRTVVotes)
    end
end)