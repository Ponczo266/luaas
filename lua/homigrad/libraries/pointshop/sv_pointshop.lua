hg = hg or {}
hg.PointShop = hg.PointShop or hg.Pointshop or {}
hg.Pointshop = hg.PointShop -- alias wsteczny

local PLUGIN = hg.PointShop
PLUGIN.PlayerInstances = PLUGIN.PlayerInstances or {}

-- ==========================================
-- KONFIGURACJA Z-CITY
-- ==========================================
local POINTS_AMOUNT = 1
local POINTS_INTERVAL = 60
local ADMINS_GET_POINTS = true
-- ==========================================

-- NETY
util.AddNetworkString("hg_pointshop_net")          -- request/response (callback)
util.AddNetworkString("hg_pointshop_vars")         -- push bez callbacków
util.AddNetworkString("hg_pointshop_send_notificate")

-- 1. ŁADOWANIE BAZY DANYCH
hook.Add("DatabaseConnected", "PointshopCreateData", function()
    local query = mysql:Create("hg_pointshop")
        query:Create("steamid", "VARCHAR(20) NOT NULL")
        query:Create("steam_name", "VARCHAR(32) NOT NULL")
        query:Create("donpoints", "FLOAT NOT NULL")
        query:Create("points", "FLOAT NOT NULL")
        query:Create("items", "TEXT NOT NULL")
        query:PrimaryKey("steamid")
    query:Execute()

    PLUGIN.Active = true
    print("[Z-City Shop] Baza danych załadowana pomyślnie.")
end)

local plyMeta = FindMetaTable("Player")

function plyMeta:GetPointshopVars()
    local steamID64 = self:SteamID64()
    if not PLUGIN.PlayerInstances[steamID64] then
        PLUGIN.PlayerInstances[steamID64] = { donpoints = 0, points = 0, items = {} }
    end
    return PLUGIN.PlayerInstances[steamID64]
end

-- SERVER: sprawdzanie itemów (poprawne, bez LocalPlayer)
function plyMeta:PS_HasItem(uid)
    local pointshopVars = self:GetPointshopVars()
    if not pointshopVars or not pointshopVars.items then return false end
    return pointshopVars.items[uid] or false
end

-- 2. PUSH VARS (bez callbacków)
function PLUGIN:PushPointShopVars(ply)
    net.Start("hg_pointshop_vars")
        net.WriteTable(ply:GetPointshopVars())
    net.Send(ply)
end

-- 3. RESPONSE VARS (do callbacków)
function PLUGIN:ReplyPointShopVars(ply)
    net.Start("hg_pointshop_net")
        net.WriteTable(ply:GetPointshopVars())
    net.Send(ply)
end

