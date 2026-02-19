if not SERVER then return end

zb = zb or {}
zb.GuiltSQL = zb.GuiltSQL or {}
zb.GuiltSQL.PlayerInstances = zb.GuiltSQL.PlayerInstances or {}

local function CanUse(ply)
    -- konsola serwera: ply nie jest valid
    if not IsValid(ply) then return true end
    return ply:IsSuperAdmin()
end

local function ClampKarma(val)
    val = tonumber(val) or 100
    return math.Clamp(val, -60, zb.MaxKarma or 100)
end

local function ApplyToOnlinePlayer(ply, val)
    if not IsValid(ply) then return end
    ply.Karma = val
    if ply.SetNetVar then ply:SetNetVar("Karma", val) end
    if ply.guilt_SetValue then ply:guilt_SetValue(val) end
end

local function UpdateDBSteamID64(sid64, val)
    if not mysql then return false end
    if not sid64 or sid64 == "" then return false end

    -- update; jeśli rekord nie istnieje, wstaw
    local q = mysql:Update("zb_guilt")
        q:Update("value", val)
        q:Where("steamid", sid64)
    q:Execute()

    local ins = mysql:Insert("zb_guilt")
        ins:Insert("steamid", sid64)
        ins:Insert("steam_name", "Unknown")
        ins:Insert("value", val)
    -- część wrapperów ma Ignore/OnDuplicate; jeśli nie ma, insert może się nie udać gdy rekord istnieje
    -- więc robimy to bezpiecznie "po cichu"
    if ins.Ignore then ins:Ignore(true) end
    ins:Execute()

    return true
end

local function ParseSteamID64(str)
    if not isstring(str) then return nil end
    str = string.Trim(str)

    if str == "" then return nil end
    if string.match(str, "^%d+$") then return str end

    if string.StartWith(str, "STEAM_") then
        return util.SteamIDTo64(str)
    end

    return nil
end

-- hg_resetkarma_all [value]
concommand.Add("hg_resetkarma_all", function(ply, cmd, args)
    if not CanUse(ply) then return end

    local val = ClampKarma(args[1] or 100)

    -- DB: wszystkim, także offline
    if mysql then
        local q = mysql:Update("zb_guilt")
            q:Update("value", val)
        q:Execute()
    end

    -- online: natychmiast
    for _, p in ipairs(player.GetAll()) do
        ApplyToOnlinePlayer(p, val)

        local sid64 = p:SteamID64()
        zb.GuiltSQL.PlayerInstances[sid64] = zb.GuiltSQL.PlayerInstances[sid64] or {}
        zb.GuiltSQL.PlayerInstances[sid64].value = val
    end

    print(("[KARMA] hg_resetkarma_all -> ustawiono wszystkim %d"):format(val))
end)

-- hg_resetkarma <nick/steamid/steamid64> [value]
concommand.Add("hg_resetkarma", function(ply, cmd, args)
    if not CanUse(ply) then return end
    if not args[1] then
        print("[KARMA] Użycie: hg_resetkarma <nick/STEAMID/STEAMID64> [wartość]")
        return
    end

    local target = args[1]
    local val = ClampKarma(args[2] or 100)

    -- 1) spróbuj online po nicku
    local found = player.GetListByName and player.GetListByName(target)[1] or nil
    if IsValid(found) then
        ApplyToOnlinePlayer(found, val)

        local sid64 = found:SteamID64()
        zb.GuiltSQL.PlayerInstances[sid64] = zb.GuiltSQL.PlayerInstances[sid64] or {}
        zb.GuiltSQL.PlayerInstances[sid64].value = val

        print(("[KARMA] hg_resetkarma -> %s (%s) ustawiono na %d"):format(found:Name(), sid64, val))
        return
    end

    -- 2) offline po SteamID/SteamID64
    local sid64 = ParseSteamID64(target)
    if not sid64 then
        print("[KARMA] Nie znaleziono gracza online po nicku i nie rozpoznano SteamID/SteamID64.")
        return
    end

    if mysql then
        UpdateDBSteamID64(sid64, val)
        zb.GuiltSQL.PlayerInstances[sid64] = zb.GuiltSQL.PlayerInstances[sid64] or {}
        zb.GuiltSQL.PlayerInstances[sid64].value = val
        print(("[KARMA] hg_resetkarma -> %s (offline) ustawiono na %d w DB"):format(sid64, val))
    else
        print("[KARMA] Brak mysql – nie mogę ustawić karmy offline. (Ustawiłem tylko online, ale nikogo nie znaleziono.)")
    end
end)