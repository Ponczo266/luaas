-- =========================================================
-- INICJALIZACJA
-- =========================================================
hg = hg or {}
hg.PointShop = hg.PointShop or {}
hg.PointShop.Items = hg.PointShop.Items or {}

local PLUGIN = hg.PointShop

-- =========================================================
-- MUZYKA SKLEPU
-- =========================================================
local MUSIC_URL = "https://cdn.discordapp.com/attachments/911948152381251605/1473256572900606012/044TemShopTobyFox.wav?ex=6996de1a&is=69958c9a&hm=1d2b477819db7ec162a504fb69fa1520d7e68f799ba0709bc04a8ef0565b9a28&"
local MUSIC_VOLUME = 0.65

-- =========================================================
-- KATEGORIE SKLEPU
-- =========================================================
local SHOP_CATEGORIES = {
    { id = "all",       name = "Wszystkie",     icon = "A", order = 0 },
    { id = "premium",   name = "Premium [DZP]", icon = "P", order = 1, color = Color(255, 200, 50) },
    { id = "skiny",     name = "Skiny Postaci", icon = "S", order = 2 },
    { id = "czapki",    name = "Czapki",        icon = "C", order = 3 },
    { id = "maski",     name = "Maski",         icon = "M", order = 4 },
    { id = "okulary",   name = "Okulary",       icon = "O", order = 5 },
    { id = "plecaki",   name = "Plecaki",       icon = "B", order = 6 },
    { id = "akcesoria", name = "Akcesoria",     icon = "X", order = 7 },
    { id = "efekty",    name = "Efekty",        icon = "E", order = 8 },
    { id = "inne",      name = "Inne",          icon = "?", order = 99 }
}

local function GetItemCategory(item)
    if item.CATEGORY then return item.CATEGORY end
    if item.ISDONATE then return "premium" end

    local name = (item.NAME or ""):lower()
    local mdl  = (item.MDL or ""):lower()

    if string.find(name, "skin") or string.find(mdl, "player") or string.find(mdl, "humans") then
        return "skiny"
    elseif string.find(name, "czapk") or string.find(name, "cap") or string.find(name, "hat") or string.find(mdl, "hat") then
        return "czapki"
    elseif string.find(name, "mask") or string.find(name, "maska") or string.find(mdl, "mask") then
        return "maski"
    elseif string.find(name, "okular") or string.find(name, "glass") or string.find(mdl, "glass") then
        return "okulary"
    elseif string.find(name, "plecak") or string.find(name, "backpack") or string.find(mdl, "backpack") then
        return "plecaki"
    elseif string.find(name, "efekt") or string.find(name, "effect") or string.find(name, "trail") then
        return "efekty"
    elseif string.find(name, "rekawiczk") or string.find(name, "glove") or string.find(mdl, "glove") then
        return "akcesoria"
    elseif string.find(name, "zegarek") or string.find(name, "watch") or string.find(mdl, "watch") then
        return "akcesoria"
    elseif string.find(name, "lancuch") or string.find(name, "chain") or string.find(mdl, "chain") then
        return "akcesoria"
    end

    return "inne"
end

-- =========================================================
-- POMOCNICZE
-- =========================================================
local function IsPlayerModelItem(item)
    if item.CATEGORY == "skiny" then return true end
    local name = (item.NAME or ""):lower()
    local mdl  = (item.MDL or ""):lower()
    if string.find(name, "skin") then return true end
    if string.find(mdl, "player") then return true end
    if string.find(mdl, "humans") then return true end
    if string.find(mdl, "playermodel") then return true end
    return false
end

local function ApplyModelProperties(entity, ent)
    if not IsValid(entity) then return end
    entity:SetSkin((isfunction(ent.SKIN) and ent.SKIN()) or (ent.SKIN or 0))
    if ent.BODYGROUP then
        entity:SetBodyGroups(ent.BODYGROUP)
    end
    if ent.DATA then
        for k, v in pairs(ent.DATA) do
            entity:SetSubMaterial(k, v)
        end
    end
end

-- =========================================================
-- [FIX] AutoDetectModelCamera — poprawione framing
-- dla wszystkich rozmiarow modeli (w tym bardzo malych)
-- =========================================================
local function AutoDetectModelCamera(mdlPanel)
    if not IsValid(mdlPanel) or not IsValid(mdlPanel.Entity) then return end

    local ent = mdlPanel.Entity
    ent:SetupBones()

    local mins, maxs = ent:GetRenderBounds()
    if not mins or not maxs then
        mins = Vector(-10, -10, 0)
        maxs = Vector(10, 10, 72)
    end

    local center = (mins + maxs) * 0.5
    local size   = maxs - mins
    local maxDim = math.max(size.x, size.y, size.z)

    -- Zabezpieczenie przed zerowym lub prawie zerowym rozmiarem
    if maxDim < 0.5 then
        local dist = 25
        mdlPanel:SetLookAt(Vector(0, 0, 0))
        mdlPanel:SetCamPos(Vector(dist, dist * 0.3, dist * 0.2))
        mdlPanel:SetFOV(30)
        return Vector(0, 0, 0), dist
    end

    -- Ekstremalnie maly model (np. kolczyk, pin)
    if maxDim < 3 then
        local dist = maxDim * 8
        mdlPanel:SetLookAt(center)
        mdlPanel:SetCamPos(center + Vector(dist, dist * 0.3, dist * 0.15))
        mdlPanel:SetFOV(25)
        return center, dist

    -- Bardzo maly model (np. okulary, mala odznaka)
    elseif maxDim < 8 then
        local dist = maxDim * 4
        mdlPanel:SetLookAt(center)
        mdlPanel:SetCamPos(center + Vector(dist, dist * 0.25, dist * 0.15))
        mdlPanel:SetFOV(28)
        return center, dist

    -- Maly model (np. rekawiczki, zegarek)
    elseif maxDim < 15 then
        local dist = maxDim * 2.8
        mdlPanel:SetLookAt(center)
        mdlPanel:SetCamPos(center + Vector(dist, dist * 0.2, maxDim * 0.3))
        mdlPanel:SetFOV(32)
        return center, dist

    -- Sredni model (np. czapka, maska, plecak)
    elseif maxDim < 40 then
        local dist = maxDim * 1.8
        mdlPanel:SetLookAt(center)
        mdlPanel:SetCamPos(center + Vector(dist, dist * 0.15, maxDim * 0.2))
        mdlPanel:SetFOV(38)
        return center, dist

    -- Duzy model (np. bron, duzy plecak, postac)
    else
        local dist = math.Clamp(maxDim * 1.3, 30, 200)
        mdlPanel:SetLookAt(center)
        mdlPanel:SetCamPos(center + Vector(dist, 0, maxDim * 0.1))
        mdlPanel:SetFOV(45)
        return center, dist
    end
end

local function FindAccessoryData(itemID, itemMDL)
    if not hg.Accessories then return nil end

    if itemID and hg.Accessories[itemID] and hg.Accessories[itemID].bone then
        return hg.Accessories[itemID]
    end

    if itemMDL then
        for accKey, accInfo in pairs(hg.Accessories) do
            if accInfo.model and accInfo.model == itemMDL then
                return accInfo
            end
        end
    end

    return nil
end

