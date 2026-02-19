local PANEL = {}

BlurBackground = hg.DrawBlur

local col = {
    bg        = Color(12, 12, 18, 240),
    header    = Color(18, 18, 28, 255),
    accent    = Color(220, 55, 55),
    text      = Color(240, 240, 245),
    subtext   = Color(150, 155, 170, 200),
    border    = Color(220, 55, 55, 100),
    divider   = Color(50, 50, 65),
}

function PANEL:Init()
    self.openTime = SysTime()
end

function PANEL:Paint(w, h)
    local age = math.Clamp((SysTime() - self.openTime) * 3, 0, 1)

    BlurBackground(self)

    surface.SetDrawColor(col.bg)
    surface.DrawRect(0, 0, w, h)

    local hdrH = ScreenScale(30)

    surface.SetDrawColor(col.header)
    surface.DrawRect(0, 0, w, hdrH)

    local stripe = ScreenScale(1.2)
    surface.SetDrawColor(col.accent)
    surface.DrawRect(0, 0, w * age, stripe)

    for i = 0, hdrH do
        local frac = 1 - (i / hdrH)
        surface.SetDrawColor(col.accent.r, col.accent.g, col.accent.b, frac * frac * 20)
        surface.DrawRect(0, i, w, 1)
    end

    surface.SetFont("ZB_InterfaceMediumLarge")
    local title = "GŁOSOWANIE NA MAPĘ"
    local tw, th = surface.GetTextSize(title)
    local titleX = w / 2 - tw / 2
    local titleY = hdrH / 2 - th / 2 - ScreenScale(3)

    surface.SetTextColor(0, 0, 0, 120 * age)
    surface.SetTextPos(titleX + 1, titleY + 1)
    surface.DrawText(title)

    surface.SetTextColor(col.text.r, col.text.g, col.text.b, 255 * age)
    surface.SetTextPos(titleX, titleY)
    surface.DrawText(title)

    surface.SetFont("ZB_ScrappersMedium")
    local sub = "Wybierz następną mapę  •  " .. player.GetCount() .. " graczy online"
    local sw, sh = surface.GetTextSize(sub)

    surface.SetTextColor(col.subtext.r, col.subtext.g, col.subtext.b, col.subtext.a * age)
    surface.SetTextPos(w / 2 - sw / 2, titleY + th + ScreenScale(1))
    surface.DrawText(sub)

    surface.SetDrawColor(col.divider)
    surface.DrawRect(0, hdrH, w, 1)

    local accentW = w * 0.6 * age
    surface.SetDrawColor(col.accent.r, col.accent.g, col.accent.b, 80)
    surface.DrawRect(w / 2 - accentW / 2, hdrH, accentW, 1)

    surface.SetDrawColor(col.border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

vgui.Register("ZB_RTVMenu", PANEL, "ZFrame")