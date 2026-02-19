local PANEL = {}

BlurBackground = BlurBackground or hg.DrawBlur

local col = {
    cardBg      = Color(22, 22, 32, 220),
    cardHover   = Color(30, 30, 45, 240),
    accent      = Color(220, 55, 55),
    accentDark  = Color(140, 30, 30),
    barTrack    = Color(255, 255, 255, 10),
    text        = Color(240, 240, 245),
    textDim     = Color(80, 80, 95),
    overlay     = Color(0, 0, 0, 130),
    border      = Color(55, 55, 70),
    borderHover = Color(220, 55, 55, 200),
    badge       = Color(220, 55, 55, 210),
    shadow      = Color(0, 0, 0, 100),
}

function PANEL:Init()
    self.Map = ""
    self.Votes = 0
    self.lerp = 0
    self.BipCD = 0

    self.hovered = false
    self.hoverAlpha = 0
    self.winFlash = 0

    self.disabled = false
    self.selected = false

    self:SetFont("ZB_ScrappersMedium")
    self:SetPaintBackground(false)
    self:SetContentAlignment(5)
    self:SetTextColor(col.text)
end

function PANEL:Paint(w, h)
    local ss = ScreenScale

    if self.disabled then
        surface.SetDrawColor(30, 30, 38, 200)
        surface.DrawRect(0, 0, w, h)

        render.SetScissorRect(self:LocalToScreen(0, 0), self:LocalToScreen(w, h), true)
        surface.SetDrawColor(255, 255, 255, 6)
        for i = -h, w, ss(6) do
            surface.DrawLine(i, 0, i + h, h)
        end
        render.SetScissorRect(0, 0, 0, 0, false)

        surface.SetDrawColor(50, 50, 60, 80)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        return
    end

    if self.MapIcon then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(self.MapIcon)
        local imgSize = w + 15
        surface.DrawTexturedRect(0, -w / 2, imgSize, imgSize)
    end

    surface.SetDrawColor(col.overlay)
    surface.DrawRect(0, 0, w, h)

    BlurBackground(self)

    local bgA = Lerp(self.hoverAlpha / 255, col.cardBg.a, col.cardHover.a)
    surface.SetDrawColor(col.cardBg.r, col.cardBg.g, col.cardBg.b, bgA)
    surface.DrawRect(0, 0, w, h)

    if self.hoverAlpha > 0 then
        local glowH = h * 0.4
        for i = 0, glowH do
            local frac = 1 - (i / glowH)
            surface.SetDrawColor(col.accent.r, col.accent.g, col.accent.b,
                frac * frac * (self.hoverAlpha * 0.08))
            surface.DrawRect(0, i, w, 1)
        end
    end

    local barH = ss(1.5)
    local barPad = ss(4)
    local barY = h - barH - barPad
    local barW = w - barPad * 2

    surface.SetDrawColor(col.barTrack)
    surface.DrawRect(barPad, barY, barW, barH)

    local totalPlayers = math.max(player.GetCount(), 1)
    local targetFill = barW * (self.Votes / totalPlayers)
    self.lerp = Lerp(FrameTime() * 6, self.lerp, targetFill)

    if self.lerp > 1 then
        local fillW = math.floor(self.lerp)
        for i = 0, fillW do
            local frac = i / math.max(targetFill, 1)
            local r = Lerp(frac, col.accentDark.r, col.accent.r)
            local g = Lerp(frac, col.accentDark.g, col.accent.g)
            local b = Lerp(frac, col.accentDark.b, col.accent.b)
            surface.SetDrawColor(r, g, b, 220)
            surface.DrawRect(barPad + i, barY, 1, barH)
        end

        surface.SetDrawColor(col.accent.r, col.accent.g, col.accent.b, 25)
        surface.DrawRect(barPad, barY - 2, fillW, barH + 4)
    end

    if self.Votes > 0 then
        surface.SetFont("ZB_ScrappersMedium")
        local voteStr = tostring(self.Votes)
        local vtw, vth = surface.GetTextSize(voteStr)

        local bw = vtw + ss(5)
        local bh = vth + ss(2)
        local bx = w - bw - ss(3)
        local by = ss(3)

        surface.SetDrawColor(col.shadow)
        surface.DrawRect(bx + 1, by + 1, bw, bh)

        surface.SetDrawColor(col.badge)
        surface.DrawRect(bx, by, bw, bh)

        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(bx + bw / 2 - vtw / 2, by + bh / 2 - vth / 2)
        surface.DrawText(voteStr)
    end

    local borderA = Lerp(self.hoverAlpha / 255, 50, 220)
    local bThick = self.hovered and ss(0.7) or ss(0.4)

    surface.SetDrawColor(col.accent.r, col.accent.g, col.accent.b, borderA)
    surface.DrawOutlinedRect(0, 0, w, h, bThick)

    if self.Win and self.BipCD < CurTime() then
        self.winFlash = 255
        surface.PlaySound("buttons/blip1.wav")
        self.BipCD = CurTime() + 1
        self:CreateAnimation(0.6, {
            index = 2,
            target = { winFlash = 0 },
            easing = "inExpo",
            bIgnoreConfig = true,
        })
    end

    if self.winFlash > 0 then
        surface.SetDrawColor(col.accent.r, col.accent.g, col.accent.b, self.winFlash)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(255, 255, 255, self.winFlash * 0.6)
        surface.DrawOutlinedRect(0, 0, w, h, ss(1))
    end
end

function PANEL:OnCursorEntered()
    if self.disabled then return end
    self:CreateAnimation(0.2, {
        index = 1,
        target = { hoverAlpha = 255 },
        easing = "outQuad",
        bIgnoreConfig = true,
    })
    self.hovered = true
end

function PANEL:OnCursorExited()
    if self.selected then return end
    self:CreateAnimation(0.4, {
        index = 1,
        target = { hoverAlpha = 0 },
        easing = "outExpo",
        bIgnoreConfig = true,
    })
    self.hovered = false
end

function PANEL:SetSelected(value)
    self.selected = value
    if value then
        self:OnCursorEntered()
    else
        self:OnCursorExited()
    end
end

function PANEL:Disabled(bool)
    self.disabled = bool
    if bool then
        self:SetTextColor(col.textDim)
        self:SetCursor("arrow")
    else
        self:SetTextColor(col.text)
        self:SetCursor("hand")
    end
end

vgui.Register("ZB_RTVButton", PANEL, "DButton")