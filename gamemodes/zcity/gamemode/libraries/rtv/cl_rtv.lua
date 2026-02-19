local maps      = {}
local time       = 0
local votes      = {}
local winmap     = ""
local rtvStarted = false
local rtvEnded   = false
local VoteCD     = 0
local activeMenu = nil

local col = {
    timerOk      = Color(160, 210, 160),
    timerWarn    = Color(255, 200, 70),
    timerCrit    = Color(255, 60, 60),
    closeBg      = Color(30, 30, 42),
    closeHover   = Color(200, 45, 45),
    closeBorder  = Color(220, 55, 55, 60),
    scrollTrack  = Color(20, 20, 30),
    scrollGrip   = Color(200, 50, 50, 160),
    separator    = Color(220, 55, 55, 40),
}

local function FormatMapName(raw)
    if raw == "random" then return "Losowa Mapa" end
    local parts = string.Explode("_", raw)
    table.remove(parts, 1)
    if #parts == 0 then return raw end
    parts[1] = string.upper(string.Left(parts[1], 1)) .. string.sub(parts[1], 2)
    return table.concat(parts, " ")
end

local function GetMapIcon(raw)
    local path = raw == "random"
        and "icon64/random.png"
        or  "maps/thumb/" .. raw .. ".png"
    local mat = Material(path)
    if mat:IsError() then mat = Material("icon64/tool.png") end
    return mat
end

