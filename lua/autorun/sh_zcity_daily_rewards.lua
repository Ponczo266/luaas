if SERVER then AddCSLuaFile() end

hg = hg or {}
hg.DailyRewards = hg.DailyRewards or {}
local DR = hg.DailyRewards

DR.SKIN_ITEM_ID = "daily_skin_bigstein"
DR.SKIN_MODEL   = "models/thebigstein/player/bigstein.mdl"
DR.SKIN_NAME    = "Jeffrey Stein"

util.PrecacheModel(DR.SKIN_MODEL)

local function DayStampUTC(t) return tonumber(os.date("!%Y%m%d", t or os.time())) or 0 end
local function TodayStamp() return DayStampUTC(os.time()) end
local function YesterdayStamp() return DayStampUTC(os.time() - 86400) end

local function GetRewardForDay(day, hasSkinAlready)
    if day == 10 then
        if hasSkinAlready then
            return { kind = "points", amount = 200, desc = "200 ZP" }
        else
            return { kind = "skin", itemID = DR.SKIN_ITEM_ID, desc = "Skin: " .. DR.SKIN_NAME }
        end
    end
    if day > 10 then return { kind = "points", amount = 200, desc = "200 ZP" } end
    if day == 5  then return { kind = "points", amount = 100, desc = "100 ZP" } end
    return { kind = "points", amount = 50, desc = "50 ZP" }
end

local function GetRewardShort(day)
    if day == 10 then return "SKIN" end
    if day == 5  then return "100" end
    if day > 10  then return "200" end
    return "50"
end

DR._AppearancePatched = false

local function PatchAppearance()
    if not hg.Appearance or not hg.Appearance.PlayerModels then return false end

    hg.Appearance.PlayerModels[1] = hg.Appearance.PlayerModels[1] or {}
    hg.Appearance.FuckYouModels = hg.Appearance.FuckYouModels or { {}, {} }
    hg.Appearance.FuckYouModels[1] = hg.Appearance.FuckYouModels[1] or {}

    local entry = {
        mdl         = DR.SKIN_MODEL,
        submatSlots = {},
        sex         = 1,
        psItemID    = DR.SKIN_ITEM_ID,
        noRandom    = true,
    }

    hg.Appearance.PlayerModels[1][DR.SKIN_NAME] = entry
    hg.Appearance.FuckYouModels[1][DR.SKIN_MODEL] = entry

    hg.Appearance.FacemapsSlots  = hg.Appearance.FacemapsSlots or {}
    hg.Appearance.FacemapsModels = hg.Appearance.FacemapsModels or {}
    hg.Appearance.FacemapsSlots["__NOFACEMAP__"] = hg.Appearance.FacemapsSlots["__NOFACEMAP__"] or { ["Default"] = "" }
    hg.Appearance.FacemapsModels[DR.SKIN_MODEL]  = "__NOFACEMAP__"

    if not DR._AppearancePatched then
        DR._AppearancePatched = true
        hg.Appearance.ValidateFunctions = hg.Appearance.ValidateFunctions or {}
        local oldAModel = hg.Appearance.ValidateFunctions.AModel

        hg.Appearance.ValidateFunctions.AModel = function(str)
            if str == DR.SKIN_NAME then return true end
            if oldAModel then return oldAModel(str) end
            if not isstring(str) then return false end
            local pm = hg.Appearance.PlayerModels
            return (pm and pm[1] and pm[1][str] ~= nil) or (pm and pm[2] and pm[2][str] ~= nil)
        end
    end

    return true
end

hook.Add("Initialize", "ZCityDR_Patch1", function()
    PatchAppearance()
    timer.Create("ZCityDR_PatchRetry", 1, 120, function()
        if PatchAppearance() then timer.Remove("ZCityDR_PatchRetry") end
    end)
end)
hook.Add("PostGamemodeLoaded", "ZCityDR_Patch2", PatchAppearance)
hook.Add("InitPostEntity",     "ZCityDR_Patch3", PatchAppearance)