-- =========================================================
-- MOTYWY KOLOROW
-- =========================================================
local THEMES = {
    ["Blood Red"] = {
        bg_dark         = Color(15, 8, 8, 252),
        bg_panel        = Color(25, 12, 15, 255),
        bg_item         = Color(40, 20, 25, 255),
        bg_item_hover   = Color(60, 30, 35, 255),
        bg_button       = Color(70, 35, 40, 255),
        accent          = Color(220, 40, 60, 255),
        accent_hover    = Color(255, 70, 90, 255),
        accent_secondary= Color(255, 150, 50, 255),
        accent_green    = Color(80, 220, 120, 255),
        accent_gold     = Color(255, 200, 50, 255),
        accent_red      = Color(255, 50, 70, 255),
        text_white      = Color(255, 255, 255, 255),
        text_gray       = Color(180, 150, 150, 255),
        text_dark       = Color(120, 80, 80, 255),
        shadow          = Color(0, 0, 0, 150),
    },
    ["Cyberpunk"] = {
        bg_dark         = Color(10, 10, 18, 252),
        bg_panel        = Color(18, 18, 30, 255),
        bg_item         = Color(25, 25, 45, 255),
        bg_item_hover   = Color(35, 35, 60, 255),
        bg_button       = Color(40, 40, 70, 255),
        accent          = Color(255, 0, 128, 255),
        accent_hover    = Color(255, 50, 150, 255),
        accent_secondary= Color(0, 255, 255, 255),
        accent_green    = Color(0, 255, 150, 255),
        accent_gold     = Color(255, 215, 0, 255),
        accent_red      = Color(255, 60, 80, 255),
        text_white      = Color(255, 255, 255, 255),
        text_gray       = Color(150, 150, 180, 255),
        text_dark       = Color(80, 80, 110, 255),
        shadow          = Color(0, 0, 0, 150),
    },
    ["Neon Blue"] = {
        bg_dark         = Color(8, 12, 20, 252),
        bg_panel        = Color(15, 20, 35, 255),
        bg_item         = Color(20, 30, 50, 255),
        bg_item_hover   = Color(30, 45, 70, 255),
        bg_button       = Color(35, 50, 80, 255),
        accent          = Color(0, 150, 255, 255),
        accent_hover    = Color(50, 180, 255, 255),
        accent_secondary= Color(0, 255, 200, 255),
        accent_green    = Color(0, 255, 130, 255),
        accent_gold     = Color(255, 200, 50, 255),
        accent_red      = Color(255, 80, 100, 255),
        text_white      = Color(255, 255, 255, 255),
        text_gray       = Color(140, 160, 190, 255),
        text_dark       = Color(70, 90, 120, 255),
        shadow          = Color(0, 0, 0, 150),
    },
    ["Purple Haze"] = {
        bg_dark         = Color(12, 8, 18, 252),
        bg_panel        = Color(22, 15, 35, 255),
        bg_item         = Color(35, 25, 55, 255),
        bg_item_hover   = Color(50, 35, 75, 255),
        bg_button       = Color(55, 40, 85, 255),
        accent          = Color(150, 80, 255, 255),
        accent_hover    = Color(180, 120, 255, 255),
        accent_secondary= Color(255, 100, 200, 255),
        accent_green    = Color(100, 255, 150, 255),
        accent_gold     = Color(255, 210, 80, 255),
        accent_red      = Color(255, 70, 100, 255),
        text_white      = Color(255, 255, 255, 255),
        text_gray       = Color(170, 150, 200, 255),
        text_dark       = Color(100, 80, 130, 255),
        shadow          = Color(0, 0, 0, 150),
    },
    ["Emerald"] = {
        bg_dark         = Color(8, 15, 12, 252),
        bg_panel        = Color(12, 25, 20, 255),
        bg_item         = Color(20, 40, 32, 255),
        bg_item_hover   = Color(30, 55, 45, 255),
        bg_button       = Color(35, 65, 52, 255),
        accent          = Color(0, 220, 130, 255),
        accent_hover    = Color(50, 255, 160, 255),
        accent_secondary= Color(100, 255, 200, 255),
        accent_green    = Color(0, 255, 150, 255),
        accent_gold     = Color(255, 210, 80, 255),
        accent_red      = Color(255, 90, 90, 255),
        text_white      = Color(255, 255, 255, 255),
        text_gray       = Color(150, 180, 170, 255),
        text_dark       = Color(80, 120, 100, 255),
        shadow          = Color(0, 0, 0, 150),
    },
    ["Golden"] = {
        bg_dark         = Color(18, 15, 8, 252),
        bg_panel        = Color(30, 25, 15, 255),
        bg_item         = Color(45, 38, 22, 255),
        bg_item_hover   = Color(60, 50, 30, 255),
        bg_button       = Color(70, 58, 35, 255),
        accent          = Color(255, 200, 50, 255),
        accent_hover    = Color(255, 220, 100, 255),
        accent_secondary= Color(255, 170, 50, 255),
        accent_green    = Color(150, 255, 100, 255),
        accent_gold     = Color(255, 215, 0, 255),
        accent_red      = Color(255, 100, 80, 255),
        text_white      = Color(255, 255, 255, 255),
        text_gray       = Color(200, 180, 140, 255),
        text_dark       = Color(140, 120, 80, 255),
        shadow          = Color(0, 0, 0, 150),
    },
}

local currentThemeName = "Blood Red"
local THEME = THEMES[currentThemeName]

local function SaveTheme(name)
    file.Write("zcity_shop_theme.txt", name)
end

local function LoadTheme()
    if file.Exists("zcity_shop_theme.txt", "DATA") then
        local name = file.Read("zcity_shop_theme.txt", "DATA")
        if THEMES[name] then
            currentThemeName = name
            THEME = THEMES[name]
        end
    end
end

LoadTheme()

-- =========================================================
-- CZCIONKI
-- =========================================================
local function CreateScaledFonts()
    local scale = math.Clamp(ScrH() / 1080, 0.7, 1.5)

    surface.CreateFont("ZCity_Title",            { font = "Roboto", size = math.floor(36 * scale), weight = 800, antialias = true })
    surface.CreateFont("ZCity_Subtitle",         { font = "Roboto", size = math.floor(18 * scale), weight = 600, antialias = true })
    surface.CreateFont("ZCity_Button",           { font = "Roboto", size = math.floor(14 * scale), weight = 700, antialias = true })
    surface.CreateFont("ZCity_ItemName",         { font = "Roboto", size = math.floor(15 * scale), weight = 600, antialias = true })
    surface.CreateFont("ZCity_Price",            { font = "Roboto", size = math.floor(13 * scale), weight = 600, antialias = true })
    surface.CreateFont("ZCity_Points",           { font = "Roboto", size = math.floor(24 * scale), weight = 700, antialias = true })
    surface.CreateFont("ZCity_Search",           { font = "Roboto", size = math.floor(16 * scale), weight = 500, antialias = true })
    surface.CreateFont("ZCity_Category",         { font = "Roboto", size = math.floor(14 * scale), weight = 600, antialias = true })
    surface.CreateFont("ZCity_CategoryIcon",     { font = "Roboto", size = math.floor(16 * scale), weight = 800, antialias = true })
    surface.CreateFont("ZCity_PreviewName",      { font = "Roboto", size = math.floor(20 * scale), weight = 700, antialias = true })
    surface.CreateFont("ZCity_PreviewPrice",     { font = "Roboto", size = math.floor(16 * scale), weight = 600, antialias = true })
    surface.CreateFont("ZCity_Notification",     { font = "Roboto", size = math.floor(16 * scale), weight = 600, antialias = true })
    surface.CreateFont("ZCity_NotificationIcon", { font = "Roboto", size = math.floor(20 * scale), weight = 800, antialias = true })
end

CreateScaledFonts()

-- =========================================================
-- FUNKCJE RYSOWANIA
-- =========================================================
local function AltDonate()
    gui.OpenURL("https://zcity-polska.tebex.io/")
end

local blur = Material("pp/blurscreen")
local hg_potatopc

local function DrawBlur(panel, amount, passes, alpha)
    if not IsValid(panel) then return end
    amount = amount or 5
    hg_potatopc = hg_potatopc or (hg.ConVars and hg.ConVars.potatopc)

    if hg_potatopc and hg_potatopc:GetBool() then
        surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
    else
        surface.SetMaterial(blur)
        surface.SetDrawColor(0, 0, 0, alpha or 125)
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
        local x, y = panel:LocalToScreen(0, 0)
        for i = -(passes or 0.2), 1, 0.2 do
            blur:SetFloat("$blur", i * amount)
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
        end
    end
end

local function LerpColor(t, from, to)
    return Color(
        Lerp(t, from.r, to.r),
        Lerp(t, from.g, to.g),
        Lerp(t, from.b, to.b),
        Lerp(t, from.a or 255, to.a or 255)
    )
end