function zb.RTVMenu()
    if IsValid(activeMenu) then activeMenu:Remove() end
    if #maps == 0 then return end

    system.FlashWindow()

    local ss     = ScreenScale
    local frameW = math.Clamp(ScrW() * 0.62, ss(280), ss(420))
    local frameH = ScrH() * 0.85

    local frame = vgui.Create("ZB_RTVMenu")
    frame:SetSize(frameW, frameH)
    frame:Center()
    frame:SetTitle("")
    frame:SetBackgroundBlur(true)
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame._autoCloseStarted = false
    activeMenu = frame

    local headerH = ss(30)
    local pad     = ss(4)
    local columns = 3
    local gap     = ss(2)

    -- Timer (top-right)
    local timerPanel = vgui.Create("DPanel", frame)
    timerPanel:SetPos(frameW - ss(55) - pad, ss(6))
    timerPanel:SetSize(ss(52), ss(14))

    timerPanel.Paint = function(self, w, h)
        local rem = math.max(0, time - CurTime())
        local tc = col.timerOk
        if rem <= 10 then     tc = col.timerCrit
        elseif rem <= 20 then tc = col.timerWarn end

        draw.RoundedBox(ss(2), 0, 0, w, h, Color(0, 0, 0, 90))

        local str = string.format("%d:%02d",
            math.floor(rem / 60), math.floor(rem % 60))
        surface.SetFont("ZB_ScrappersMedium")
        local tw, th = surface.GetTextSize(str)
        surface.SetTextColor(tc)
        surface.SetTextPos(w / 2 - tw / 2, h / 2 - th / 2)
        surface.DrawText(str)

        if rem <= 10 and rem > 0 then
            local a = math.abs(math.sin(CurTime() * 5)) * 120
            surface.SetDrawColor(tc.r, tc.g, tc.b, a)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
    end

    -- Close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:Dock(BOTTOM)
    closeBtn:DockMargin(pad, ss(2), pad, pad)
    closeBtn:SetTall(ss(11))
    closeBtn:SetText("")
    closeBtn:SetCursor("hand")
    closeBtn._hl = 0

    closeBtn.Paint = function(self, w, h)
        local hov = self:IsHovered()
        self._hl = Lerp(FrameTime() * 10, self._hl, hov and 1 or 0)
        local r = Lerp(self._hl, col.closeBg.r, col.closeHover.r)
        local g = Lerp(self._hl, col.closeBg.g, col.closeHover.g)
        local b = Lerp(self._hl, col.closeBg.b, col.closeHover.b)
        surface.SetDrawColor(r, g, b, 230)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(col.closeBorder.r, col.closeBorder.g, col.closeBorder.b,
            col.closeBorder.a + self._hl * 150)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.SetFont("ZB_ScrappersMedium")
        local txt = "ZAMKNIJ"
        local tw, th = surface.GetTextSize(txt)
        surface.SetTextColor(255, 255, 255, 170 + self._hl * 85)
        surface.SetTextPos(w / 2 - tw / 2, h / 2 - th / 2)
        surface.DrawText(txt)
    end

    closeBtn.DoClick = function()
        if IsValid(frame) then frame:Remove() end
    end

    -- Scroll panel (FILL)
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(pad, headerH + ss(4), pad, 0)

    local sbar = scroll:GetVBar()
    sbar:SetWide(ss(1.5))
    sbar.Paint         = function(_, w, h) surface.SetDrawColor(col.scrollTrack); surface.DrawRect(0, 0, w, h) end
    sbar.btnGrip.Paint = function(_, w, h) draw.RoundedBox(w / 2, 0, 0, w, h, col.scrollGrip) end
    sbar.btnUp.Paint   = function() end
    sbar.btnDown.Paint = function() end

    -- Grid container
    local sbarW  = sbar:GetWide()
    local gridW  = frameW - pad * 2 - sbarW - ss(1)
    local cardW  = math.floor((gridW - gap * (columns - 1)) / columns)
    local cardH  = ss(28)  -- ← ZMNIEJSZONE z 38 na 28

    local container = vgui.Create("DPanel", scroll)
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 0)
    container.Paint = function() end

    -- Split maps
    local regular, hasRandom = {}, false
    for _, v in ipairs(maps) do
        if v == "random" then hasRandom = true
        else table.insert(regular, v) end
    end

    -- Calculate total height
    local rows     = math.ceil(#regular / columns)
    local totalH   = rows * (cardH + gap)
    if hasRandom then totalH = totalH + ss(1) + math.floor(cardH * 0.75) + gap end
    container:SetTall(totalH + gap)

    -- Place cards in 3-column grid
    for i, mapName in ipairs(regular) do
        local colIdx = (i - 1) % columns
        local rowIdx = math.floor((i - 1) / columns)

        local x = colIdx * (cardW + gap)
        local y = rowIdx * (cardH + gap)

        local card = vgui.Create("ZB_RTVButton", container)
        card:SetPos(x, y)
        card:SetSize(cardW, cardH)
        card:SetText(FormatMapName(mapName))
        card.Map     = mapName
        card.MapIcon = GetMapIcon(mapName)

        card.Think = function(self)
            self.Votes = votes[self.Map] or 0
            self.Win   = (winmap ~= "" and self.Map == winmap)
        end

        card.DoClick = function(self)
            if VoteCD > CurTime() then return end
            net.Start("ZB_RockTheVote_vote")
                net.WriteString(self.Map)
            net.SendToServer()
            VoteCD = CurTime() + 1
            surface.PlaySound("UI/buttonclick.wav")
        end
    end

    -- Random button at bottom
    if hasRandom then
        local sepY = rows * (cardH + gap)

        local sep = vgui.Create("DPanel", container)
        sep:SetPos(0, sepY)
        sep:SetSize(gridW, ss(1))
        sep.Paint = function(_, w, h)
            surface.SetDrawColor(col.separator)
            surface.DrawRect(w * 0.1, 0, w * 0.8, h)
        end

        local rndH = math.floor(cardH * 0.75)
        local rnd  = vgui.Create("ZB_RTVButton", container)
        rnd:SetPos(0, sepY + ss(1) + gap)
        rnd:SetSize(gridW, rndH)
        rnd:SetText("LOSOWA MAPA")
        rnd.Map     = "random"
        rnd.MapIcon = GetMapIcon("random")

        rnd.Think = function(self)
            self.Votes = votes["random"] or 0
            self.Win   = false
        end

        rnd.DoClick = function(self)
            if VoteCD > CurTime() then return end
            net.Start("ZB_RockTheVote_vote")
                net.WriteString("random")
            net.SendToServer()
            VoteCD = CurTime() + 1
            surface.PlaySound("UI/buttonclick.wav")
        end
    end

    -- Auto-close after vote ends
    frame.Think = function(self)
        if rtvEnded and winmap ~= "" and not self._autoCloseStarted then
            self._autoCloseStarted = true
            timer.Simple(5, function()
                if IsValid(self) then self:Remove() end
            end)
        end
    end
end

function zb.StartRTV()
    maps     = net.ReadTable()
    time     = net.ReadFloat()
    votes    = {}
    winmap   = ""
    rtvEnded   = false
    rtvStarted = true
    zb.RTVMenu()
end

function zb.RTVregVote()
    votes = net.ReadTable()
end

function zb.EndRTV()
    winmap   = net.ReadString()
    rtvEnded = true
end

net.Receive("ZB_RockTheVote_start",     zb.StartRTV)
net.Receive("ZB_RockTheVote_voteCLreg", zb.RTVregVote)
net.Receive("ZB_RockTheVote_end",       zb.EndRTV)

-- Poprawiona funkcja RTVMenu dla late joiners
net.Receive("RTVMenu", function()
    local newMaps  = net.ReadTable()
    local newTime  = net.ReadFloat()
    local newVotes = net.ReadTable()

    if newMaps and #newMaps > 0 then
        maps  = newMaps
        time  = newTime
        votes = newVotes
    end

    if #maps > 0 then zb.RTVMenu() end
end)