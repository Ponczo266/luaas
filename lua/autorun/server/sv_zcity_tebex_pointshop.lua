hg = hg or {}
hg.PointShop = hg.PointShop or hg.Pointshop or {}
hg.Pointshop = hg.PointShop

local function FindPlayerFinal(input)
    if not input then return nil end
    input = string.Replace(input, '"', "")
    input = string.Trim(input)

    for _, v in ipairs(player.GetAll()) do
        if v:SteamID() == input then return v end
        if v:SteamID64() == input then return v end
        if v:Nick() == input then return v end
    end
    return nil
end

local function SyncPointshopToClient(ply)
    local PS = hg.PointShop
    if not PS then return end

    -- jeśli masz nową wersję z pushem:
    if PS.PushPointShopVars then
        PS:PushPointShopVars(ply)
        return
    end

    -- stara wersja:
    if PS.NET_SendPointShopVars then
        PS:NET_SendPointShopVars(ply)
        return
    end
end

local function AddZP(ply, amount)
    amount = tonumber(amount)
    if not amount then return false, "Bad amount" end

    -- Preferowane (jeśli istnieje)
    if ply.PS_AddPoints then
        return ply:PS_AddPoints(amount)
    end

    -- Fallback: bez PS_AddPoints, ale z GetPointshopVars/PS_SetPoints
    if ply.GetPointshopVars then
        local vars = ply:GetPointshopVars()
        if vars then
            local newVal = (vars.points or 0) + amount
            if ply.PS_SetPoints then
                ply:PS_SetPoints(newVal)
            else
                vars.points = newVal -- awaryjnie tylko w RAM
            end
            return true
        end
    end

    -- Ostateczny fallback: bez metod na graczu, aktualizacja struktury punktshopa
    local PS = hg.PointShop
    PS.PlayerInstances = PS.PlayerInstances or {}
    local sid = ply:SteamID64()
    PS.PlayerInstances[sid] = PS.PlayerInstances[sid] or { donpoints = 0, points = 0, items = {} }
    PS.PlayerInstances[sid].points = (PS.PlayerInstances[sid].points or 0) + amount

    if mysql then
        local q = mysql:Update("hg_pointshop")
            q:Update("points", PS.PlayerInstances[sid].points)
            q:Where("steamid", sid)
        q:Execute()
    end

    return true
end

local function AddDZP(ply, amount)
    amount = tonumber(amount)
    if not amount then return false, "Bad amount" end

    if ply.PS_AddDPoints then
        return ply:PS_AddDPoints(amount)
    end

    if ply.GetPointshopVars then
        local vars = ply:GetPointshopVars()
        if vars then
            local newVal = (vars.donpoints or 0) + amount
            if ply.PS_SetDPoints then
                ply:PS_SetDPoints(newVal)
            else
                vars.donpoints = newVal
            end
            return true
        end
    end

    local PS = hg.PointShop
    PS.PlayerInstances = PS.PlayerInstances or {}
    local sid = ply:SteamID64()
    PS.PlayerInstances[sid] = PS.PlayerInstances[sid] or { donpoints = 0, points = 0, items = {} }
    PS.PlayerInstances[sid].donpoints = (PS.PlayerInstances[sid].donpoints or 0) + amount

    if mysql then
        local q = mysql:Update("hg_pointshop")
            q:Update("donpoints", PS.PlayerInstances[sid].donpoints)
            q:Where("steamid", sid)
        q:Execute()
    end

    return true
end

-- ZP
concommand.Add("zcity_tebex_add", function(ply, cmd, args)
    -- Tebex odpala z konsoli serwera -> ply = nil
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = FindPlayerFinal(args[1])
    local amount = tonumber(args[2])

    if not IsValid(target) or not amount then
        print("[TEBEX] ERROR: Nie znaleziono gracza lub zła ilość.")
        return
    end

    local ok, err = AddZP(target, amount)
    if not ok then
        print("[TEBEX] ERROR: " .. tostring(err))
        return
    end

    SyncPointshopToClient(target)
    print("[TEBEX] SUKCES: Dodano " .. amount .. " ZP dla " .. target:Nick())
end)

-- DZP
concommand.Add("zcity_tebex_add_premium", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local target = FindPlayerFinal(args[1])
    local amount = tonumber(args[2])

    if not IsValid(target) or not amount then
        print("[TEBEX] ERROR: Nie znaleziono gracza lub zła ilość.")
        return
    end

    local ok, err = AddDZP(target, amount)
    if not ok then
        print("[TEBEX] ERROR: " .. tostring(err))
        return
    end

    SyncPointshopToClient(target)
    print("[TEBEX] SUKCES: Dodano " .. amount .. " DZP dla " .. target:Nick())
end)