local function DrawGlowingBox(radius, x, y, w, h, color, glowSize, glowAlpha)
    glowSize = glowSize or 8
    glowAlpha = glowAlpha or 30
    for i = glowSize, 1, -2 do
        local a = (glowAlpha / glowSize) * (glowSize - i + 1)
        draw.RoundedBox(radius + i, x - i, y - i, w + i * 2, h + i * 2, ColorAlpha(color, a))
    end
    draw.RoundedBox(radius, x, y, w, h, color)
end

local gradientMatU = Material("vgui/gradient-u")

local particles = {}

local function CreateParticle(x, y, color)
    table.insert(particles, {
        x = x, y = y,
        vx = math.Rand(-50, 50),
        vy = math.Rand(-100, -50),
        life = 1,
        size = math.Rand(3, 8),
        color = color or THEME.accent,
        rotation = math.Rand(0, 360)
    })
end

local function UpdateAndDrawParticles()
    local dt = FrameTime()
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 200 * dt
        p.life = p.life - dt * 2
        p.rotation = p.rotation + 180 * dt
        p.size = p.size * (1 - dt)
        if p.life <= 0 then
            table.remove(particles, i)
        else
            local a = p.life * 255
            draw.NoTexture()
            surface.SetDrawColor(ColorAlpha(p.color, a))
            surface.DrawTexturedRectRotated(p.x, p.y, p.size, p.size, p.rotation)
        end
    end
end

-- =========================================================
-- POWIADOMIENIA
-- =========================================================
local notifications = {}

local function AddNotification(text, notifType, duration)
    notifType = notifType or "info"
    duration = duration or 4
    local colors = {
        success = Color(80, 220, 120),
        error   = Color(255, 50, 70),
        info    = Color(220, 40, 60),
        warning = Color(255, 200, 50)
    }
    local icons = { success = "V", error = "X", info = "i", warning = "!" }
    table.insert(notifications, {
        text      = text,
        color     = colors[notifType] or Color(220, 40, 60),
        icon      = icons[notifType] or "*",
        startTime = CurTime(),
        duration  = duration
    })
    if notifType == "success" then
        surface.PlaySound("buttons/button14.wav")
    elseif notifType == "error" then
        surface.PlaySound("buttons/button10.wav")
    else
        surface.PlaySound("UI/buttonclick.wav")
    end
end