-- 4. WCZYTYWANIE GRACZA PRZY WEJŚCIU
hook.Add("PlayerInitialSpawn", "Pointshop_OnInitSpawn", function(ply)
    local name = ply:Name()
    local steamID64 = ply:SteamID64()

    if not PLUGIN.Active then
        PLUGIN.PlayerInstances[steamID64] = { donpoints = 0, points = 0, items = {} }
        timer.Simple(0, function()
            if IsValid(ply) then PLUGIN:PushPointShopVars(ply) end
        end)
        return
    end

    local query = mysql:Select("hg_pointshop")
        query:Select("donpoints")
        query:Select("points")
        query:Select("items")
        query:Where("steamid", steamID64)
        query:Callback(function(result)
            if (IsValid(ply) and istable(result) and #result > 0 and result[1] and result[1].donpoints) then
                local updateQuery = mysql:Update("hg_pointshop")
                    updateQuery:Update("steam_name", name)
                    updateQuery:Where("steamid", steamID64)
                updateQuery:Execute()

                PLUGIN.PlayerInstances[steamID64] = {
                    donpoints = tonumber(result[1].donpoints) or 0,
                    points = tonumber(result[1].points) or 0,
                    items = util.JSONToTable(result[1].items) or {}
                }

                hook.Run("PS_PlayerLoaded", ply, steamID64)
            else
                local insertQuery = mysql:Insert("hg_pointshop")
                    insertQuery:Insert("steamid", steamID64)
                    insertQuery:Insert("steam_name", name)
                    insertQuery:Insert("donpoints", 0)
                    insertQuery:Insert("points", 0)
                    insertQuery:Insert("items", util.TableToJSON({}))
                insertQuery:Execute()

                PLUGIN.PlayerInstances[steamID64] = { donpoints = 0, points = 0, items = {} }
            end

            timer.Simple(0, function()
                if IsValid(ply) then PLUGIN:PushPointShopVars(ply) end
            end)
        end)
    query:Execute()
end)

-- 5. PUNKTY
function plyMeta:PS_AddPoints(ammout)
    local v = self:GetPointshopVars()
    if ammout < 1 then return false end
    self:PS_SetPoints(v.points + ammout)
    return true
end

function plyMeta:PS_SetPoints(value)
    if not util.IsBinaryModuleInstalled("mysqloo") and not mysql then return end
    local steamID64 = self:SteamID64()
    local v = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
        updateQuery:Update("points", value)
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()

    v.points = value
end

function plyMeta:PS_TakePoints(ammout, callback)
    local v = self:GetPointshopVars()
    if ammout > v.points then return false, "Not enough ZPoints." end
    self:PS_SetPoints(v.points - ammout)
    if callback then callback(self) end
    return true, "Purchased."
end

function plyMeta:PS_AddDPoints(ammout)
    local v = self:GetPointshopVars()
    if ammout < 1 then return false end
    self:PS_SetDPoints(v.donpoints + ammout)
    return true
end

function plyMeta:PS_SetDPoints(value)
    if not util.IsBinaryModuleInstalled("mysqloo") and not mysql then return end
    local steamID64 = self:SteamID64()
    local v = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
        updateQuery:Update("donpoints", value)
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()

    v.donpoints = value
end

function plyMeta:PS_TakeDPoints(ammout, callback)
    local v = self:GetPointshopVars()
    if ammout > v.donpoints then return false, "Not enough DZPoints." end
    self:PS_SetDPoints(v.donpoints - ammout)
    if callback then callback(self) end
    return true, "Purchased."
end

-- 6. ITEMY
function plyMeta:PS_SetItems(tItems)
    local steamID64 = self:SteamID64()
    local v = self:GetPointshopVars()

    local updateQuery = mysql:Update("hg_pointshop")
        updateQuery:Update("items", util.TableToJSON(tItems))
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()

    v.items = tItems
end

function plyMeta:PS_AddItem(uid)
    if not hg.PointShop.Items or not hg.PointShop.Items[uid] then return end
    local v = self:GetPointshopVars()
    v.items[uid] = true
    self:PS_SetItems(v.items)
end

-- 7. KUPNO
function PLUGIN:NET_BuyItem(ply, uid)
    if not util.IsBinaryModuleInstalled("mysqloo") and not mysql then return end
    if not hg.PointShop.Items or not hg.PointShop.Items[uid] then return end

    if ply:PS_HasItem(uid) then
        PLUGIN:ReplyPointShopVars(ply)
        return
    end

    local yes, reason
    if hg.PointShop.Items[uid].ISDONATE then
        yes, reason = ply:PS_TakeDPoints(hg.PointShop.Items[uid].PRICE, function() ply:PS_AddItem(uid) end)
    else
        yes, reason = ply:PS_TakePoints(hg.PointShop.Items[uid].PRICE, function() ply:PS_AddItem(uid) end)
    end

    net.Start("hg_pointshop_send_notificate")
        net.WriteString(tostring(reason or (yes and "Purchased." or "Error.")))
    net.Send(ply)

    PLUGIN:ReplyPointShopVars(ply)
end

function PLUGIN:NET_SendPointShopVars(ply)
    -- to jest request z klienta (ma callback), więc odpowiadamy przez hg_pointshop_net
    PLUGIN:ReplyPointShopVars(ply)
end

function PLUGIN:NET_GetBuyedItems(ply)
    PLUGIN:ReplyPointShopVars(ply)
end

-- Requesty z klienta
net.Receive("hg_pointshop_net", function(_, ply)
    if ply.PSNetCD and ply.PSNetCD > CurTime() then return end
    ply.PSNetCD = CurTime() + 0.01

    local str = net.ReadString()
    local func = PLUGIN["NET_" .. str]
    if not func then return end

    local vars = net.ReadTable()
    if table.Count(vars) > 5 then return end

    func(PLUGIN, ply, unpack(vars))
end)

-- Timer punktów (push bez callbacków)
timer.Create("ZCity_PointsTimer", POINTS_INTERVAL, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsFullyAuthenticated() then
            if not ADMINS_GET_POINTS and (ply:IsSuperAdmin() or ply:IsAdmin()) then
                continue
            end

            ply:PS_AddPoints(POINTS_AMOUNT)
            PLUGIN:PushPointShopVars(ply)
        end
    end
end)