if SERVER then
    util.AddNetworkString("hg_daily_rewards_request")
    util.AddNetworkString("hg_daily_rewards_state")
    util.AddNetworkString("hg_daily_rewards_claim")
end

if SERVER then
    DR.Data = DR.Data or {}

    local function EnsureRow(ply)
        local sid = ply:SteamID64()
        DR.Data[sid] = DR.Data[sid] or { streak = 0, lastclaim = 0 }
        return DR.Data[sid]
    end

    local function SaveRow(ply)
        if not mysql then return end
        local sid = ply:SteamID64()
        local row = EnsureRow(ply)
        local q = mysql:Update("hg_daily_rewards")
            q:Update("streak", row.streak)
            q:Update("lastclaim", row.lastclaim)
            q:Where("steamid", sid)
        q:Execute()
    end

    local function ComputeClaimDay(row)
        local today     = TodayStamp()
        local yesterday = YesterdayStamp()
        if row.lastclaim == yesterday then return (row.streak or 0) + 1 end
        if row.lastclaim == today     then return row.streak or 0 end
        return 1
    end

    local function PlayerHasSkin(ply)
        if not IsValid(ply) then return false end
        if ply.PS_HasItem and ply:PS_HasItem(DR.SKIN_ITEM_ID) then return true end
        if ply.GetPointshopVars then
            local v = ply:GetPointshopVars()
            if v and v.items and v.items[DR.SKIN_ITEM_ID] then return true end
        end
        return false
    end

    local function ForceGivePSItem(ply, uid)
        if not IsValid(ply) then return false end

        if ply.GetPointshopVars and ply.PS_SetItems then
            local v = ply:GetPointshopVars()
            v.items = v.items or {}
            if not v.items[uid] then
                v.items[uid] = true
                ply:PS_SetItems(v.items)
            end
        end

        if ply.PS_GiveItem then ply:PS_GiveItem(uid) end
        if hg.PointShop and hg.PointShop.GiveItem then hg.PointShop:GiveItem(ply, uid) end
        if ply.PS_Save then ply:PS_Save() end
        if hg.PointShop and hg.PointShop.SavePlayerData then hg.PointShop:SavePlayerData(ply) end

        return PlayerHasSkin(ply)
    end

    local function SyncPointshop(ply)
        if not IsValid(ply) then return end
        if hg.PointShop then
            if hg.PointShop.PushPointShopVars    then hg.PointShop:PushPointShopVars(ply) end
            if hg.PointShop.NET_SendPointShopVars then hg.PointShop:NET_SendPointShopVars(ply) end
        end
    end

    function DR:SendState(ply)
        local row      = EnsureRow(ply)
        local today    = TodayStamp()
        local claimDay = ComputeClaimDay(row)
        local canClaim = (row.lastclaim ~= today)
        local hasSkin  = PlayerHasSkin(ply)
        local reward   = GetRewardForDay(claimDay, hasSkin)

        net.Start("hg_daily_rewards_state")
            net.WriteUInt(row.streak or 0, 16)
            net.WriteUInt(row.lastclaim or 0, 32)
            net.WriteBool(canClaim)
            net.WriteUInt(claimDay or 1, 16)
            net.WriteString(reward.desc or "")
            net.WriteUInt((reward.kind == "skin") and 1 or 0, 8)
            net.WriteUInt(reward.amount or 0, 16)
            net.WriteBool(hasSkin)
        net.Send(ply)
    end

    hook.Add("DatabaseConnected", "ZCityDR_CreateTable", function()
        if not mysql then return end
        local q = mysql:Create("hg_daily_rewards")
            q:Create("steamid",   "VARCHAR(20) NOT NULL")
            q:Create("streak",    "INT NOT NULL")
            q:Create("lastclaim", "INT NOT NULL")
            q:PrimaryKey("steamid")
        q:Execute()
    end)

    hook.Add("PlayerInitialSpawn", "ZCityDR_Load", function(ply)
        EnsureRow(ply)

        if not mysql then
            timer.Simple(2, function() if IsValid(ply) then DR:SendState(ply) end end)
            return
        end

        local sid = ply:SteamID64()
        local q = mysql:Select("hg_daily_rewards")
            q:Select("streak")
            q:Select("lastclaim")
            q:Where("steamid", sid)
            q:Callback(function(res)
                if not IsValid(ply) then return end
                if istable(res) and res[1] then
                    DR.Data[sid] = {
                        streak    = tonumber(res[1].streak)    or 0,
                        lastclaim = tonumber(res[1].lastclaim) or 0,
                    }
                else
                    local ins = mysql:Insert("hg_daily_rewards")
                        ins:Insert("steamid",   sid)
                        ins:Insert("streak",    0)
                        ins:Insert("lastclaim", 0)
                    ins:Execute()
                    DR.Data[sid] = { streak = 0, lastclaim = 0 }
                end
                timer.Simple(1, function() if IsValid(ply) then DR:SendState(ply) end end)
            end)
        q:Execute()
    end)

    net.Receive("hg_daily_rewards_request", function(_, ply)
        if IsValid(ply) then DR:SendState(ply) end
    end)

    net.Receive("hg_daily_rewards_claim", function(_, ply)
        if not IsValid(ply) then return end

        local row       = EnsureRow(ply)
        local today     = TodayStamp()
        local yesterday = YesterdayStamp()

        if row.lastclaim == today then
            DR:SendState(ply)
            return
        end

        local newDay
        if row.lastclaim == yesterday then
            row.streak = (row.streak or 0) + 1
            newDay = row.streak
        else
            row.streak = 1
            newDay = 1
        end
        row.lastclaim = today

        local hasSkin = PlayerHasSkin(ply)
        local reward  = GetRewardForDay(newDay, hasSkin)

        if reward.kind == "skin" then
            if not hasSkin then
                ForceGivePSItem(ply, DR.SKIN_ITEM_ID)
                ply:ChatPrint("[Nagrody] Otrzymales skin: " .. DR.SKIN_NAME .. "!")
                ply:ChatPrint("[Nagrody] Mozesz go wybrac w menu wygladu.")
            else
                ply:PS_AddPoints(200)
                ply:ChatPrint("[Nagrody] Masz juz tego skina — dostajesz 200 ZP!")
            end
        else
            if ply.PS_AddPoints then ply:PS_AddPoints(reward.amount or 0) end
            ply:ChatPrint("[Nagrody] Otrzymales " .. (reward.amount or 0) .. " ZP!")
        end

        SaveRow(ply)
        timer.Simple(0.5, function()
            if IsValid(ply) then
                SyncPointshop(ply)
                DR:SendState(ply)
            end
        end)
    end)

    concommand.Add("hg_daily_rewards_debug_setday", function(ply, _, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        local day = math.max(1, math.floor(tonumber(args[1] or "1") or 1))
        local row = EnsureRow(ply)
        row.streak    = day - 1
        row.lastclaim = YesterdayStamp()
        SaveRow(ply)
        DR:SendState(ply)
    end)

    concommand.Add("hg_daily_rewards_debug_reset", function(ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        local row = EnsureRow(ply)
        row.streak    = 0
        row.lastclaim = 0
        SaveRow(ply)
        DR:SendState(ply)
    end)

    concommand.Add("hg_daily_rewards_debug_giveskin", function(ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        ForceGivePSItem(ply, DR.SKIN_ITEM_ID)
        SyncPointshop(ply)
        DR:SendState(ply)
    end)
end

if CLIENT then

    surface.CreateFont("ZDR_Header",   { font = "Montserrat Bold", fallback = "Roboto", size = 26, weight = 800, antialias = true })
    surface.CreateFont("ZDR_Sub",      { font = "Montserrat",      fallback = "Roboto", size = 15, weight = 600, antialias = true })
    surface.CreateFont("ZDR_Day",      { font = "Montserrat Bold", fallback = "Roboto", size = 20, weight = 800, antialias = true })
    surface.CreateFont("ZDR_DaySub",   { font = "Montserrat",      fallback = "Roboto", size = 11, weight = 500, antialias = true })
    surface.CreateFont("ZDR_Info",     { font = "Montserrat",      fallback = "Roboto", size = 16, weight = 500, antialias = true })
    surface.CreateFont("ZDR_InfoBold", { font = "Montserrat Bold", fallback = "Roboto", size = 16, weight = 700, antialias = true })
    surface.CreateFont("ZDR_Btn",      { font = "Montserrat Bold", fallback = "Roboto", size = 18, weight = 800, antialias = true })
    surface.CreateFont("ZDR_Close",    { font = "Roboto",          size = 24, weight = 800, antialias = true })

    DR.State = DR.State or {}

    local colBg        = Color(18, 18, 22)
    local colHeader    = Color(190, 30, 45)
    local colHeaderDk  = Color(140, 20, 30)
    local colTile      = Color(32, 32, 38)
    local colTileHov   = Color(42, 42, 50)
    local colClaimed   = Color(190, 30, 45)
    local colNext      = Color(45, 160, 65)
    local colNextGlow  = Color(45, 160, 65, 60)
    local colMilestone = Color(230, 175, 30)
    local colMileBg    = Color(60, 50, 15)
    local colGold      = Color(255, 210, 50)
    local colCheck     = Color(120, 255, 130)
    local colDim       = Color(120, 120, 130)
    local colWhite     = Color(240, 240, 245)
    local colBtnOff    = Color(55, 55, 60)
    local colBtnHov    = Color(220, 40, 55)
    local colSep       = Color(255, 255, 255, 12)
    local colCloseHov  = Color(255, 60, 60)

    local function LerpColor(t, a, b)
        return Color(
            Lerp(t, a.r, b.r),
            Lerp(t, a.g, b.g),
            Lerp(t, a.b, b.b),
            Lerp(t, a.a or 255, b.a or 255)
        )
    end

    net.Receive("hg_daily_rewards_state", function()
        DR.State.streak       = net.ReadUInt(16)
        DR.State.lastclaim    = net.ReadUInt(32)
        DR.State.canClaim     = net.ReadBool()
        DR.State.claimDay     = net.ReadUInt(16)
        DR.State.rewardDesc   = net.ReadString()
        DR.State.rewardKind   = net.ReadUInt(8)
        DR.State.rewardAmount = net.ReadUInt(16)
        DR.State.hasSkin      = net.ReadBool()

        if IsValid(DR.Panel) and DR.Panel.Refresh then
            DR.Panel:Refresh()
        end
    end)

    local function RequestState()
        net.Start("hg_daily_rewards_request")
        net.SendToServer()
    end

    local function Claim()
        net.Start("hg_daily_rewards_claim")
        net.SendToServer()
    end

    local PANEL = {}

    function PANEL:Init()
        local pnl = self

        self:SetSize(680, 400)
        self:Center()
        self:SetTitle("")
        self:ShowCloseButton(false)
        self:SetDraggable(true)
        self:MakePopup()
        self:DockPadding(0, 0, 0, 0)

        self.HeaderH     = 50
        self.ClaimedDays = 0
        self.DayTiles    = {}

        self.CloseBtn = vgui.Create("DButton", self)
        self.CloseBtn:SetText("")
        self.CloseBtn:SetSize(36, 36)
        self.CloseBtn:SetZPos(999)
        self.CloseBtn:MoveToFront()
        self.CloseBtn:SetMouseInputEnabled(true)
        self.CloseBtn._hover = 0

        self.CloseBtn.Think = function(s)
            s._hover = Lerp(FrameTime() * 12, s._hover or 0, s:IsHovered() and 1 or 0)
        end

        self.CloseBtn.Paint = function(s, w, h)
            if s._hover > 0.01 then
                draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(colCloseHov, 40 * s._hover))
            end
            local col = LerpColor(s._hover, colDim, colCloseHov)
            draw.SimpleText("X", "ZDR_Close", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        self.CloseBtn.DoClick = function()
            if IsValid(pnl) then pnl:Remove() end
        end

        self.TileContainer = vgui.Create("DPanel", self)
        self.TileContainer.Paint = function() end

        for i = 1, 10 do
            local tile = vgui.Create("DPanel", self.TileContainer)
            tile.DayIndex = i
            tile._hover = 0

            tile.Think = function(s)
                s._hover = Lerp(FrameTime() * 10, s._hover or 0, s:IsHovered() and 1 or 0)
            end

            tile.Paint = function(s, w, h)
                local claimed   = pnl.ClaimedDays or 0
                local isClaimed = (s.DayIndex <= claimed)
                local isNext    = (s.DayIndex == claimed + 1)
                local isMile    = (s.DayIndex == 5 or s.DayIndex == 10)

                local bg
                if isClaimed then
                    bg = isMile and colMilestone or colClaimed
                elseif isNext then
                    bg = colNext
                elseif isMile then
                    bg = LerpColor(s._hover, colMileBg, colTileHov)
                else
                    bg = LerpColor(s._hover, colTile, colTileHov)
                end

                draw.RoundedBox(6, 0, 0, w, h, bg)

                if isNext and not isClaimed then
                    local pulse = math.sin(CurTime() * 3) * 0.3 + 0.7
                    local glow = ColorAlpha(colNextGlow, 60 * pulse)
                    draw.RoundedBox(6, -2, -2, w + 4, h + 4, glow)
                end

                if isMile and not isClaimed then
                    surface.SetDrawColor(ColorAlpha(colGold, 80 + s._hover * 80))
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                end

                draw.SimpleText(tostring(s.DayIndex), "ZDR_Day",
                    w / 2, h * 0.35, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                local subText = GetRewardShort(s.DayIndex)

                if isClaimed then
                    draw.SimpleText("✓", "ZDR_Day",
                        w / 2, h * 0.72, colCheck, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                else
                    local subCol = isMile and colGold or colDim
                    draw.SimpleText(subText, "ZDR_DaySub",
                        w / 2, h * 0.73, subCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            self.DayTiles[i] = tile
        end

        self.InfoPanel = vgui.Create("DPanel", self)
        self.InfoPanel.Paint = function(_, w, h)
            surface.SetDrawColor(colSep)
            surface.DrawRect(0, 0, w, 1)
        end

        self.InfoLabel = vgui.Create("DLabel", self.InfoPanel)
        self.InfoLabel:SetFont("ZDR_Info")
        self.InfoLabel:SetTextColor(colWhite)
        self.InfoLabel:SetWrap(true)
        self.InfoLabel:SetAutoStretchVertical(true)

        self.SkinLabel = vgui.Create("DLabel", self.InfoPanel)
        self.SkinLabel:SetFont("ZDR_InfoBold")
        self.SkinLabel:SetTextColor(colGold)

        self.ClaimBtn = vgui.Create("DButton", self)
        self.ClaimBtn:SetText("ODBIERZ")
        self.ClaimBtn:SetFont("ZDR_Btn")
        self.ClaimBtn:SetTextColor(colWhite)
        self.ClaimBtn._hover = 0

        self.ClaimBtn.Think = function(s)
            s._hover = Lerp(FrameTime() * 10, s._hover or 0, s:IsHovered() and 1 or 0)
        end

        self.ClaimBtn.Paint = function(s, w, h)
            local col
            if s:GetDisabled() then
                col = colBtnOff
            else
                col = LerpColor(s._hover, colHeader, colBtnHov)
            end
            draw.RoundedBox(6, 0, 0, w, h, col)
        end

        self.ClaimBtn.DoClick = function() Claim() end

        RequestState()
    end

    function PANEL:PerformLayout(w, h)
        self.CloseBtn:SetPos(w - 44, 7)

        local tileW = 56
        local tileH = 56
        local gap = 6
        local totalW = 10 * tileW + 9 * gap
        local startX = (w - totalW) / 2
        local tileY = self.HeaderH + 20

        self.TileContainer:SetPos(0, 0)
        self.TileContainer:SetSize(w, tileY + tileH + 10)

        for i, tile in ipairs(self.DayTiles) do
            tile:SetPos(startX + (i - 1) * (tileW + gap), tileY)
            tile:SetSize(tileW, tileH)
        end

        local infoY = tileY + tileH + 18
        self.InfoPanel:SetPos(20, infoY)
        self.InfoPanel:SetSize(w - 40, h - infoY - 70)

        self.InfoLabel:SetPos(0, 10)
        self.InfoLabel:SetSize(self.InfoPanel:GetWide(), 20)

        self.SkinLabel:SetPos(0, self.InfoPanel:GetTall() - 24)
        self.SkinLabel:SetSize(self.InfoPanel:GetWide(), 20)

        self.ClaimBtn:SetPos(20, h - 58)
        self.ClaimBtn:SetSize(w - 40, 44)
    end

    function PANEL:Refresh()
        local st  = DR.State or {}
        local day = math.max(1, st.claimDay or 1)
        local todayReward = GetRewardForDay(day, st.hasSkin)

        local claimed = 0
        local today     = TodayStamp()
        local yesterday = YesterdayStamp()
        if (st.lastclaim == today) or (st.lastclaim == yesterday) then
            claimed = tonumber(st.streak or 0) or 0
        end
        self.ClaimedDays = math.Clamp(claimed, 0, 10)

        self.InfoLabel:SetText(
            "Dzien " .. day .. "  ·  " .. (todayReward.desc or "?") ..
            "\nDzien 5: 100 ZP   ·   Dzien 10: Skin " .. DR.SKIN_NAME
        )

        if st.hasSkin then
            self.SkinLabel:SetText("Posiadasz skin " .. DR.SKIN_NAME .. " — wybierz go w menu wygladu")
            self.SkinLabel:SetTextColor(colCheck)
        else
            self.SkinLabel:SetText("Skin " .. DR.SKIN_NAME .. " — odblokujesz go na dzien 10")
            self.SkinLabel:SetTextColor(colDim)
        end

        self.ClaimBtn:SetEnabled(st.canClaim and true or false)
        self.ClaimBtn:SetText(st.canClaim and "ODBIERZ NAGRODE" or "ODEBRANO")
    end

    function PANEL:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, colBg)

        local hh = self.HeaderH
        draw.RoundedBoxEx(8, 0, 0, w, hh, colHeaderDk, true, true, false, false)

        surface.SetDrawColor(colHeader)
        surface.DrawRect(0, hh - 3, w, 3)

        draw.SimpleText("NAGRODY DZIENNE", "ZDR_Header",
            20, hh / 2, colWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local streak = DR.State.streak or 0
        draw.SimpleText(streak .. " / 10", "ZDR_Sub",
            w - 52, hh / 2, ColorAlpha(colWhite, 180), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        local barW = (streak / 10) * w
        surface.SetDrawColor(colHeader)
        surface.DrawRect(0, hh - 3, barW, 3)
    end

    function PANEL:OnKeyCodePressed(key)
        if key == KEY_ESCAPE or key == KEY_F2 then
            self:Remove()
        end
    end

    vgui.Register("ZCityDailyRewards", PANEL, "DFrame")

    function DR.Open()
        if IsValid(DR.Panel) then
            DR.Panel:Remove()
            DR.Panel = nil
            return
        end
        DR.Panel = vgui.Create("ZCityDailyRewards")
        DR.Panel:Refresh()
    end

    concommand.Add("hg_daily_rewards", function() DR.Open() end)

    DR._F2Down = DR._F2Down or false
    hook.Add("Think", "ZCityDR_F2Think", function()
        if not IsValid(LocalPlayer()) then return end
        if gui.IsGameUIVisible() then return end

        local down = input.IsKeyDown(KEY_F2)
        if down and not DR._F2Down then
            DR._F2Down = true
            DR.Open()
        elseif not down and DR._F2Down then
            DR._F2Down = false
        end
    end)
end