hook.Add("HUDPaint", "ZCity_Shop_Notifications", function()
    if #notifications == 0 then return end

    local y = 120
    local toRemove = {}

    for i, notif in ipairs(notifications) do
        local elapsed  = CurTime() - notif.startTime
        local progress = elapsed / notif.duration

        if progress >= 1 then
            table.insert(toRemove, i)
        else
            local a       = 255
            local xOffset = 0

            if elapsed < 0.3 then
                local t = elapsed / 0.3
                xOffset = Lerp(t, 300, 0)
                a       = Lerp(t, 0, 255)
            elseif progress > 0.75 then
                local t = (progress - 0.75) / 0.25
                xOffset = Lerp(t, 0, 300)
                a       = Lerp(t, 255, 0)
            end

            local nW, nH = 350, 50
            local nX = ScrW() - nW - 30 + xOffset
            local nY = y

            draw.RoundedBox(10, nX, nY, nW, nH, Color(20, 10, 10, a * 0.95))
            draw.RoundedBoxEx(10, nX, nY, 6, nH, ColorAlpha(notif.color, a), true, false, true, false)
            draw.RoundedBox(15, nX + 15, nY + 10, 30, 30, ColorAlpha(notif.color, a))
            draw.SimpleText(notif.icon, "ZCity_NotificationIcon", nX + 30, nY + 25, Color(0, 0, 0, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(notif.text, "ZCity_Notification", nX + 55, nY + nH / 2, Color(255, 255, 255, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local barW = nW * (1 - progress)
            draw.RoundedBox(0, nX, nY + nH - 4, barW, 4, ColorAlpha(notif.color, a * 0.7))

            y = y + nH + 12
        end
    end

    for i = #toRemove, 1, -1 do
        table.remove(notifications, toRemove[i])
    end
end)

-- =========================================================
-- TWORZENIE PANELU PRZEDMIOTU (kafelek)
-- =========================================================
local function CreateItemPanel(ent, size, mainpan)
    local item = vgui.Create("DPanel")
    item:SetSize(size, size * 1.15)
    item.hoverAnim = 0
    item.glowAnim  = 0
    item.ent       = ent
    item.isNew     = (ent.NEW == true)
    item.isOnSale  = (ent.SALE and ent.SALE > 0)
    item.isDonate  = (ent.ISDONATE == true)

    local hasItem = false
    if LocalPlayer().PS_HasItem then
        hasItem = LocalPlayer():PS_HasItem(ent.ID)
    end
    item.owned = hasItem

    item.Model = vgui.Create("DModelPanel", item)
    local mdl = item.Model
    mdl:SetPos(8, 8)
    mdl:SetSize(size - 16, size * 0.6)
    mdl:SetModel(ent.MDL or "models/error.mdl")
    mdl:SetMouseInputEnabled(false)

    if ent.CAM_POS and ent.VPos then
        mdl:SetCamPos(ent.CAM_POS)
        mdl:SetLookAt(ent.VPos)
        mdl:SetFOV(ent.FOV or 25)
    elseif IsPlayerModelItem(ent) then
        mdl:SetLookAt(Vector(0, 0, 58))
        mdl:SetCamPos(Vector(45, 0, 58))
        mdl:SetFOV(20)
    else
        mdl:SetLookAt(ent.VPos or Vector(0, 0, 0))
        mdl:SetCamPos(ent.CAM_POS or Vector(50, 0, 0))
        mdl:SetFOV(ent.FOV or 25)
    end

    timer.Simple(0.1, function()
        if not IsValid(mdl) or not IsValid(mdl.Entity) then return end
        ApplyModelProperties(mdl.Entity, ent)

        if IsPlayerModelItem(ent) and not ent.CAM_POS then
            local entity = mdl.Entity
            entity:SetupBones()
            local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
            if headBone and headBone >= 0 then
                local matrix = entity:GetBoneMatrix(headBone)
                if matrix then
                    local headPos = matrix:GetTranslation()
                    local bodyCenter = headPos * 0.65
                    mdl:SetLookAt(bodyCenter)
                    mdl:SetCamPos(bodyCenter + Vector(50, 0, 0))
                    mdl:SetFOV(22)
                end
            end
        elseif not ent.CAM_POS then
            -- [FIX] Auto-detect kamera dla kafelkow akcesoriow
            AutoDetectModelCamera(mdl)
        end
    end)

    local rotationAngle = math.random(0, 360)
    function mdl:LayoutEntity(Entity)
        if not IsValid(Entity) then return end
        rotationAngle = rotationAngle + FrameTime() * 25
        Entity:SetAngles(Angle(0, rotationAngle, 0))
    end

    function mdl:Paint(w, h)
        if not IsValid(self.Entity) then return end
        local x, y = self:LocalToScreen(0, 0)
        self:LayoutEntity(self.Entity)
        local ang = self.aLookAngle or (self.vLookatPos - self.vCamPos):Angle()
        cam.Start3D(self.vCamPos, ang, self.fFOV, x, y, w, h, 5, self.FarZ)
            render.SuppressEngineLighting(true)
            render.SetLightingOrigin(self.Entity:GetPos())
            render.ResetModelLighting(0.3, 0.3, 0.35)
            render.SetModelLighting(0, 0.9, 0.9, 1.0)
            render.SetModelLighting(1, 0.5, 0.5, 0.6)
            render.SetColorModulation(1, 1, 1)
            render.SetBlend((self:GetAlpha() / 255))
            self:DrawModel()
            render.SuppressEngineLighting(false)
        cam.End3D()
    end

    item.NameLabel = vgui.Create("DLabel", item)
    item.NameLabel:SetPos(8, size * 0.62)
    item.NameLabel:SetSize(size - 16, 22)
    item.NameLabel:SetText(ent.NAME or "Nieznany")
    item.NameLabel:SetFont("ZCity_ItemName")
    item.NameLabel:SetTextColor(THEME.text_white)
    item.NameLabel:SetContentAlignment(5)

    item.PriceLabel = vgui.Create("DLabel", item)
    item.PriceLabel:SetPos(8, size * 0.72)
    item.PriceLabel:SetSize(size - 16, 18)

    local priceText, priceColor = "", THEME.text_gray
    if hasItem then
        priceText  = "POSIADANE"
        priceColor = THEME.accent_green
    elseif ent.ISDONATE then
        priceText  = ent.PRICE .. " DZP [PREMIUM]"
        priceColor = THEME.accent_gold
    else
        priceText  = ent.PRICE .. " ZP"
        priceColor = THEME.accent_secondary
    end
    item.PriceLabel:SetText(priceText)
    item.PriceLabel:SetFont("ZCity_Price")
    item.PriceLabel:SetTextColor(priceColor)
    item.PriceLabel:SetContentAlignment(5)

    item.ViewBtn = vgui.Create("DButton", item)
    item.ViewBtn:SetPos(8, size * 0.85)
    item.ViewBtn:SetSize((size - 24) / 2, 28)
    item.ViewBtn:SetText("PODGLAD")
    item.ViewBtn:SetFont("ZCity_Button")
    item.ViewBtn:SetTextColor(THEME.text_white)
    item.ViewBtn.hoverAnim = 0

    function item.ViewBtn:DoClick()
        if not IsValid(mainpan) then return end
        surface.PlaySound("UI/buttonclick.wav")
        mainpan:SetPreviewItem(ent)
        local px, py = self:LocalToScreen(self:GetWide() / 2, self:GetTall() / 2)
        for i = 1, 5 do CreateParticle(px, py, THEME.accent) end
    end

    function item.ViewBtn:Paint(w, h)
        self.hoverAnim = Lerp(FrameTime() * 12, self.hoverAnim, self:IsHovered() and 1 or 0)
        draw.RoundedBox(6, 0, 0, w, h, LerpColor(self.hoverAnim, THEME.bg_button, THEME.accent))
    end

    item.BuyBtn = vgui.Create("DButton", item)
    item.BuyBtn:SetPos(8 + (size - 24) / 2 + 8, size * 0.85)
    item.BuyBtn:SetSize((size - 24) / 2, 28)
    item.BuyBtn:SetFont("ZCity_Button")
    item.BuyBtn.hoverAnim  = 0
    item.BuyBtn.ent        = ent
    item.BuyBtn.owned      = hasItem
    item.BuyBtn.parentItem = item

    if hasItem then
        item.BuyBtn:SetText("POSIADANE")
        item.BuyBtn:SetTextColor(THEME.accent_green)
    else
        item.BuyBtn:SetText("KUP")
        item.BuyBtn:SetTextColor(THEME.text_white)
    end

    function item.BuyBtn:DoClick()
        if self.InWait then return end
        local currentlyOwned = LocalPlayer().PS_HasItem and LocalPlayer():PS_HasItem(self.ent.ID)
        if currentlyOwned then
            surface.PlaySound("buttons/button10.wav")
            AddNotification("Juz posiadasz ten przedmiot!", "warning")
            return
        end

        surface.PlaySound("UI/buttonclick.wav")
        self:SetText("...")
        self:SetTextColor(THEME.text_gray)
        self.InWait = true

        if PLUGIN.SendNET then
            PLUGIN:SendNET("BuyItem", { self.ent.ID }, function(data)
                if not IsValid(self) then return end
                local nowOwned = LocalPlayer().PS_HasItem and LocalPlayer():PS_HasItem(self.ent.ID)
                if nowOwned then
                    self:SetText("POSIADANE")
                    self:SetTextColor(THEME.accent_green)
                    self.owned = true
                    if IsValid(self.parentItem) and IsValid(self.parentItem.PriceLabel) then
                        self.parentItem.PriceLabel:SetText("POSIADANE")
                        self.parentItem.PriceLabel:SetTextColor(THEME.accent_green)
                        self.parentItem.owned = true
                    end
                    local px, py = self:LocalToScreen(self:GetWide() / 2, self:GetTall() / 2)
                    for i = 1, 15 do CreateParticle(px, py, THEME.accent_green) end
                    AddNotification("Zakupiono: " .. (self.ent.NAME or "przedmiot"), "success")
                else
                    self:SetText("KUP")
                    self:SetTextColor(THEME.text_white)
                    AddNotification("Nie udalo sie kupic przedmiotu!", "error")
                end
                if IsValid(mainpan) then mainpan:Update(data) end
                self.InWait = false
            end)
        else
            self:SetText("KUP")
            self:SetTextColor(THEME.text_white)
            self.InWait = false
        end
    end

    function item.BuyBtn:Paint(w, h)
        self.hoverAnim = Lerp(FrameTime() * 12, self.hoverAnim, self:IsHovered() and 1 or 0)
        local currentlyOwned = LocalPlayer().PS_HasItem and LocalPlayer():PS_HasItem(self.ent.ID)
        local baseCol  = (self.owned or currentlyOwned) and ColorAlpha(THEME.accent_green, 150) or THEME.accent
        local hoverCol = (self.owned or currentlyOwned) and THEME.accent_green or THEME.accent_hover
        local col = LerpColor(self.hoverAnim, baseCol, hoverCol)
        if self.hoverAnim > 0.1 and not self.owned and not currentlyOwned then
            DrawGlowingBox(6, 0, 0, w, h, col, 4, 20 * self.hoverAnim)
        else
            draw.RoundedBox(6, 0, 0, w, h, col)
        end
    end

    function item:Paint(w, h)
        self.hoverAnim = Lerp(FrameTime() * 10, self.hoverAnim, self:IsHovered() and 1 or 0)
        self.glowAnim  = Lerp(FrameTime() * 6, self.glowAnim, self:IsHovered() and 1 or 0)

        draw.RoundedBox(10, 4, 4, w, h, THEME.shadow)

        if self.glowAnim > 0.05 then
            local glowCol = self.owned and THEME.accent_green or (self.isDonate and THEME.accent_gold or THEME.accent)
            for i = 3, 1, -1 do
                draw.RoundedBox(10 + i, -i * 2, -i * 2, w + i * 4, h + i * 4, ColorAlpha(glowCol, 15 * self.glowAnim * (4 - i)))
            end
        end

        draw.RoundedBox(10, 0, 0, w, h, LerpColor(self.hoverAnim, THEME.bg_item, THEME.bg_item_hover))

        local accentCol = self.owned and THEME.accent_green or (self.isDonate and THEME.accent_gold or THEME.accent)
        draw.RoundedBoxEx(10, 0, 0, w, 4, ColorAlpha(accentCol, 180 + 75 * self.hoverAnim), true, true, false, false)

        if self.isDonate and not self.owned then
            draw.RoundedBox(4, w - 65, 8, 60, 18, THEME.accent_gold)
            draw.SimpleText("PREMIUM", "ZCity_Category", w - 35, 17, THEME.bg_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif self.isNew then
            draw.RoundedBox(4, w - 50, 8, 45, 18, THEME.accent_green)
            draw.SimpleText("NEW", "ZCity_Category", w - 27, 17, THEME.bg_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if self.owned then
            draw.RoundedBox(4, 5, 8, 70, 18, THEME.accent_green)
            draw.SimpleText("POSIADANE", "ZCity_Category", 40, 17, THEME.bg_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    return item
end

-- =========================================================
-- GLOWNY PANEL SKLEPU
-- =========================================================
local PANEL = {}

function PANEL:StartMusic()
    if self.MusicStation then return end
    sound.PlayURL(MUSIC_URL, "noblock", function(station, errCode, errStr)
        if IsValid(station) and IsValid(self) then
            station:SetVolume(MUSIC_VOLUME)
            station:Play()
            station:EnableLooping(true)
            self.MusicStation = station
        end
    end)
end

function PANEL:StopMusic()
    if IsValid(self.MusicStation) then
        self.MusicStation:Stop()
        self.MusicStation = nil
    end
end

function PANEL:OnRemove()
    self:StopMusic()
end

function PANEL:Init()
    self.Itensens        = {}
    self.searchQuery     = ""
    self.currentCategory = "all"
    self.sortMode        = "default"
    self.itemPanels      = {}

    self:StartMusic()

    local windowW = math.min(ScrW() * 0.92, 1700)
    local windowH = math.min(ScrH() * 0.9, 1000)

    self:SetSize(windowW, windowH)
    self:Center()
    self:SetTitle("")
    self:SetDraggable(true)
    self:ShowCloseButton(false)
    self:SetAlpha(0)

    local startY = self:GetY()
    self:SetY(ScrH())

    local mainpan = self

    -- HEADER
    self.Header = vgui.Create("DPanel", self)
    self.Header:Dock(TOP)
    self.Header:SetTall(70)
    self.Header:DockMargin(15, 10, 15, 0)

    function self.Header:Paint(w, h)
        draw.RoundedBox(12, 0, 0, w, h, THEME.bg_panel)
        surface.SetDrawColor(ColorAlpha(THEME.accent, 30))
        surface.SetMaterial(gradientMatU)
        surface.DrawTexturedRect(0, 0, w, h / 2)
    end

    local title = vgui.Create("DLabel", self.Header)
    title:SetPos(20, 10)
    title:SetText("[ Z-CITY SHOP ]")
    title:SetFont("ZCity_Title")
    title:SetTextColor(THEME.text_white)
    title:SizeToContents()

    local subtitle = vgui.Create("DLabel", self.Header)
    subtitle:SetPos(20, 42)
    subtitle:SetText("Personalizuj swoja postac - " .. table.Count(PLUGIN.Items or {}) .. " przedmiotow")
    subtitle:SetFont("ZCity_Subtitle")
    subtitle:SetTextColor(THEME.text_dark)
    subtitle:SizeToContents()

    self.PointsPanel = vgui.Create("DPanel", self.Header)
    self.PointsPanel:SetSize(280, 50)
    function self.PointsPanel:Think() self:SetPos(self:GetParent():GetWide() - 420, 10) end
    function self.PointsPanel:Paint(w, h) draw.RoundedBox(10, 0, 0, w, h, THEME.bg_dark) end

    self.moneyTxt = vgui.Create("DLabel", self.PointsPanel)
    self.moneyTxt:SetPos(15, 6)
    self.moneyTxt:SetText("0 ZP")
    self.moneyTxt:SetFont("ZCity_Points")
    self.moneyTxt:SetTextColor(THEME.accent_secondary)
    self.moneyTxt:SizeToContents()

    self.DmoneyTxt = vgui.Create("DLabel", self.PointsPanel)
    self.DmoneyTxt:SetPos(15, 30)
    self.DmoneyTxt:SetText("0 DZP")
    self.DmoneyTxt:SetFont("ZCity_Subtitle")
    self.DmoneyTxt:SetTextColor(THEME.accent_gold)
    self.DmoneyTxt:SizeToContents()

    local donateBtn = vgui.Create("DButton", self.PointsPanel)
    donateBtn:SetPos(175, 8)
    donateBtn:SetSize(95, 34)
    donateBtn:SetText("DOLADUJ")
    donateBtn:SetFont("ZCity_Button")
    donateBtn:SetTextColor(THEME.bg_dark)
    donateBtn.hoverAnim = 0
    function donateBtn:DoClick() surface.PlaySound("UI/buttonclick.wav") AltDonate() end
    function donateBtn:Paint(w, h)
        self.hoverAnim = Lerp(FrameTime() * 12, self.hoverAnim, self:IsHovered() and 1 or 0)
        local col = LerpColor(self.hoverAnim, THEME.accent_gold, Color(255, 230, 100))
        if self.hoverAnim > 0.1 then
            DrawGlowingBox(8, 0, 0, w, h, col, 6, 30 * self.hoverAnim)
        else
            draw.RoundedBox(8, 0, 0, w, h, col)
        end
    end

    local themeBtn = vgui.Create("DButton", self.Header)
    themeBtn:SetSize(35, 35)
    themeBtn:SetText("T")
    themeBtn:SetFont("ZCity_Subtitle")
    themeBtn:SetTextColor(THEME.text_white)
    themeBtn.hoverAnim = 0
    function themeBtn:Think() self:SetPos(self:GetParent():GetWide() - 90, 18) end
    function themeBtn:DoClick()
        surface.PlaySound("UI/buttonclick.wav")
        local menu = DermaMenu()
        for name, _ in pairs(THEMES) do
            local opt = menu:AddOption(name, function()
                currentThemeName = name
                THEME = THEMES[name]
                SaveTheme(name)
                if IsValid(PLUGIN.MenuPanel) then PLUGIN.MenuPanel:Remove() end
                timer.Simple(0.1, function() RunConsoleCommand("hg_pointshop") end)
            end)
            if name == currentThemeName then opt:SetIcon("icon16/accept.png") end
        end
        menu:Open()
    end
    function themeBtn:Paint(w, h)
        self.hoverAnim = Lerp(FrameTime() * 12, self.hoverAnim, self:IsHovered() and 1 or 0)
        draw.RoundedBox(8, 0, 0, w, h, LerpColor(self.hoverAnim, THEME.bg_button, THEME.accent))
    end

    local closeBtn = vgui.Create("DButton", self.Header)
    closeBtn:SetSize(35, 35)
    closeBtn:SetText("X")
    closeBtn:SetFont("ZCity_Subtitle")
    closeBtn:SetTextColor(THEME.text_gray)
    closeBtn.hoverAnim = 0
    function closeBtn:Think() self:SetPos(self:GetParent():GetWide() - 50, 18) end
    function closeBtn:DoClick() surface.PlaySound("UI/buttonclick.wav") mainpan:Close() end
    function closeBtn:Paint(w, h)
        self.hoverAnim = Lerp(FrameTime() * 12, self.hoverAnim, self:IsHovered() and 1 or 0)
        draw.RoundedBox(8, 0, 0, w, h, LerpColor(self.hoverAnim, THEME.bg_button, THEME.accent_red))
    end

    -- LEWY PANEL — PREVIEW
    self.LeftPanel = vgui.Create("DPanel", self)
    self.LeftPanel:Dock(LEFT)
    self.LeftPanel:SetWide(windowW * 0.28)
    self.LeftPanel:DockMargin(15, 10, 0, 15)
    function self.LeftPanel:Paint(w, h) draw.RoundedBox(12, 0, 0, w, h, THEME.bg_panel) end

    local previewHeader = vgui.Create("DPanel", self.LeftPanel)
    previewHeader:Dock(TOP)
    previewHeader:SetTall(40)
    previewHeader:DockMargin(10, 10, 10, 0)
    function previewHeader:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, THEME.bg_dark)
        draw.SimpleText("[ PODGLAD 3D ]", "ZCity_Subtitle", 15, h / 2, THEME.text_gray, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.PreviewContainer = vgui.Create("DPanel", self.LeftPanel)
    self.PreviewContainer:Dock(FILL)
    self.PreviewContainer:DockMargin(10, 10, 10, 10)
    function self.PreviewContainer:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, THEME.bg_dark)
        surface.SetDrawColor(THEME.accent)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    -- MODEL PREVIEW 3D
    self.ModelPreview = vgui.Create("DModelPanel", self.PreviewContainer)
    self.ModelPreview:Dock(FILL)
    self.ModelPreview:DockMargin(5, 5, 5, 80)
    self.ModelPreview:SetModel("models/player/group01/male_01.mdl")
    self.ModelPreview:SetLookAt(Vector(0, 0, 35))
    self.ModelPreview:SetCamPos(Vector(80, 0, 40))
    self.ModelPreview:SetFOV(45)
    self.ModelPreview.rotationAngle = 0
    self.ModelPreview.zoomLevel     = 1
    self.ModelPreview._baseCamPos   = Vector(80, 0, 40)
    self.ModelPreview._baseLookAt   = Vector(0, 0, 35)
    self.ModelPreview._baseFOV      = 45

    function self.ModelPreview:DragMousePress()
        self.pressing = true
        self.lastX = gui.MousePos()
    end

    function self.ModelPreview:DragMouseRelease()
        self.pressing = false
    end

    function self.ModelPreview:LayoutEntity(Entity)
        if not IsValid(Entity) then return end

        if self.pressing then
            local mx = gui.MousePos()
            self.rotationAngle = self.rotationAngle - (mx - (self.lastX or mx)) * 0.5
            self.lastX = mx
        else
            self.rotationAngle = self.rotationAngle + FrameTime() * 15
        end
        Entity:SetAngles(Angle(0, self.rotationAngle, 0))
    end

    function self.ModelPreview:OnMouseWheeled(delta)
        self.zoomLevel = math.Clamp((self.zoomLevel or 1) - delta * 0.08, 0.1, 6.0)
        local base   = self._baseCamPos or Vector(80, 0, 40)
        local lookAt = self._baseLookAt or Vector(0, 0, 35)
        local dir    = base - lookAt
        self:SetCamPos(lookAt + dir * self.zoomLevel)
    end

    -- INFO POD PREVIEW
    self.PreviewInfo = vgui.Create("DPanel", self.PreviewContainer)
    self.PreviewInfo:Dock(BOTTOM)
    self.PreviewInfo:SetTall(70)
    self.PreviewInfo:DockMargin(5, 0, 5, 5)
    self.PreviewName     = ""
    self.PreviewPrice    = 0
    self.PreviewIsDonate = false
    self.PreviewOwned    = false

    function self.PreviewInfo:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, ColorAlpha(THEME.bg_panel, 200))
        draw.SimpleText(mainpan.PreviewName or "Wybierz przedmiot", "ZCity_PreviewName", w / 2, 18, THEME.text_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local priceText, priceColor = "", THEME.text_gray
        if mainpan.PreviewOwned then
            priceText, priceColor = "POSIADANE", THEME.accent_green
        elseif mainpan.PreviewIsDonate then
            priceText, priceColor = mainpan.PreviewPrice .. " DZP [PREMIUM]", THEME.accent_gold
        elseif mainpan.PreviewPrice > 0 then
            priceText, priceColor = mainpan.PreviewPrice .. " ZP", THEME.accent_secondary
        end
        draw.SimpleText(priceText, "ZCity_PreviewPrice", w / 2, 42, priceColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Scroll = Zoom | Przeciagnij = Obroc", "ZCity_Category", w / 2, 60, THEME.text_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- SRODKOWY PANEL — FILTRY
    self.FilterPanel = vgui.Create("DPanel", self)
    self.FilterPanel:Dock(LEFT)
    self.FilterPanel:SetWide(170)
    self.FilterPanel:DockMargin(10, 10, 0, 15)
    function self.FilterPanel:Paint(w, h) draw.RoundedBox(12, 0, 0, w, h, THEME.bg_panel) end

    local searchLabel = vgui.Create("DLabel", self.FilterPanel)
    searchLabel:Dock(TOP)
    searchLabel:SetTall(25)
    searchLabel:DockMargin(10, 10, 10, 0)
    searchLabel:SetText("[ SZUKAJ ]")
    searchLabel:SetFont("ZCity_Category")
    searchLabel:SetTextColor(THEME.text_gray)

    local searchPanel = vgui.Create("DPanel", self.FilterPanel)
    searchPanel:Dock(TOP)
    searchPanel:SetTall(35)
    searchPanel:DockMargin(10, 5, 10, 0)
    function searchPanel:Paint(w, h) draw.RoundedBox(6, 0, 0, w, h, THEME.bg_dark) end

    self.SearchEntry = vgui.Create("DTextEntry", searchPanel)
    self.SearchEntry:Dock(FILL)
    self.SearchEntry:DockMargin(8, 5, 8, 5)
    self.SearchEntry:SetFont("ZCity_Search")
    self.SearchEntry:SetTextColor(THEME.text_white)
    self.SearchEntry:SetDrawBackground(false)
    self.SearchEntry:SetPlaceholderText("Wpisz nazwe...")
    function self.SearchEntry:OnChange()
        mainpan.searchQuery = self:GetValue():lower()
        mainpan:FilterItems()
    end

    local sortLabel = vgui.Create("DLabel", self.FilterPanel)
    sortLabel:Dock(TOP)
    sortLabel:SetTall(25)
    sortLabel:DockMargin(10, 10, 10, 0)
    sortLabel:SetText("[ SORTUJ ]")
    sortLabel:SetFont("ZCity_Category")
    sortLabel:SetTextColor(THEME.text_gray)

    local sortCombo = vgui.Create("DComboBox", self.FilterPanel)
    sortCombo:Dock(TOP)
    sortCombo:SetTall(30)
    sortCombo:DockMargin(10, 5, 10, 0)
    sortCombo:SetValue("Domyslne")
    sortCombo:AddChoice("Domyslne",      "default")
    sortCombo:AddChoice("Nazwa A-Z",     "name_asc")
    sortCombo:AddChoice("Nazwa Z-A",     "name_desc")
    sortCombo:AddChoice("Cena rosnaco",  "price_asc")
    sortCombo:AddChoice("Cena malejaco", "price_desc")
    sortCombo:AddChoice("Posiadane",     "owned")
    sortCombo:SetFont("ZCity_Category")
    sortCombo:SetTextColor(THEME.text_white)
    function sortCombo:OnSelect(_, _, data) mainpan.sortMode = data mainpan:FilterItems() end
    function sortCombo:Paint(w, h) draw.RoundedBox(6, 0, 0, w, h, THEME.bg_button) end

    local catLabel = vgui.Create("DLabel", self.FilterPanel)
    catLabel:Dock(TOP)
    catLabel:SetTall(25)
    catLabel:DockMargin(10, 15, 10, 0)
    catLabel:SetText("[ KATEGORIE ]")
    catLabel:SetFont("ZCity_Category")
    catLabel:SetTextColor(THEME.text_gray)

    self.CategoryButtons = {}
    local catScroll = vgui.Create("DScrollPanel", self.FilterPanel)
    catScroll:Dock(FILL)
    catScroll:DockMargin(10, 5, 10, 10)
    local sbar = catScroll:GetVBar()
    sbar:SetWide(4)
    sbar:SetHideButtons(true)
    function sbar:Paint(w, h) draw.RoundedBox(2, 0, 0, w, h, THEME.bg_dark) end
    function sbar.btnGrip:Paint(w, h) draw.RoundedBox(2, 0, 0, w, h, THEME.accent) end

    table.sort(SHOP_CATEGORIES, function(a, b) return a.order < b.order end)

    local categoryCounts = { all = table.Count(PLUGIN.Items or {}) }
    for _, itemData in pairs(PLUGIN.Items or {}) do
        local cat = GetItemCategory(itemData)
        categoryCounts[cat] = (categoryCounts[cat] or 0) + 1
        if itemData.ISDONATE then
            categoryCounts["premium"] = (categoryCounts["premium"] or 0) + 1
        end
    end

    for _, cat in ipairs(SHOP_CATEGORIES) do
        local count = categoryCounts[cat.id] or 0
        if count > 0 or cat.id == "all" then
            local catBtn = vgui.Create("DButton", catScroll)
            catBtn:Dock(TOP)
            catBtn:SetTall(36)
            catBtn:DockMargin(0, 3, 0, 0)
            catBtn:SetText("")
            catBtn.catKey    = cat.id
            catBtn.catData   = cat
            catBtn.hoverAnim = 0
            catBtn.isActive  = (cat.id == "all")
            catBtn.count     = count
            self.CategoryButtons[cat.id] = catBtn

            function catBtn:DoClick()
                surface.PlaySound("UI/buttonclick.wav")
                mainpan.currentCategory = self.catKey
                for _, btn in pairs(mainpan.CategoryButtons) do btn.isActive = false end
                self.isActive = true
                mainpan:FilterItems()
            end

            function catBtn:Paint(w, h)
                self.hoverAnim = Lerp(FrameTime() * 12, self.hoverAnim, (self:IsHovered() or self.isActive) and 1 or 0)
                local catColor = self.catData.color or THEME.accent
                draw.RoundedBox(6, 0, 0, w, h, LerpColor(self.hoverAnim, THEME.bg_dark, catColor))
                if self.isActive then
                    surface.SetDrawColor(catColor)
                    surface.DrawRect(0, 0, 4, h)
                end
                draw.RoundedBox(4, 6, 6, 24, 24, self.isActive and catColor or THEME.bg_button)
                draw.SimpleText(self.catData.icon, "ZCity_CategoryIcon", 18, 18, self.isActive and THEME.bg_dark or THEME.text_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(self.catData.name, "ZCity_Category", 36, 10, THEME.text_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText("(" .. self.count .. ")", "ZCity_Category", 36, 22, THEME.text_dark, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end

    -- PRAWY PANEL — PRZEDMIOTY
    self.RightPanel = vgui.Create("DPanel", self)
    self.RightPanel:Dock(FILL)
    self.RightPanel:DockMargin(10, 10, 15, 15)
    function self.RightPanel:Paint(w, h) draw.RoundedBox(12, 0, 0, w, h, THEME.bg_panel) end

    local itemsHeader = vgui.Create("DPanel", self.RightPanel)
    itemsHeader:Dock(TOP)
    itemsHeader:SetTall(40)
    itemsHeader:DockMargin(10, 10, 10, 0)
    function itemsHeader:Paint(w, h) draw.RoundedBox(8, 0, 0, w, h, THEME.bg_dark) end

    self.ItemCountLabel = vgui.Create("DLabel", itemsHeader)
    self.ItemCountLabel:Dock(FILL)
    self.ItemCountLabel:SetFont("ZCity_Subtitle")
    self.ItemCountLabel:SetTextColor(THEME.text_gray)
    self.ItemCountLabel:SetContentAlignment(4)
    self.ItemCountLabel:SetText("  [ PRZEDMIOTY ]")

    self.ItemsScroll = vgui.Create("DScrollPanel", self.RightPanel)
    self.ItemsScroll:Dock(FILL)
    self.ItemsScroll:DockMargin(10, 10, 10, 10)
    local scrollBar = self.ItemsScroll:GetVBar()
    scrollBar:SetWide(6)
    scrollBar:SetHideButtons(true)
    function scrollBar:Paint(w, h) draw.RoundedBox(3, 0, 0, w, h, THEME.bg_dark) end
    function scrollBar.btnGrip:Paint(w, h) draw.RoundedBox(3, 0, 0, w, h, THEME.accent) end

    self.ItemsGrid = vgui.Create("DIconLayout", self.ItemsScroll)
    self.ItemsGrid:Dock(TOP)
    self.ItemsGrid:DockMargin(5, 5, 5, 5)
    self.ItemsGrid:SetSpaceY(10)
    self.ItemsGrid:SetSpaceX(10)

    timer.Simple(0.1, function()
        if IsValid(self) then self:PopulateItems() end
    end)

    self:AlphaTo(255, 0.3, 0)
    self:MoveTo(self:GetX(), startY, 0.4, 0, 0.2)
end

-- =========================================================
-- [FIX] USTAWIENIE PODGLADU PRZEDMIOTU
-- Zawsze pokazuje SAM model przedmiotu (bez postaci gracza).
-- Auto-detect kamera dopasowuje sie do rozmiaru modelu.
-- Dla akcesoriow z hg.Accessories — uzywa accData.model
-- i aplikuje skin/bodygroup/submaterial/scale z danych.
-- =========================================================
function PANEL:SetPreviewItem(ent)
    if not ent then return end

    -- Token chroni przed race condition przy szybkim klikaniu
    local previewToken = {}
    self._previewToken = previewToken

    self.PreviewName     = ent.NAME or "Nieznany"
    self.PreviewPrice    = ent.PRICE or 0
    self.PreviewIsDonate = ent.ISDONATE or false
    self.PreviewOwned    = LocalPlayer().PS_HasItem and LocalPlayer():PS_HasItem(ent.ID) or false
    self.CurrentPreviewItem = ent

    if not IsValid(self.ModelPreview) then return end

    local mdlPath  = ent.MDL or "models/error.mdl"
    local isPModel = IsPlayerModelItem(ent)

    -- Szukaj danych w hg.Accessories (dla modelu/skin/scale)
    local accData = FindAccessoryData(ent.ID, mdlPath)

    -- ===============================
    -- PRZYPADEK 1: AKCESORIUM Z hg.Accessories
    -- Wyswietlamy sam model akcesorium (bez gracza)
    -- z danymi z accData (model, skin, bodygroups, scale, submaterial, kolor)
    -- ===============================
    if accData then
        local accModel = accData.model or mdlPath
        self.ModelPreview:SetModel(accModel)

        -- Tymczasowa kamera — auto-detect nadpisze po zaladowaniu
        self.ModelPreview:SetLookAt(Vector(0, 0, 0))
        self.ModelPreview:SetCamPos(Vector(30, 10, 5))
        self.ModelPreview:SetFOV(35)
        self.ModelPreview._baseCamPos = Vector(30, 10, 5)
        self.ModelPreview._baseLookAt = Vector(0, 0, 0)
        self.ModelPreview._baseFOV    = 35
        self.ModelPreview.zoomLevel   = 1

        timer.Simple(0.05, function()
            if self._previewToken ~= previewToken then return end
            if not IsValid(self.ModelPreview) or not IsValid(self.ModelPreview.Entity) then return end

            local entity = self.ModelPreview.Entity

            -- Skin
            local skinVal = accData.skin or 0
            if isfunction(skinVal) then skinVal = 0 end
            entity:SetSkin(skinVal)

            -- Bodygroups
            if accData.bodygroups then
                entity:SetBodyGroups(accData.bodygroups)
            end

            -- SubMaterial
            if accData.SubMat then
                entity:SetSubMaterial(0, accData.SubMat)
            end

            -- Kolor
            if accData.bSetColor and accData.vecColorOveride then
                local vc = accData.vecColorOveride
                entity:SetColor(Color(vc.x * 255, vc.y * 255, vc.z * 255))
            end

            -- Scale z malepos
            local posData = accData.malepos
            if posData and posData[3] and posData[3] ~= 1 then
                entity:SetModelScale(posData[3], 0)
            end

            -- Takze zastosuj wlasciwosci z definicji przedmiotu
            ApplyModelProperties(entity, ent)

            -- [FIX] ZAWSZE auto-detect kamera dla akcesorium
            -- Dajemy dodatkowy czas na ustawienie renderboxa po scale
            timer.Simple(0.05, function()
                if self._previewToken ~= previewToken then return end
                if not IsValid(self.ModelPreview) or not IsValid(self.ModelPreview.Entity) then return end

                self.ModelPreview.Entity:SetupBones()
                local center, dist = AutoDetectModelCamera(self.ModelPreview)
                if center and dist then
                    self.ModelPreview._baseCamPos = self.ModelPreview:GetCamPos()
                    self.ModelPreview._baseLookAt = center
                end
            end)
        end)

        return
    end

    -- ===============================
    -- PRZYPADEK 2: SKIN POSTACI (playermodel)
    -- ===============================
    if isPModel then
        self.ModelPreview:SetModel(mdlPath)

        local defLookAt = ent.VPos    or Vector(0, 0, 62)
        local defCamPos = ent.CAM_POS or Vector(55, 0, 62)
        local defFov    = ent.FOV     or 20

        local lookAt = Vector(defLookAt.x, defLookAt.y, defLookAt.z - 20)
        local camPos = Vector(defCamPos.x + 25, defCamPos.y, defCamPos.z - 15)

        self.ModelPreview:SetLookAt(lookAt)
        self.ModelPreview:SetCamPos(camPos)
        self.ModelPreview:SetFOV(defFov + 10)
        self.ModelPreview._baseCamPos = camPos
        self.ModelPreview._baseLookAt = lookAt
        self.ModelPreview._baseFOV    = defFov + 10
        self.ModelPreview.zoomLevel   = 1

        timer.Simple(0.05, function()
            if self._previewToken ~= previewToken then return end
            if not IsValid(self.ModelPreview) or not IsValid(self.ModelPreview.Entity) then return end
            ApplyModelProperties(self.ModelPreview.Entity, ent)
        end)

        return
    end

    -- ===============================
    -- PRZYPADEK 3: WSZYSTKO INNE
    -- (bronie, akcesoria bez wpisu w hg.Accessories,
    --  rekawiczki, efekty, inne)
    -- Sam model z auto-detect kamera.
    -- ===============================
    self.ModelPreview:SetModel(mdlPath)

    -- Tymczasowa kamera — auto-detect nadpisze
    self.ModelPreview:SetLookAt(Vector(0, 0, 0))
    self.ModelPreview:SetCamPos(Vector(50, 10, 5))
    self.ModelPreview:SetFOV(30)
    self.ModelPreview._baseCamPos = Vector(50, 10, 5)
    self.ModelPreview._baseLookAt = Vector(0, 0, 0)
    self.ModelPreview._baseFOV    = 30
    self.ModelPreview.zoomLevel   = 1

    timer.Simple(0.05, function()
        if self._previewToken ~= previewToken then return end
        if not IsValid(self.ModelPreview) or not IsValid(self.ModelPreview.Entity) then return end
        ApplyModelProperties(self.ModelPreview.Entity, ent)

        -- [FIX] ZAWSZE uzyj auto-detect dla nie-playermodeli
        timer.Simple(0.05, function()
            if self._previewToken ~= previewToken then return end
            if not IsValid(self.ModelPreview) or not IsValid(self.ModelPreview.Entity) then return end

            self.ModelPreview.Entity:SetupBones()
            local center, dist = AutoDetectModelCamera(self.ModelPreview)
            if center and dist then
                self.ModelPreview._baseCamPos = self.ModelPreview:GetCamPos()
                self.ModelPreview._baseLookAt = center
            end
        end)
    end)
end

-- =========================================================
-- POPULOWANIE PRZEDMIOTOW
-- =========================================================
function PANEL:PopulateItems()
    if not IsValid(self.ItemsGrid) or not IsValid(self.ItemsScroll) then return end
    self.ItemsGrid:Clear()
    self.itemPanels = {}

    local scrollW  = self.ItemsScroll:GetWide() - 25
    local cols     = math.max(1, math.floor(scrollW / 155))
    local itemSize = math.floor((scrollW - (cols - 1) * 10) / cols)

    local sortedItems = {}
    for k, v in pairs(PLUGIN.Items or {}) do
        v._key      = k
        v._category = GetItemCategory(v)
        table.insert(sortedItems, v)
    end

    local sortFunc = {
        ["default"] = function(a, b)
            if (a.ISDONATE and 1 or 0) ~= (b.ISDONATE and 1 or 0) then return (a.ISDONATE and 1 or 0) > (b.ISDONATE and 1 or 0) end
            return (a.NAME or "") < (b.NAME or "")
        end,
        ["name_asc"] = function(a, b)
            if (a.ISDONATE and 1 or 0) ~= (b.ISDONATE and 1 or 0) then return (a.ISDONATE and 1 or 0) > (b.ISDONATE and 1 or 0) end
            return (a.NAME or "") < (b.NAME or "")
        end,
        ["name_desc"] = function(a, b)
            if (a.ISDONATE and 1 or 0) ~= (b.ISDONATE and 1 or 0) then return (a.ISDONATE and 1 or 0) > (b.ISDONATE and 1 or 0) end
            return (a.NAME or "") > (b.NAME or "")
        end,
        ["price_asc"] = function(a, b)
            if (a.ISDONATE and 1 or 0) ~= (b.ISDONATE and 1 or 0) then return (a.ISDONATE and 1 or 0) > (b.ISDONATE and 1 or 0) end
            return (a.PRICE or 0) < (b.PRICE or 0)
        end,
        ["price_desc"] = function(a, b)
            if (a.ISDONATE and 1 or 0) ~= (b.ISDONATE and 1 or 0) then return (a.ISDONATE and 1 or 0) > (b.ISDONATE and 1 or 0) end
            return (a.PRICE or 0) > (b.PRICE or 0)
        end,
        ["owned"] = function(a, b)
            local aOwned = LocalPlayer().PS_HasItem and LocalPlayer():PS_HasItem(a.ID) and 1 or 0
            local bOwned = LocalPlayer().PS_HasItem and LocalPlayer():PS_HasItem(b.ID) and 1 or 0
            if aOwned ~= bOwned then return aOwned > bOwned end
            if (a.ISDONATE and 1 or 0) ~= (b.ISDONATE and 1 or 0) then return (a.ISDONATE and 1 or 0) > (b.ISDONATE and 1 or 0) end
            return (a.NAME or "") < (b.NAME or "")
        end,
    }

    table.sort(sortedItems, sortFunc[self.sortMode] or sortFunc["default"])

    local visibleCount = 0
    for _, itemData in ipairs(sortedItems) do
        local visible = true
        if self.currentCategory ~= "all" then
            if self.currentCategory == "premium" then
                visible = itemData.ISDONATE
            else
                visible = itemData._category == self.currentCategory
            end
        end
        if self.searchQuery ~= "" and not string.find((itemData.NAME or ""):lower(), self.searchQuery, 1, true) then
            visible = false
        end
        if visible then
            local itemPanel = CreateItemPanel(itemData, itemSize, self)
            self.ItemsGrid:Add(itemPanel)
            self.itemPanels[itemData._key] = itemPanel
            visibleCount = visibleCount + 1
        end
    end

    self.ItemsGrid:SetTall(math.ceil(visibleCount / cols) * (itemSize * 1.15 + 10) + 20)
    if IsValid(self.ItemCountLabel) then
        self.ItemCountLabel:SetText("  [ PRZEDMIOTY ] (" .. visibleCount .. "/" .. table.Count(PLUGIN.Items or {}) .. ")")
    end
end

function PANEL:FilterItems()
    self:PopulateItems()
end

function PANEL:Update(data)
    self.Itensens = data or self.Itensens
    if IsValid(self.moneyTxt) then
        self.moneyTxt:SetText((self.Itensens.points or 0) .. " ZP")
        self.moneyTxt:SizeToContents()
    end
    if IsValid(self.DmoneyTxt) then
        self.DmoneyTxt:SetText((self.Itensens.donpoints or 0) .. " DZP")
        self.DmoneyTxt:SizeToContents()
    end
end

function PANEL:Paint(w, h)
    DrawBlur(self, 6)
    draw.RoundedBox(14, 0, 0, w, h, THEME.bg_dark)
    surface.SetDrawColor(ColorAlpha(THEME.accent, 20))
    surface.SetMaterial(gradientMatU)
    surface.DrawTexturedRect(0, 0, w, h * 0.3)
    surface.SetDrawColor(ColorAlpha(THEME.accent, 40))
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    UpdateAndDrawParticles()
end

function PANEL:Close()
    self:StopMusic()
    self:AlphaTo(0, 0.2, 0)
    self:MoveTo(self:GetX(), ScrH(), 0.3, 0, 0.1, function()
        if IsValid(self) then self:Remove() end
    end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

function PANEL:OnKeyCodePressed(key)
    if key == KEY_ESCAPE then
        self:Close()
        return true
    end
end

vgui.Register("HG_PointShop", PANEL, "DFrame")

-- =========================================================
-- KOMENDA
-- =========================================================
local function OpenPointShop()
    if not PLUGIN then return end
    if not PLUGIN.SendNET then
        if IsValid(PLUGIN.MenuPanel) then PLUGIN.MenuPanel:Remove() end
        PLUGIN.MenuPanel = vgui.Create("HG_PointShop")
        if IsValid(PLUGIN.MenuPanel) then
            PLUGIN.MenuPanel:MakePopup()
            PLUGIN.MenuPanel:Update({ points = 0, donpoints = 0 })
        end
        return
    end
    PLUGIN:SendNET("SendPointShopVars", nil, function(data)
        if IsValid(PLUGIN.MenuPanel) then PLUGIN.MenuPanel:Remove() end
        PLUGIN.MenuPanel = vgui.Create("HG_PointShop")
        if IsValid(PLUGIN.MenuPanel) then
            PLUGIN.MenuPanel:MakePopup()
            PLUGIN.MenuPanel:Update(data)
        end
    end)
end

timer.Simple(0, function()
    concommand.Add("hg_pointshop", OpenPointShop)
    print("[ZCity Shop] Zaladowano! (FIXED version v2)")
end)

hook.Add("PlayerBindPress", "ZCity_PointShop_Bind", function(ply, bind, pressed)
    if pressed and bind == "gm_showspare1" then
        OpenPointShop()
        return true
    end
end)

hook.Add("OnScreenSizeChanged", "ZCity_PointShop_Fonts", CreateScaledFonts)