hg = hg or {}
hg.Appearance = hg.Appearance or {}
hg.Accessories = hg.Accessories or {}
hg.PointShop = hg.PointShop or {}

local PANEL = {}

local MUSIC_URL = "https://raw.githubusercontent.com/Ponczo266/mp3/main/006TobyFox.wav"
local MUSIC_VOLUME = 0.65

local Particles = {}
local PARTICLE_COUNT = 60

local function InitParticles()
    Particles = {}
    for i = 1, PARTICLE_COUNT do
        Particles[i] = {
            x = math.random(0, ScrW()),
            y = math.random(0, ScrH()),
            size = math.random(2, 5),
            speed = math.random(20, 60),
            alpha = math.random(50, 150),
            speedX = math.random(-20, 20)
        }
    end
end

local function UpdateParticles()
    local ft = FrameTime()
    for i, p in ipairs(Particles) do
        p.y = p.y + p.speed * ft
        p.x = p.x + p.speedX * ft
        if p.y > ScrH() then
            p.y = -10
            p.x = math.random(0, ScrW())
        end
        if p.x > ScrW() then p.x = 0 end
        if p.x < 0 then p.x = ScrW() end
    end
end

local function DrawParticles()
    for i, p in ipairs(Particles) do
        surface.SetDrawColor(180, 30, 30, p.alpha)
        surface.DrawRect(p.x, p.y, p.size, p.size)
    end
end

InitParticles()

local Theme = {
    bg = Color(15, 15, 20, 255),
    bgLight = Color(25, 25, 35, 255),
    bgLighter = Color(35, 35, 45, 255),
    bgDark = Color(10, 10, 15, 255),
    accent = Color(180, 30, 30, 255),
    accentHover = Color(200, 50, 50, 255),
    accentDark = Color(120, 20, 20, 255),
    success = Color(30, 150, 30, 255),
    successHover = Color(40, 180, 40, 255),
    text = Color(255, 255, 255, 255),
    textDim = Color(150, 150, 160, 255),
    textDark = Color(100, 100, 110, 255),
    border = Color(60, 60, 70, 255),
    borderLight = Color(80, 80, 90, 255),
    borderAccent = Color(180, 30, 30, 100),
    owned = Color(30, 150, 30, 255),
    rarityCommon = Color(150, 150, 150, 255),
    rarityUncommon = Color(30, 180, 30, 255),
    rarityRare = Color(30, 100, 200, 255),
    rarityEpic = Color(150, 50, 200, 255),
    rarityLegendary = Color(230, 180, 30, 255),
    scrollBg = Color(20, 20, 25, 255),
    scrollGrip = Color(60, 60, 70, 255),
    scrollGripHover = Color(80, 80, 90, 255),
    search = Color(30, 30, 40, 255),
    searchBorder = Color(70, 70, 80, 255),
}

local function PSHas(id)
    local lp = LocalPlayer()
    if not IsValid(lp) then return false end
    if id == nil then return false end
    if lp.PS_HasItem then
        if lp:PS_HasItem(id) then return true end
        if isnumber(id) and lp:PS_HasItem(tostring(id)) then return true end
        if isstring(id) then
            local n = tonumber(id)
            if n and lp:PS_HasItem(n) then return true end
        end
    end
    if lp.PS2_HasItem and lp:PS2_HasItem(id) then return true end
    if lp.PS2_HasItemEquipped and lp:PS2_HasItemEquipped(id) then return true end
    if hg.PointShop then
        if hg.PointShop.OwnedItems then
            if hg.PointShop.OwnedItems[id] then return true end
            if isnumber(id) and hg.PointShop.OwnedItems[tostring(id)] then return true end
            if isstring(id) then
                local n = tonumber(id)
                if n and hg.PointShop.OwnedItems[n] then return true end
            end
        end
        if hg.PointShop.PlayerItems then
            if hg.PointShop.PlayerItems[id] then return true end
            if isnumber(id) and hg.PointShop.PlayerItems[tostring(id)] then return true end
            if isstring(id) then
                local n = tonumber(id)
                if n and hg.PointShop.PlayerItems[n] then return true end
            end
        end
        if hg.PointShop.Items then
            for _, item in pairs(hg.PointShop.Items) do
                local itemID = item.ID or item.id or item.psItemID
                if itemID == id and (item.bought or item.owned or item.Bought or item.Owned) then
                    return true
                end
            end
        end
    end
    return false
end

local function CanUseAccessory(key)
    if not key or key == "" or key == "none" then return true end
    local acc = hg.Accessories and hg.Accessories[key]
    if not acc then return false end
    if acc.disallowinappearance then return false end
    if acc.free or acc.bFree or acc.noPointShop then return true end
    if acc.bPointShop == false then return true end
    if not acc.bPointShop and not acc.psItemID and not acc.pointshopID then return true end
    local psid = acc.psItemID or acc.pointshopID or acc.ID or acc.id
    if psid and PSHas(psid) then return true end
    if PSHas(key) then return true end
    return false
end

local function CanUseModel(modelKey)
    if not modelKey then return false end
    local PlayerModels = hg.Appearance.PlayerModels or {}
    local modelData = nil
    if PlayerModels[1] then modelData = PlayerModels[1][modelKey] end
    if not modelData and PlayerModels[2] then modelData = PlayerModels[2][modelKey] end
    if not modelData then return false end
    if not modelData.psItemID then return true end
    return PSHas(modelData.psItemID)
end

local function CanUseBodygroup(bodygroupName, optionName, sexIndex)
    if not bodygroupName or not optionName then return true end
    if optionName == "None" or optionName == "Brak" then return true end
    local bodygroups = hg.Appearance.Bodygroups
    if not bodygroups or not bodygroups[bodygroupName] then return true end
    if not bodygroups[bodygroupName][sexIndex] then return true end
    local bgData = bodygroups[bodygroupName][sexIndex][optionName]
    if not bgData then return true end
    if type(bgData) ~= "table" then return true end
    if bgData[2] == true and bgData.ID then
        return PSHas(bgData.ID)
    end
    return true
end

local function GetRarityColor(acc)
    if not acc then return Theme.rarityCommon end
    if acc.isdpoint then return Theme.rarityLegendary end
    local price = acc.price or 0
    if price == 0 then return Theme.rarityCommon end
    if price < 1500 then return Theme.rarityCommon end
    if price < 3000 then return Theme.rarityUncommon end
    if price < 5000 then return Theme.rarityRare end
    if price < 7500 then return Theme.rarityEpic end
    return Theme.rarityLegendary
end

local DefaultAppearance = {
    AModel = "Male 01",
    AClothes = {main = "normal", pants = "normal", boots = "normal"},
    AName = "Obywatel",
    AColor = Color(100, 100, 100),
    AAttachments = {"none", "none", "none"},
    ABodygroups = {},
    AFacemap = "Default",
    AModelBodygroups = "",
    ASkin = 0,
}

local function EnsureAppearanceStructure(tbl)
    if not tbl then tbl = table.Copy(DefaultAppearance) end
    if not tbl.AClothes then tbl.AClothes = {main = "normal", pants = "normal", boots = "normal"} end
    if not tbl.AClothes.main then tbl.AClothes.main = "normal" end
    if not tbl.AClothes.pants then tbl.AClothes.pants = "normal" end
    if not tbl.AClothes.boots then tbl.AClothes.boots = "normal" end
    if not tbl.AAttachments then tbl.AAttachments = {"none", "none", "none"} end
    if not tbl.ABodygroups then tbl.ABodygroups = {} end
    if not tbl.AModel then tbl.AModel = "Male 01" end
    if not tbl.AName then tbl.AName = "Obywatel" end
    if not tbl.AColor then 
        tbl.AColor = Color(100, 100, 100)
    elseif type(tbl.AColor) == "table" and not IsColor(tbl.AColor) then
        tbl.AColor = Color(tbl.AColor.r or 100, tbl.AColor.g or 100, tbl.AColor.b or 100, tbl.AColor.a or 255)
    end
    if not tbl.AFacemap then tbl.AFacemap = "Default" end
    if tbl.AModelBodygroups == nil then 
        tbl.AModelBodygroups = "" 
    else
        tbl.AModelBodygroups = tostring(tbl.AModelBodygroups)
    end
    if tbl.ASkin == nil then tbl.ASkin = 0 end
    return tbl
end

local function GetModelData(modelName)
    if not modelName then return nil end
    local pm = hg.Appearance.PlayerModels or {}
    local data = nil
    if pm[1] then data = pm[1][modelName] end
    if not data and pm[2] then data = pm[2][modelName] end
    return data
end

local function GetModelSex(modelData)
    if not modelData then return 1 end
    return modelData.sex and 2 or 1
end

local function FindHandsKey()
    local bodygroups = hg.Appearance.Bodygroups
    if not bodygroups then return nil end
    local possibleKeys = {"HANDS", "Hands", "hands", "Gloves", "gloves", "GLOVES"}
    for _, tryKey in ipairs(possibleKeys) do
        if bodygroups[tryKey] then return tryKey end
    end
    for bgName, _ in pairs(bodygroups) do
        local lower = string.lower(bgName)
        if string.find(lower, "hand") or string.find(lower, "glove") or string.find(lower, "rekaw") then
            return bgName
        end
    end
    return nil
end

local function GetHandsData(sex)
    local bodygroups = hg.Appearance.Bodygroups
    if not bodygroups then return nil, nil end
    local handsKey = FindHandsKey()
    if not handsKey then return nil, nil end
    local bgData = bodygroups[handsKey]
    if not bgData then return nil, nil end
    if bgData[sex] then return bgData[sex], handsKey end
    if bgData[1] then return bgData[1], handsKey end
    if bgData[2] then return bgData[2], handsKey end
    return nil, handsKey
end

local function ApplyBodygroupsToEntity(ent, tbl)
    if not IsValid(ent) or not tbl or not tbl.ABodygroups then return end
    local curMdl = GetModelData(tbl.AModel)
    if not curMdl then return end
    local sex = GetModelSex(curMdl)
    local bgData = hg.Appearance.Bodygroups
    if not bgData then return end
    local mats = ent:GetMaterials()
    for bgName, bgOption in pairs(tbl.ABodygroups) do
        if not bgOption or bgOption == "None" or bgOption == "Brak" or bgOption == "" then continue end
        local optionData = nil
        if bgData[bgName] then
            if bgData[bgName][sex] and bgData[bgName][sex][bgOption] then
                optionData = bgData[bgName][sex][bgOption]
            elseif bgData[bgName][1] and bgData[bgName][1][bgOption] then
                optionData = bgData[bgName][1][bgOption]
            elseif bgData[bgName][2] and bgData[bgName][2][bgOption] then
                optionData = bgData[bgName][2][bgOption]
            end
        end
        if not optionData or type(optionData) ~= "table" then continue end
        local submatName = optionData[1]
        if not submatName or type(submatName) ~= "string" then continue end
        local bgIndex = -1
        for i = 0, ent:GetNumBodyGroups() - 1 do
            local name = ent:GetBodygroupName(i)
            if name and string.lower(name) == string.lower(bgName) then
                bgIndex = i
                break
            end
        end
        if bgIndex < 0 then continue end
        local allOptions = {}
        local sourceData = bgData[bgName][sex] or bgData[bgName][1] or bgData[bgName][2]
        if sourceData then
            for optName, optData in pairs(sourceData) do
                if type(optData) == "table" and optData[1] then
                    table.insert(allOptions, {name = optName, submat = optData[1]})
                end
            end
        end
        local sortedNonNone = {}
        for _, opt in ipairs(allOptions) do
            if opt.name ~= "None" and opt.name ~= "Brak" then
                table.insert(sortedNonNone, opt)
            end
        end
        table.sort(sortedNonNone, function(a, b) return a.name < b.name end)
        local numOptions = ent:GetBodygroupCount(bgIndex)
        local found = false
        for idx, opt in ipairs(sortedNonNone) do
            if opt.name == bgOption then
                if idx < numOptions then
                    ent:SetBodygroup(bgIndex, idx)
                    found = true
                end
                break
            end
        end
        if submatName ~= "hands" then
            for i = 1, #mats do
                if string.find(mats[i], "hands") or string.find(string.lower(mats[i]), "hand") then
                    ent:SetSubMaterial(i - 1, submatName)
                    found = true
                    break
                end
            end
            if not found then
                for i = 1, #mats do
                    if string.find(string.lower(mats[i]), string.lower(submatName)) then
                        ent:SetSubMaterial(i - 1, submatName)
                        break
                    end
                end
            end
        end
    end
end

local function ParseBodygroupString(str)
    local t = {}
    if not str or str == "" then return t end
    for i = 1, #str do
        local char = string.sub(str, i, i)
        t[i] = tonumber(char) or 0
    end
    return t
end

local function BuildBodygroupString(tbl, count)
    local s = ""
    for i = 1, count do
        s = s .. tostring(tbl[i] or 0)
    end
    return s
end

local function GetOwnedModels()
    local owned = {}
    local PlayerModels = hg.Appearance.PlayerModels or {}
    for sex = 1, 2 do
        if PlayerModels[sex] then
            for name, data in pairs(PlayerModels[sex]) do
                if CanUseModel(name) then
                    table.insert(owned, {name = name, data = data, sex = sex})
                end
            end
        end
    end
    return owned
end

local function GetOwnedAccessories(placement)
    local owned = {}
    for key, acc in pairs(hg.Accessories or {}) do
        if key == "none" then continue end
        if acc.disallowinappearance then continue end
        local validPlacement = false
        if placement == "head" then
            validPlacement = (acc.placement == "head" or acc.placement == "ears")
        elseif placement == "face" then
            validPlacement = (acc.placement == "face")
        elseif placement == "body" then
            validPlacement = (acc.placement == "torso" or acc.placement == "spine")
        else
            validPlacement = (acc.placement == placement)
        end
        if validPlacement and CanUseAccessory(key) then
            table.insert(owned, key)
        end
    end
    return owned
end

local function RandomizeAppearance(currentAppearance)
    local newApp = table.Copy(currentAppearance)
    newApp = EnsureAppearanceStructure(newApp)
    local ownedModels = GetOwnedModels()
    if #ownedModels > 0 then
        local chosen = ownedModels[math.random(#ownedModels)]
        newApp.AModel = chosen.name
    end
    local tMdl = GetModelData(newApp.AModel)
    local sex = GetModelSex(tMdl)
    local clothes = hg.Appearance.Clothes and hg.Appearance.Clothes[sex]
    if clothes then
        local clothesList = {}
        for k, v in pairs(clothes) do table.insert(clothesList, k) end
        if #clothesList > 0 then
            newApp.AClothes.main = clothesList[math.random(#clothesList)]
            newApp.AClothes.pants = clothesList[math.random(#clothesList)]
            newApp.AClothes.boots = clothesList[math.random(#clothesList)]
        end
    end
    newApp.AColor = ColorRand(false)
    local headAcc = GetOwnedAccessories("head")
    local faceAcc = GetOwnedAccessories("face")
    local bodyAcc = GetOwnedAccessories("body")
    newApp.AAttachments = {"none", "none", "none"}
    if #headAcc > 0 and math.random() > 0.5 then newApp.AAttachments[1] = headAcc[math.random(#headAcc)] end
    if #faceAcc > 0 and math.random() > 0.5 then newApp.AAttachments[2] = faceAcc[math.random(#faceAcc)] end
    if #bodyAcc > 0 and math.random() > 0.5 then newApp.AAttachments[3] = bodyAcc[math.random(#bodyAcc)] end
    if tMdl and tMdl.mdl then
        local fmOverride = hg.Appearance.FacemapsModels and hg.Appearance.FacemapsModels[tMdl.mdl]
        local fmSlots = fmOverride and hg.Appearance.FacemapsSlots and hg.Appearance.FacemapsSlots[fmOverride]
        if fmSlots then
            local fmList = {}
            for name, _ in pairs(fmSlots) do table.insert(fmList, name) end
            if #fmList > 0 then newApp.AFacemap = fmList[math.random(#fmList)] end
        end
    end
    return newApp
end

local Categories = {
    {id = "skin", name = "Skorka"},
    {id = "hats", name = "Czapki"},
    {id = "face", name = "Twarz"},
    {id = "body", name = "Cialo"},
    {id = "jacket", name = "Kurtka"},
    {id = "pants", name = "Spodnie"},
    {id = "boots", name = "Buty"},
    {id = "gloves", name = "Rekawice"},
    {id = "facemap", name = "Mapa Twarzy"},
    {id = "presets", name = "Presety"},
}

local function CreateStyledScrollPanel(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    local sbar = scroll:GetVBar()
    sbar:SetWide(8)
    sbar:SetHideButtons(true)
    function sbar:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, Theme.scrollBg) end
    function sbar.btnGrip:Paint(w, h)
        draw.RoundedBox(4, 1, 1, w - 2, h - 2, self:IsHovered() and Theme.scrollGripHover or Theme.scrollGrip)
    end
    return scroll
end

local function CreateSearchBar(parent, onSearch)
    local searchPanel = vgui.Create("DPanel", parent)
    searchPanel:Dock(TOP)
    searchPanel:SetTall(45)
    searchPanel:DockMargin(0, 0, 0, 10)
    function searchPanel:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    local searchLabel = vgui.Create("DLabel", searchPanel)
    searchLabel:SetPos(12, 12)
    searchLabel:SetSize(20, 20)
    searchLabel:SetText("")
    function searchLabel:Paint(w, h)
        draw.SimpleText("Q", "DermaDefaultBold", w / 2, h / 2, Theme.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local searchEntry = vgui.Create("DTextEntry", searchPanel)
    searchEntry:SetPos(35, 8)
    searchEntry:SetSize(300, 28)
    searchEntry:SetFont("DermaDefault")
    searchEntry:SetPlaceholderText("Szukaj...")
    searchEntry:SetUpdateOnType(true)
    function searchEntry:Paint(w, h)
        local focused = self:HasFocus()
        draw.RoundedBox(4, 0, 0, w, h, Theme.search)
        surface.SetDrawColor(focused and Theme.accent or Theme.searchBorder)
        surface.DrawOutlinedRect(0, 0, w, h, focused and 2 or 1)
        self:DrawTextEntryText(Theme.text, Theme.accent, Theme.text)
    end
    function searchEntry:OnValueChange(val)
        if onSearch then onSearch(string.lower(string.Trim(val))) end
    end
    local clearBtn = vgui.Create("DButton", searchPanel)
    clearBtn:SetPos(345, 10)
    clearBtn:SetSize(60, 25)
    clearBtn:SetText("WYCZYSC")
    clearBtn:SetFont("DermaDefault")
    clearBtn:SetTextColor(Theme.text)
    function clearBtn:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Theme.bgLight or Color(0, 0, 0, 0))
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    function clearBtn:DoClick()
        searchEntry:SetText("")
        if onSearch then onSearch("") end
    end
    return searchPanel, searchEntry
end

function PANEL:Init()
    self.AppearanceTable = nil
    if hg.Appearance.LoadAppearanceFile then
        local selApp = hg.Appearance.SelectedAppearance and hg.Appearance.SelectedAppearance:GetString() or "default"
        self.AppearanceTable = hg.Appearance.LoadAppearanceFile(selApp)
    end
    if not self.AppearanceTable then
        self.AppearanceTable = table.Copy(DefaultAppearance)
    end
    self.AppearanceTable = EnsureAppearanceStructure(self.AppearanceTable)
    self.CurrentCategory = "skin"
    self.ModelRotation = 180
    self.ModelZoom = 35
    self.IsDragging = false
    self.LastMouseX = 0
    self.SearchQuery = ""
    self.SkinEditMode = false
    self.CurrentNumBodygroups = 0
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MakePopup()
    InitParticles()
    self:StartMusic()
    self:SetupLayout()
end

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

function PANEL:SetupLayout()
    local main = self
    local sw, sh = ScrW(), ScrH()
    local leftPanelWidth = sw * 0.38
    local rightPanelWidth = sw - leftPanelWidth

    self.LeftPanel = vgui.Create("DPanel", self)
    self.LeftPanel:SetPos(0, 0)
    self.LeftPanel:SetSize(leftPanelWidth, sh)
    function self.LeftPanel:Paint(w, h) end

    local previewTitle = vgui.Create("DPanel", self.LeftPanel)
    previewTitle:SetPos(20, 20)
    previewTitle:SetSize(leftPanelWidth - 40, 40)
    function previewTitle:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Theme.bgLight)
        surface.SetDrawColor(Theme.accent)
        surface.DrawRect(0, h - 3, w, 3)
        draw.SimpleText("PODGLAD POSTACI", "DermaLarge", w / 2, h / 2 - 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local tMdl = GetModelData(self.AppearanceTable.AModel)
    local modelPath = tMdl and tMdl.mdl or "models/player/group01/male_01.mdl"

    local modelViewPanel = vgui.Create("DPanel", self.LeftPanel)
    modelViewPanel:SetPos(20, 70)
    modelViewPanel:SetSize(leftPanelWidth - 40, sh * 0.55)
    function modelViewPanel:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 25, 230))
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    self.ModelView = vgui.Create("DModelPanel", modelViewPanel)
    self.ModelView:SetPos(10, 10)
    self.ModelView:SetSize(leftPanelWidth - 60, sh * 0.55 - 20)
    self.ModelView:SetModel(modelPath)
    self.ModelView:SetFOV(35)
    self.ModelView:SetCamPos(Vector(120, 0, 55))
    self.ModelView:SetLookAt(Vector(0, 0, 40))
    self.ModelView:SetAmbientLight(Color(50, 50, 50))
    self.ModelView:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
    self.ModelView:SetDirectionalLight(BOX_FRONT, Color(150, 150, 150))
    self.ModelView:SetDirectionalLight(BOX_RIGHT, Color(180, 50, 50))
    self.ModelView:SetDirectionalLight(BOX_LEFT, Color(50, 100, 180))

    function self.ModelView:LayoutEntity(ent)
        local tbl = main.AppearanceTable
        local curMdl = GetModelData(tbl.AModel)
        if curMdl and ent:GetModel() ~= curMdl.mdl then
            ent:SetModel(curMdl.mdl)
            self:SetModel(curMdl.mdl)
        end
        ent:SetAngles(Angle(0, main.ModelRotation, 0))
        if tbl.AColor then
            ent:SetNWVector("PlayerColor", Vector(tbl.AColor.r / 255, tbl.AColor.g / 255, tbl.AColor.b / 255))
        end
        ent:SetSkin(tbl.ASkin or 0)
        if tbl.AModelBodygroups and tbl.AModelBodygroups ~= "" then
            ent:SetBodyGroups(tbl.AModelBodygroups)
        end
        if curMdl then
            local mats = ent:GetMaterials()
            local sex = GetModelSex(curMdl)
            for k, v in pairs(curMdl.submatSlots or {}) do
                local slot = 0
                for i = 1, #mats do
                    if mats[i] == v then slot = i - 1 break end
                end
                local clothesMat = hg.Appearance.Clothes and hg.Appearance.Clothes[sex] and hg.Appearance.Clothes[sex][tbl.AClothes[k]]
                if clothesMat then ent:SetSubMaterial(slot, clothesMat) end
            end
            for i = 1, #mats do
                local fmSlots = hg.Appearance.FacemapsSlots and hg.Appearance.FacemapsSlots[mats[i]]
                if fmSlots and fmSlots[tbl.AFacemap] then ent:SetSubMaterial(i - 1, fmSlots[tbl.AFacemap]) end
            end
            ApplyBodygroupsToEntity(ent, tbl)
        end
        ent:SetSequence(ent:LookupSequence("idle_all_01") or 0)
        ent:SetPlaybackRate(1)
    end

    function self.ModelView:PostDrawModel(ent)
        local tbl = main.AppearanceTable
        if tbl.AAttachments then
            for i, key in ipairs(tbl.AAttachments) do
                if key and key ~= "none" and key ~= "" and hg.Accessories[key] then
                    if DrawAccesories then DrawAccesories(ent, ent, key, hg.Accessories[key], false, true) end
                end
            end
        end
    end

    function self.ModelView:OnMousePressed(mc)
        if mc == MOUSE_LEFT then main.IsDragging = true main.LastMouseX = gui.MouseX() end
    end
    function self.ModelView:OnMouseReleased(mc)
        if mc == MOUSE_LEFT then main.IsDragging = false end
    end
    function self.ModelView:Think()
        if main.IsDragging then
            local mx = gui.MouseX()
            main.ModelRotation = main.ModelRotation + (mx - main.LastMouseX) * 0.5
            main.LastMouseX = mx
        end
    end
    function self.ModelView:OnMouseWheeled(delta)
        main.ModelZoom = math.Clamp(main.ModelZoom - delta * 3, 15, 60)
        self:SetFOV(main.ModelZoom)
    end

    local infoPanel = vgui.Create("DPanel", self.LeftPanel)
    infoPanel:SetPos(20, sh * 0.55 + 90)
    infoPanel:SetSize(leftPanelWidth - 40, sh * 0.35 - 20)
    function infoPanel:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 25, 230))
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.SimpleText("AKTUALNIE ZALOZONO:", "DermaDefaultBold", 15, 15, Theme.accent, TEXT_ALIGN_LEFT)
        local tbl = main.AppearanceTable
        local y = 40
        local hasItems = false
        if tbl.AAttachments then
            for i, key in ipairs(tbl.AAttachments) do
                if key and key ~= "none" and key ~= "" then
                    hasItems = true
                    local acc = hg.Accessories[key]
                    local name = acc and acc.name or key
                    local slotName = (i == 1 and "Glowa: ") or (i == 2 and "Twarz: ") or "Cialo: "
                    draw.SimpleText(slotName .. name, "DermaDefault", 15, y, Theme.text, TEXT_ALIGN_LEFT)
                    y = y + 24
                end
            end
        end
        if tbl.ABodygroups then
            for bgName, bgOption in pairs(tbl.ABodygroups) do
                if bgOption and bgOption ~= "None" and bgOption ~= "Brak" and bgOption ~= "" then
                    hasItems = true
                    draw.SimpleText(bgName .. ": " .. bgOption, "DermaDefault", 15, y, Theme.text, TEXT_ALIGN_LEFT)
                    y = y + 24
                end
            end
        end
        if tbl.AModelBodygroups and tbl.AModelBodygroups ~= "" then
            hasItems = true
            draw.SimpleText("Bodygroups: " .. tbl.AModelBodygroups, "DermaDefault", 15, y, Theme.text, TEXT_ALIGN_LEFT)
            y = y + 24
        end
        if tbl.ASkin and tbl.ASkin > 0 then
            hasItems = true
            draw.SimpleText("Skin: " .. tbl.ASkin, "DermaDefault", 15, y, Theme.text, TEXT_ALIGN_LEFT)
            y = y + 24
        end
        if not hasItems then
            draw.SimpleText("Brak akcesoriow", "DermaDefault", 15, y, Theme.textDark, TEXT_ALIGN_LEFT)
        end
        draw.SimpleText("Model: " .. (tbl.AModel or "?"), "DermaDefault", 15, h - 50, Theme.textDim, TEXT_ALIGN_LEFT)
        draw.SimpleText("Ubranie: " .. (tbl.AClothes and tbl.AClothes.main or "normal"), "DermaDefault", 15, h - 28, Theme.textDim, TEXT_ALIGN_LEFT)
    end

    self.RightPanel = vgui.Create("DPanel", self)
    self.RightPanel:SetPos(leftPanelWidth, 0)
    self.RightPanel:SetSize(rightPanelWidth, sh)
    function self.RightPanel:Paint(w, h) end

    local headerPanel = vgui.Create("DPanel", self.RightPanel)
    headerPanel:SetPos(20, 20)
    headerPanel:SetSize(rightPanelWidth - 40, 50)
    function headerPanel:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Theme.bgLight)
        surface.SetDrawColor(Theme.accent)
        surface.DrawRect(0, h - 3, w, 3)
        draw.SimpleText("EDYTOR WYGLADU POSTACI", "DermaLarge", w / 2, h / 2 - 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local closeBtn = vgui.Create("DButton", headerPanel)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(headerPanel:GetWide() - 45, 5)
    closeBtn:SetText("")
    function closeBtn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Theme.accent or Theme.bgLighter)
        draw.SimpleText("X", "DermaLarge", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function closeBtn:DoClick() main:Close() end

    local nickPanel = vgui.Create("DPanel", self.RightPanel)
    nickPanel:SetPos(20, 85)
    nickPanel:SetSize(rightPanelWidth - 40, 90)
    function nickPanel:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Theme.bgLight)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("NICK POSTACI (IN-GAME)", "DermaDefaultBold", 15, 12, Theme.accent, TEXT_ALIGN_LEFT)
        draw.SimpleText("Ta nazwa bedzie widoczna dla innych graczy w grze", "DermaDefault", 15, 32, Theme.textDim, TEXT_ALIGN_LEFT)
    end

    self.NameEntry = vgui.Create("DTextEntry", nickPanel)
    self.NameEntry:SetPos(15, 55)
    self.NameEntry:SetSize(rightPanelWidth - 200, 28)
    self.NameEntry:SetFont("DermaDefaultBold")
    self.NameEntry:SetText(self.AppearanceTable.AName or "Obywatel")
    self.NameEntry:SetPlaceholderText("Wpisz nick swojej postaci...")
    function self.NameEntry:Paint(w, h)
        local focused = self:HasFocus()
        draw.RoundedBox(6, 0, 0, w, h, focused and Color(40, 40, 50) or Theme.bgDark)
        surface.SetDrawColor(focused and Theme.accent or Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, focused and 2 or 1)
        self:DrawTextEntryText(Theme.text, Theme.accent, Theme.text)
    end
    function self.NameEntry:OnChange() main.AppearanceTable.AName = self:GetValue() end

    local colorBtn = vgui.Create("DButton", nickPanel)
    colorBtn:SetPos(rightPanelWidth - 175, 55)
    colorBtn:SetSize(120, 28)
    colorBtn:SetText("")
    function colorBtn:Paint(w, h)
        local col = main.AppearanceTable.AColor or Color(100, 100, 100)
        draw.RoundedBox(6, 0, 0, w, h, col)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local textCol = (col.r + col.g + col.b) / 3 > 128 and Color(0, 0, 0) or Color(255, 255, 255)
        draw.SimpleText("KOLOR", "DermaDefaultBold", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function colorBtn:DoClick()
        local colorMenu = DermaMenu()
        local colorMixer = vgui.Create("DColorMixer", colorMenu)
        colorMixer:SetSize(200, 200)
        colorMixer:SetColor(main.AppearanceTable.AColor or Color(100, 100, 100))
        colorMixer:SetPalette(true)
        colorMixer:SetAlphaBar(false)
        function colorMixer:ValueChanged(col) main.AppearanceTable.AColor = col end
        colorMenu:AddPanel(colorMixer)
        colorMenu:Open()
    end

    local tabsPanel = vgui.Create("DPanel", self.RightPanel)
    tabsPanel:SetPos(20, 190)
    tabsPanel:SetSize(rightPanelWidth - 40, 45)
    function tabsPanel:Paint(w, h) draw.RoundedBox(8, 0, 0, w, h, Theme.bgLight) end

    local tabWidth = (rightPanelWidth - 60) / #Categories
    for i, cat in ipairs(Categories) do
        local tabBtn = vgui.Create("DButton", tabsPanel)
        tabBtn:SetPos(10 + (i - 1) * tabWidth, 7)
        tabBtn:SetSize(tabWidth - 5, 31)
        tabBtn:SetText(cat.name)
        tabBtn:SetFont("DermaDefault")
        tabBtn:SetTextColor(Theme.text)
        tabBtn.CatID = cat.id
        function tabBtn:Paint(w, h)
            local isActive = main.CurrentCategory == self.CatID
            draw.RoundedBox(4, 0, 0, w, h, isActive and Theme.accent or (self:IsHovered() and Theme.bgLighter or Color(0, 0, 0, 0)))
        end
        function tabBtn:DoClick()
            main.CurrentCategory = self.CatID
            main.SearchQuery = ""
            main.SkinEditMode = false
            main:RefreshContent()
            surface.PlaySound("UI/buttonclick.wav")
        end
    end

    self.ContentPanel = vgui.Create("DPanel", self.RightPanel)
    self.ContentPanel:SetPos(20, 245)
    self.ContentPanel:SetSize(rightPanelWidth - 40, sh - 335)
    function self.ContentPanel:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Theme.bgLight)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local bottomPanel = vgui.Create("DPanel", self.RightPanel)
    bottomPanel:SetPos(20, sh - 80)
    bottomPanel:SetSize(rightPanelWidth - 40, 60)
    function bottomPanel:Paint(w, h) end

    local resetBtn = vgui.Create("DButton", bottomPanel)
    resetBtn:SetPos(0, 10)
    resetBtn:SetSize(130, 40)
    resetBtn:SetText("RESET")
    resetBtn:SetFont("DermaDefaultBold")
    resetBtn:SetTextColor(Theme.text)
    function resetBtn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Theme.bgLighter or Theme.bgLight)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    function resetBtn:DoClick()
        main.AppearanceTable = EnsureAppearanceStructure(table.Copy(DefaultAppearance))
        main.NameEntry:SetText(DefaultAppearance.AName)
        main.SkinEditMode = false
        main:RefreshContent()
        surface.PlaySound("UI/buttonclick.wav")
    end

    local randomBtn = vgui.Create("DButton", bottomPanel)
    randomBtn:SetPos(145, 10)
    randomBtn:SetSize(130, 40)
    randomBtn:SetText("LOSUJ")
    randomBtn:SetFont("DermaDefaultBold")
    randomBtn:SetTextColor(Theme.text)
    function randomBtn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(80, 80, 180) or Color(60, 60, 150))
    end
    function randomBtn:DoClick()
        main.AppearanceTable = EnsureAppearanceStructure(RandomizeAppearance(main.AppearanceTable))
        main.NameEntry:SetText(main.AppearanceTable.AName or "Obywatel")
        main.SkinEditMode = false
        main:RefreshContent()
        surface.PlaySound("UI/buttonclick.wav")
    end

    local applyBtn = vgui.Create("DButton", bottomPanel)
    applyBtn:SetPos(rightPanelWidth - 200, 10)
    applyBtn:SetSize(160, 40)
    applyBtn:SetText("ZASTOSUJ")
    applyBtn:SetFont("DermaDefaultBold")
    applyBtn:SetTextColor(Theme.text)
    function applyBtn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Theme.successHover or Theme.success)
    end
    function applyBtn:DoClick()
        print("=== ZAPISYWANIE APPEARANCE ===")
        print("AModel: " .. tostring(main.AppearanceTable.AModel))
        print("AModelBodygroups: \"" .. tostring(main.AppearanceTable.AModelBodygroups) .. "\"")
        print("ASkin: " .. tostring(main.AppearanceTable.ASkin))
        print("AName: " .. tostring(main.AppearanceTable.AName))
        PrintTable(main.AppearanceTable)
        print("==============================")
        if hg.Appearance.CreateAppearanceFile then
            hg.Appearance.CreateAppearanceFile(hg.Appearance.SelectedAppearance:GetString(), main.AppearanceTable)
        end
        net.Start("OnlyGet_Appearance")
        net.WriteTable(main.AppearanceTable)
        net.SendToServer()
        surface.PlaySound("UI/buttonclickrelease.wav")
        main:Close()
    end

    self:RefreshContent()
end

function PANEL:RefreshContent()
    if IsValid(self.ContentScroll) then self.ContentScroll:Remove() end
    self.ContentScroll = CreateStyledScrollPanel(self.ContentPanel)
    self.ContentScroll:Dock(FILL)
    self.ContentScroll:DockMargin(10, 10, 10, 10)
    local cat = self.CurrentCategory
    if cat == "skin" then
        if self.SkinEditMode then
            self:BuildSkinEditContent()
        else
            self:BuildSkinContent()
        end
    elseif cat == "hats" then self:BuildAccessoryContent("head")
    elseif cat == "face" then self:BuildAccessoryContent("face")
    elseif cat == "body" then self:BuildAccessoryContent("body")
    elseif cat == "jacket" then self:BuildClothesContent("main")
    elseif cat == "pants" then self:BuildClothesContent("pants")
    elseif cat == "boots" then self:BuildClothesContent("boots")
    elseif cat == "gloves" then self:BuildGlovesContent()
    elseif cat == "facemap" then self:BuildFacemapContent()
    elseif cat == "presets" then self:BuildPresetsContent()
    end
end

function PANEL:BuildSkinContent()
    local main = self

    local editPanel = vgui.Create("DPanel", self.ContentScroll)
    editPanel:Dock(TOP)
    editPanel:SetTall(50)
    editPanel:DockMargin(0, 0, 0, 10)
    function editPanel:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
        surface.SetDrawColor(Theme.accent)
        surface.DrawRect(0, 0, 4, h)
        draw.SimpleText("Wybrany model: " .. (main.AppearanceTable.AModel or "?"), "DermaDefaultBold", 15, h / 2, Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local editBtn = vgui.Create("DButton", editPanel)
    editBtn:SetSize(160, 36)
    editBtn:SetText("")
    function editBtn:PerformLayout()
        self:SetPos(self:GetParent():GetWide() - 175, 7)
    end
    function editBtn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Theme.accentHover or Theme.accent)
        draw.SimpleText("EDYTUJ KOLOR / CIALO", "DermaDefaultBold", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function editBtn:DoClick()
        main.SkinEditMode = true
        main.SearchQuery = ""
        main:RefreshContent()
        surface.PlaySound("UI/buttonclick.wav")
    end

    CreateSearchBar(self.ContentScroll, function(query)
        main.SearchQuery = query
        main:RebuildSkinGrid()
    end)
    self.SkinGridParent = vgui.Create("DPanel", self.ContentScroll)
    self.SkinGridParent:Dock(TOP)
    self.SkinGridParent:SetTall(2000)
    function self.SkinGridParent:Paint() end
    self:RebuildSkinGrid()
end

function PANEL:RebuildSkinGrid()
    if not IsValid(self.SkinGridParent) then return end
    self.SkinGridParent:Clear()
    local main = self
    local query = self.SearchQuery or ""
    local grid = vgui.Create("DIconLayout", self.SkinGridParent)
    grid:Dock(TOP)
    grid:SetSpaceX(10)
    grid:SetSpaceY(10)
    local count = 0
    for sex = 1, 2 do
        local pm = hg.Appearance.PlayerModels and hg.Appearance.PlayerModels[sex]
        if not pm then continue end
        for name, data in pairs(pm) do
            if not CanUseModel(name) then continue end
            if query ~= "" and not string.find(string.lower(name), query, 1, true) then continue end
            count = count + 1
            local btn = vgui.Create("DButton", grid)
            btn:SetSize(110, 140)
            btn:SetText("")
            btn.ModelName = name
            btn.ModelData = data
            local modelIcon = vgui.Create("DModelPanel", btn)
            modelIcon:SetPos(5, 5)
            modelIcon:SetSize(100, 100)
            modelIcon:SetModel(data.mdl or "models/error.mdl")
            modelIcon:SetFOV(25)
            modelIcon:SetCamPos(Vector(80, 0, 60))
            modelIcon:SetLookAt(Vector(0, 0, 60))
            modelIcon:SetMouseInputEnabled(false)
            function modelIcon:LayoutEntity(ent) ent:SetAngles(Angle(0, RealTime() * 30, 0)) end
            function btn:Paint(w, h)
                local isSel = main.AppearanceTable.AModel == self.ModelName
                local bgCol = isSel and Theme.accent or (self:IsHovered() and Theme.bgLighter or Theme.bgLight)
                draw.RoundedBox(6, 0, 0, w, h, bgCol)
                surface.SetDrawColor(isSel and Theme.accentHover or Theme.border)
                surface.DrawOutlinedRect(0, 0, w, h, isSel and 2 or 1)
                draw.SimpleText(self.ModelName, "DermaDefault", w / 2, h - 20, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                local sexText = self.ModelData.sex and "K" or "M"
                local sexCol = self.ModelData.sex and Color(255, 150, 200) or Color(150, 200, 255)
                draw.SimpleText(sexText, "DermaDefaultBold", w - 15, 10, sexCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
            function btn:DoClick()
                main.AppearanceTable.AModel = name
                main.AppearanceTable.AFacemap = "Default"
                main.AppearanceTable.AModelBodygroups = ""
                main.AppearanceTable.ASkin = 0
                main:RefreshContent()
                surface.PlaySound("UI/buttonclick.wav")
            end
        end
    end
    self.SkinGridParent:SetTall(math.max(math.ceil(count / 5) * 150, 50))
    if count == 0 then
        local noLabel = vgui.Create("DLabel", self.SkinGridParent)
        noLabel:Dock(TOP)
        noLabel:SetTall(40)
        noLabel:SetText("Nie znaleziono modeli")
        noLabel:SetFont("DermaDefault")
        noLabel:SetTextColor(Theme.textDim)
        noLabel:SetContentAlignment(5)
    end
end

function PANEL:BuildSkinEditContent()
    local main = self
    local tMdl = GetModelData(self.AppearanceTable.AModel)
    local modelPath = tMdl and tMdl.mdl or "models/player/group01/male_01.mdl"

    local backBtn = vgui.Create("DButton", self.ContentScroll)
    backBtn:Dock(TOP)
    backBtn:SetTall(35)
    backBtn:DockMargin(0, 0, 0, 10)
    backBtn:SetText("")
    function backBtn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Theme.bgLighter or Theme.bgLight)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("<  WSTECZ DO LISTY MODELI", "DermaDefaultBold", 15, h / 2, Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Model: " .. (main.AppearanceTable.AModel or "?"), "DermaDefault", w - 15, h / 2, Theme.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    function backBtn:DoClick()
        main.SkinEditMode = false
        main.SearchQuery = ""
        main:RefreshContent()
        surface.PlaySound("UI/buttonclick.wav")
    end

    local colorSection = vgui.Create("DPanel", self.ContentScroll)
    colorSection:Dock(TOP)
    colorSection:SetTall(40)
    colorSection:DockMargin(0, 0, 0, 5)
    function colorSection:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
        surface.SetDrawColor(Theme.accent)
        surface.DrawRect(0, 0, 4, h)
        draw.SimpleText("KOLOR POSTACI (PlayerColor)", "DermaDefaultBold", 15, h / 2, Theme.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local colorRow = vgui.Create("DPanel", self.ContentScroll)
    colorRow:Dock(TOP)
    colorRow:SetTall(45)
    colorRow:DockMargin(0, 0, 0, 5)
    function colorRow:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, Theme.bgDark) end

    local colorPreview = vgui.Create("DButton", colorRow)
    colorPreview:SetPos(10, 5)
    colorPreview:SetSize(80, 35)
    colorPreview:SetText("")
    function colorPreview:Paint(w, h)
        local col = main.AppearanceTable.AColor or Color(100, 100, 100)
        draw.RoundedBox(4, 0, 0, w, h, col)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local quickColors = {
        Color(20, 20, 20), Color(240, 240, 240), Color(128, 128, 128),
        Color(200, 30, 30), Color(30, 60, 200), Color(30, 150, 30),
        Color(230, 200, 30), Color(230, 130, 30), Color(230, 100, 180),
        Color(130, 40, 200), Color(120, 70, 30), Color(30, 180, 180),
    }
    for i, qc in ipairs(quickColors) do
        local qcBtn = vgui.Create("DButton", colorRow)
        qcBtn:SetPos(100 + (i - 1) * 30, 8)
        qcBtn:SetSize(25, 28)
        qcBtn:SetText("")
        function qcBtn:Paint(w, h)
            draw.RoundedBox(3, 0, 0, w, h, qc)
            if self:IsHovered() then
                surface.SetDrawColor(255, 255, 255, 150)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
        end
        function qcBtn:DoClick()
            main.AppearanceTable.AColor = Color(qc.r, qc.g, qc.b)
            surface.PlaySound("UI/buttonclick.wav")
        end
    end

    local colorMixer = vgui.Create("DColorMixer", self.ContentScroll)
    colorMixer:Dock(TOP)
    colorMixer:SetTall(180)
    colorMixer:DockMargin(0, 0, 0, 15)
    colorMixer:SetColor(main.AppearanceTable.AColor or Color(100, 100, 100))
    colorMixer:SetPalette(true)
    colorMixer:SetAlphaBar(false)
    function colorMixer:ValueChanged(col) main.AppearanceTable.AColor = col end

    local tempEnt = ClientsideModel(modelPath, RENDERGROUP_OTHER)
    if not IsValid(tempEnt) then return end
    tempEnt:SetNoDraw(true)

    local numSkins = tempEnt:SkinCount() or 1
    local numBodygroups = tempEnt:GetNumBodyGroups() or 0

    main.CurrentNumBodygroups = numBodygroups

    if numSkins > 1 then
        local skinSection = vgui.Create("DPanel", self.ContentScroll)
        skinSection:Dock(TOP)
        skinSection:SetTall(40)
        skinSection:DockMargin(0, 0, 0, 5)
        function skinSection:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
            surface.SetDrawColor(Theme.accent)
            surface.DrawRect(0, 0, 4, h)
            draw.SimpleText("SKIN MODELU (" .. numSkins .. " dostepnych)", "DermaDefaultBold", 15, h / 2, Theme.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local skinGrid = vgui.Create("DIconLayout", self.ContentScroll)
        skinGrid:Dock(TOP)
        skinGrid:SetSpaceX(8)
        skinGrid:SetSpaceY(8)
        skinGrid:DockMargin(0, 0, 0, 15)

        for skinIdx = 0, numSkins - 1 do
            local skinBtn = vgui.Create("DButton", skinGrid)
            skinBtn:SetSize(100, 120)
            skinBtn:SetText("")
            skinBtn.SkinIdx = skinIdx
            local skinPreview = vgui.Create("DModelPanel", skinBtn)
            skinPreview:SetPos(5, 5)
            skinPreview:SetSize(90, 80)
            skinPreview:SetModel(modelPath)
            skinPreview:SetFOV(25)
            skinPreview:SetCamPos(Vector(80, 0, 60))
            skinPreview:SetLookAt(Vector(0, 0, 60))
            skinPreview:SetMouseInputEnabled(false)
            local capturedSkinIdx = skinIdx
            function skinPreview:LayoutEntity(ent)
                ent:SetSkin(capturedSkinIdx)
                ent:SetAngles(Angle(0, RealTime() * 30, 0))
            end
            function skinBtn:Paint(w, h)
                local isSel = (main.AppearanceTable.ASkin or 0) == self.SkinIdx
                draw.RoundedBox(6, 0, 0, w, h, isSel and Theme.accent or (self:IsHovered() and Theme.bgLighter or Theme.bgLight))
                surface.SetDrawColor(isSel and Theme.accentHover or Theme.border)
                surface.DrawOutlinedRect(0, 0, w, h, isSel and 2 or 1)
                draw.SimpleText("Skin " .. self.SkinIdx, "DermaDefault", w / 2, h - 18, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            function skinBtn:DoClick()
                main.AppearanceTable.ASkin = self.SkinIdx
                surface.PlaySound("UI/buttonclick.wav")
            end
        end
    end

    local hasBg = false

    local function getCurrentBgValue(idx)
        local parsed = ParseBodygroupString(main.AppearanceTable.AModelBodygroups or "")
        return parsed[idx + 1] or 0
    end

    for bgIdx = 0, numBodygroups - 1 do
        local bgName = tempEnt:GetBodygroupName(bgIdx)
        local bgCount = tempEnt:GetBodygroupCount(bgIdx)
        if bgCount <= 1 then continue end
        if not bgName or bgName == "" or bgName == "studio" then continue end

        if not hasBg then
            hasBg = true
            local bgSection = vgui.Create("DPanel", self.ContentScroll)
            bgSection:Dock(TOP)
            bgSection:SetTall(40)
            bgSection:DockMargin(0, 0, 0, 5)
            function bgSection:Paint(w, h)
                draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
                surface.SetDrawColor(Theme.accent)
                surface.DrawRect(0, 0, 4, h)
                draw.SimpleText("GRUPY CIALA (Bodygroups)", "DermaDefaultBold", 15, h / 2, Theme.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        local bgPanel = vgui.Create("DPanel", self.ContentScroll)
        bgPanel:Dock(TOP)
        bgPanel:SetTall(55)
        bgPanel:DockMargin(0, 0, 0, 8)
        bgPanel.BgIdx = bgIdx
        bgPanel.BgName = bgName
        bgPanel.BgCount = bgCount
        function bgPanel:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, Theme.bgDark)
            surface.SetDrawColor(Theme.border)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(self.BgName, "DermaDefaultBold", 15, 12, Theme.text, TEXT_ALIGN_LEFT)
            draw.SimpleText(self.BgCount .. " opcji", "DermaDefault", 15, 33, Theme.textDim, TEXT_ALIGN_LEFT)
        end

        local capturedBgIdx = bgIdx
        local capturedBgCount = bgCount
        local capturedNumBodygroups = numBodygroups

        local valDisplay = vgui.Create("DPanel", bgPanel)
        valDisplay:SetSize(60, 30)
        valDisplay.BgIdx = capturedBgIdx
        function valDisplay:PerformLayout() self:SetPos(self:GetParent():GetWide() / 2 - 30, 12) end
        function valDisplay:Paint(w, h)
            local currentVal = getCurrentBgValue(self.BgIdx)
            draw.SimpleText(tostring(currentVal), "DermaLarge", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local leftBtn = vgui.Create("DButton", bgPanel)
        leftBtn:SetSize(40, 35)
        leftBtn:SetText("")
        function leftBtn:PerformLayout() self:SetPos(self:GetParent():GetWide() / 2 - 80, 10) end
        function leftBtn:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Theme.accentHover or Theme.accent)
            draw.SimpleText("<", "DermaLarge", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function leftBtn:DoClick()
            local parsed = ParseBodygroupString(main.AppearanceTable.AModelBodygroups or "")
            local cur = parsed[capturedBgIdx + 1] or 0
            cur = cur - 1
            if cur < 0 then cur = capturedBgCount - 1 end
            parsed[capturedBgIdx + 1] = cur
            main.AppearanceTable.AModelBodygroups = BuildBodygroupString(parsed, capturedNumBodygroups)
            surface.PlaySound("UI/buttonclick.wav")
        end

        local rightBtn = vgui.Create("DButton", bgPanel)
        rightBtn:SetSize(40, 35)
        rightBtn:SetText("")
        function rightBtn:PerformLayout() self:SetPos(self:GetParent():GetWide() / 2 + 40, 10) end
        function rightBtn:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Theme.accentHover or Theme.accent)
            draw.SimpleText(">", "DermaLarge", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function rightBtn:DoClick()
            local parsed = ParseBodygroupString(main.AppearanceTable.AModelBodygroups or "")
            local cur = parsed[capturedBgIdx + 1] or 0
            cur = cur + 1
            if cur >= capturedBgCount then cur = 0 end
            parsed[capturedBgIdx + 1] = cur
            main.AppearanceTable.AModelBodygroups = BuildBodygroupString(parsed, capturedNumBodygroups)
            surface.PlaySound("UI/buttonclick.wav")
        end

        if bgCount > 2 then
            local slider = vgui.Create("DNumSlider", bgPanel)
            slider:SetSize(200, 30)
            slider:SetMin(0)
            slider:SetMax(bgCount - 1)
            slider:SetDecimals(0)
            slider:SetValue(getCurrentBgValue(bgIdx))
            slider:SetText("")
            function slider:PerformLayout() self:SetPos(self:GetParent():GetWide() - 220, 12) end
            function slider:OnValueChanged(val)
                local v = math.Round(val)
                local parsed = ParseBodygroupString(main.AppearanceTable.AModelBodygroups or "")
                parsed[capturedBgIdx + 1] = v
                main.AppearanceTable.AModelBodygroups = BuildBodygroupString(parsed, capturedNumBodygroups)
            end
        end
    end

    if IsValid(tempEnt) then tempEnt:Remove() end

    if not hasBg and numSkins <= 1 then
        local noLabel = vgui.Create("DLabel", self.ContentScroll)
        noLabel:Dock(TOP)
        noLabel:SetTall(40)
        noLabel:DockMargin(0, 10, 0, 0)
        noLabel:SetText("Ten model nie ma dodatkowych opcji bodygroup ani skinow.")
        noLabel:SetFont("DermaDefault")
        noLabel:SetTextColor(Theme.textDim)
        noLabel:SetContentAlignment(5)
    end

    local debugPanel = vgui.Create("DPanel", self.ContentScroll)
    debugPanel:Dock(TOP)
    debugPanel:SetTall(40)
    debugPanel:DockMargin(0, 10, 0, 0)
    function debugPanel:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 50))
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("DEBUG - AModelBodygroups: \"" .. (main.AppearanceTable.AModelBodygroups or "") .. "\" | ASkin: " .. (main.AppearanceTable.ASkin or 0), "DermaDefault", 15, h / 2, Color(200, 200, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local resetBgBtn = vgui.Create("DButton", self.ContentScroll)
    resetBgBtn:Dock(TOP)
    resetBgBtn:SetTall(35)
    resetBgBtn:DockMargin(0, 10, 0, 0)
    resetBgBtn:SetText("")
    function resetBgBtn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Theme.bgLighter or Theme.bgLight)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("RESETUJ BODYGROUP'Y I SKIN", "DermaDefaultBold", w / 2, h / 2, Theme.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function resetBgBtn:DoClick()
        main.AppearanceTable.AModelBodygroups = ""
        main.AppearanceTable.ASkin = 0
        main:RefreshContent()
        surface.PlaySound("UI/buttonclick.wav")
    end
end

function PANEL:BuildAccessoryContent(placement)
    local main = self
    local slotIndex = placement == "head" and 1 or (placement == "face" and 2 or 3)
    CreateSearchBar(self.ContentScroll, function(query)
        main.SearchQuery = query
        main:RebuildAccessoryGrid(placement, slotIndex)
    end)
    self.AccGridParent = vgui.Create("DPanel", self.ContentScroll)
    self.AccGridParent:Dock(TOP)
    self.AccGridParent:SetTall(2000)
    function self.AccGridParent:Paint() end
    self:RebuildAccessoryGrid(placement, slotIndex)
end

function PANEL:RebuildAccessoryGrid(placement, slotIndex)
    if not IsValid(self.AccGridParent) then return end
    self.AccGridParent:Clear()
    local main = self
    local query = self.SearchQuery or ""
    local grid = vgui.Create("DIconLayout", self.AccGridParent)
    grid:Dock(TOP)
    grid:SetSpaceX(10)
    grid:SetSpaceY(10)
    local count = 1
    local noneBtn = vgui.Create("DButton", grid)
    noneBtn:SetSize(110, 130)
    noneBtn:SetText("")
    function noneBtn:Paint(w, h)
        local cur = main.AppearanceTable.AAttachments and main.AppearanceTable.AAttachments[slotIndex]
        local isSel = not cur or cur == "none" or cur == ""
        draw.RoundedBox(6, 0, 0, w, h, isSel and Theme.accent or (self:IsHovered() and Theme.bgLighter or Theme.bgLight))
        surface.SetDrawColor(isSel and Theme.accentHover or Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, isSel and 2 or 1)
        surface.SetDrawColor(Theme.textDim)
        surface.DrawLine(w/2 - 25, h/2 - 40, w/2 + 25, h/2 - 40 + 50)
        surface.DrawLine(w/2 + 25, h/2 - 40, w/2 - 25, h/2 - 40 + 50)
        draw.SimpleText("BRAK", "DermaDefaultBold", w / 2, h - 20, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function noneBtn:DoClick()
        if not main.AppearanceTable.AAttachments then main.AppearanceTable.AAttachments = {"none", "none", "none"} end
        main.AppearanceTable.AAttachments[slotIndex] = "none"
        main:RefreshContent()
        surface.PlaySound("UI/buttonclick.wav")
    end
    for key, acc in pairs(hg.Accessories or {}) do
        if key == "none" or acc.disallowinappearance then continue end
        local valid = false
        if placement == "head" then valid = (acc.placement == "head" or acc.placement == "ears")
        elseif placement == "face" then valid = (acc.placement == "face")
        elseif placement == "body" then valid = (acc.placement == "torso" or acc.placement == "spine") end
        if not valid or not CanUseAccessory(key) then continue end
        local accName = acc.name or key
        if query ~= "" and not string.find(string.lower(accName), query, 1, true) and not string.find(string.lower(key), query, 1, true) then continue end
        count = count + 1
        local btn = vgui.Create("DButton", grid)
        btn:SetSize(110, 130)
        btn:SetText("")
        btn.AccKey = key
        btn.AccData = acc
        local modelIcon = vgui.Create("DModelPanel", btn)
        modelIcon:SetPos(5, 8)
        modelIcon:SetSize(100, 75)
        modelIcon:SetModel(acc.model or "models/error.mdl")
        modelIcon:SetFOV(20)
        modelIcon:SetCamPos(Vector(30, 0, 0))
        modelIcon:SetLookAt(acc.vpos or Vector(0, 0, 0))
        modelIcon:SetMouseInputEnabled(false)
        local skin = acc.skin
        if isfunction(skin) then skin = skin() end
        timer.Simple(0, function()
            if IsValid(modelIcon) and IsValid(modelIcon.Entity) then
                modelIcon.Entity:SetSkin(skin or 0)
                if acc.bodygroups then modelIcon.Entity:SetBodyGroups(acc.bodygroups) end
            end
        end)
        function modelIcon:LayoutEntity(ent) ent:SetAngles(Angle(0, RealTime() * 30, 0)) end
        local rarityCol = GetRarityColor(acc)
        function btn:Paint(w, h)
            local cur = main.AppearanceTable.AAttachments and main.AppearanceTable.AAttachments[slotIndex]
            local isSel = cur == self.AccKey
            draw.RoundedBox(6, 0, 0, w, h, isSel and Theme.accent or (self:IsHovered() and Theme.bgLighter or Theme.bgLight))
            draw.RoundedBoxEx(6, 0, 0, w, 4, rarityCol, true, true, false, false)
            surface.SetDrawColor(isSel and Theme.accentHover or Theme.border)
            surface.DrawOutlinedRect(0, 0, w, h, isSel and 2 or 1)
            local name = self.AccData.name or self.AccKey
            if #name > 12 then name = string.sub(name, 1, 11) .. "." end
            draw.SimpleText(name, "DermaDefault", w / 2, h - 30, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("POSIADANE", "DermaDefault", w / 2, h - 14, Theme.owned, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function btn:DoClick()
            if not main.AppearanceTable.AAttachments then main.AppearanceTable.AAttachments = {"none", "none", "none"} end
            main.AppearanceTable.AAttachments[slotIndex] = key
            main:RefreshContent()
            surface.PlaySound("UI/buttonclick.wav")
        end
        function btn:DoRightClick()
            if self.AccData.bSetColor then
                local colorMenu = DermaMenu()
                local colorMixer = vgui.Create("DColorMixer", colorMenu)
                colorMixer:SetSize(200, 200)
                colorMixer:SetColor(main.AppearanceTable.AColor or Color(255, 255, 255))
                colorMixer:SetPalette(true)
                colorMixer:SetAlphaBar(false)
                function colorMixer:ValueChanged(col) main.AppearanceTable.AColor = col end
                colorMenu:AddPanel(colorMixer)
                colorMenu:Open()
            end
        end
    end
    self.AccGridParent:SetTall(math.max(math.ceil(count / 5) * 140, 50))
    if count <= 1 then
        local noLabel = vgui.Create("DLabel", self.AccGridParent)
        noLabel:Dock(TOP)
        noLabel:DockMargin(0, 10, 0, 0)
        noLabel:SetTall(40)
        noLabel:SetText(query ~= "" and "Nie znaleziono akcesoriow" or "Brak dostepnych akcesoriow")
        noLabel:SetFont("DermaDefault")
        noLabel:SetTextColor(Theme.textDim)
        noLabel:SetContentAlignment(5)
    end
end

function PANEL:BuildClothesContent(clothesType)
    local main = self
    local tMdl = GetModelData(self.AppearanceTable.AModel)
    local sex = GetModelSex(tMdl)
    local headerPanel = vgui.Create("DPanel", self.ContentScroll)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(50)
    headerPanel:DockMargin(0, 0, 0, 10)
    function headerPanel:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
        draw.SimpleText("Wybierz styl:", "DermaDefaultBold", 15, h / 2, Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local colorBtn = vgui.Create("DButton", headerPanel)
    colorBtn:SetSize(110, 35)
    colorBtn:SetText("")
    function colorBtn:PerformLayout() self:SetPos(self:GetParent():GetWide() - 130, 7) end
    function colorBtn:Paint(w, h)
        local col = main.AppearanceTable.AColor or Color(100, 100, 100)
        draw.RoundedBox(6, 0, 0, w, h, col)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local textCol = (col.r + col.g + col.b) / 3 > 128 and Color(0, 0, 0) or Color(255, 255, 255)
        draw.SimpleText("KOLOR", "DermaDefaultBold", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function colorBtn:DoClick()
        local colorMenu = DermaMenu()
        local colorMixer = vgui.Create("DColorMixer", colorMenu)
        colorMixer:SetSize(200, 200)
        colorMixer:SetColor(main.AppearanceTable.AColor or Color(100, 100, 100))
        colorMixer:SetPalette(true)
        colorMixer:SetAlphaBar(false)
        function colorMixer:ValueChanged(col) main.AppearanceTable.AColor = col end
        colorMenu:AddPanel(colorMixer)
        colorMenu:Open()
    end
    CreateSearchBar(self.ContentScroll, function(query)
        main.SearchQuery = query
        main:RebuildClothesGrid(clothesType, sex)
    end)
    self.ClothesGridParent = vgui.Create("DPanel", self.ContentScroll)
    self.ClothesGridParent:Dock(TOP)
    self.ClothesGridParent:SetTall(500)
    function self.ClothesGridParent:Paint() end
    self:RebuildClothesGrid(clothesType, sex)
end

function PANEL:RebuildClothesGrid(clothesType, sex)
    if not IsValid(self.ClothesGridParent) then return end
    self.ClothesGridParent:Clear()
    local main = self
    local query = self.SearchQuery or ""
    local clothes = hg.Appearance.Clothes and hg.Appearance.Clothes[sex] or {}
    local grid = vgui.Create("DIconLayout", self.ClothesGridParent)
    grid:Dock(TOP)
    grid:SetSpaceX(10)
    grid:SetSpaceY(10)
    local clothesNames = {
        normal = "Zwykly", formal = "Formalny", plaid = "Krata",
        striped = "Paski", young = "Mlodziez", cold = "Zimowy",
        casual = "Luzny", sweater_xmas = "Swiateczny", worker = "Robotnik",
    }
    local count = 0
    for key, matPath in pairs(clothes) do
        local displayName = clothesNames[key] or key
        if query ~= "" and not string.find(string.lower(displayName), query, 1, true) and not string.find(string.lower(key), query, 1, true) then continue end
        count = count + 1
        local btn = vgui.Create("DButton", grid)
        btn:SetSize(130, 50)
        btn:SetText("")
        btn.ClothesKey = key
        function btn:Paint(w, h)
            local isSel = main.AppearanceTable.AClothes and main.AppearanceTable.AClothes[clothesType] == self.ClothesKey
            draw.RoundedBox(6, 0, 0, w, h, isSel and Theme.accent or (self:IsHovered() and Theme.bgLighter or Theme.bgLight))
            surface.SetDrawColor(isSel and Theme.accentHover or Theme.border)
            surface.DrawOutlinedRect(0, 0, w, h, isSel and 2 or 1)
            draw.SimpleText(clothesNames[self.ClothesKey] or self.ClothesKey, "DermaDefaultBold", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function btn:DoClick()
            if not main.AppearanceTable.AClothes then main.AppearanceTable.AClothes = {main = "normal", pants = "normal", boots = "normal"} end
            main.AppearanceTable.AClothes[clothesType] = self.ClothesKey
            main:RefreshContent()
            surface.PlaySound("UI/buttonclick.wav")
        end
    end
    self.ClothesGridParent:SetTall(math.max(math.ceil(count / 4) * 60, 50))
    if count == 0 then
        local noLabel = vgui.Create("DLabel", self.ClothesGridParent)
        noLabel:Dock(TOP)
        noLabel:SetTall(40)
        noLabel:SetText("Nie znaleziono ubran")
        noLabel:SetFont("DermaDefault")
        noLabel:SetTextColor(Theme.textDim)
        noLabel:SetContentAlignment(5)
    end
end

function PANEL:BuildGlovesContent()
    local main = self
    if not main.AppearanceTable.ABodygroups then main.AppearanceTable.ABodygroups = {} end
    local tMdl = GetModelData(self.AppearanceTable.AModel)
    local sex = GetModelSex(tMdl)
    local headerPanel = vgui.Create("DPanel", self.ContentScroll)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(50)
    headerPanel:DockMargin(0, 0, 0, 10)
    function headerPanel:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
        draw.SimpleText("Wybierz rekawice:", "DermaDefaultBold", 15, h / 2, Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local colorBtn = vgui.Create("DButton", headerPanel)
    colorBtn:SetSize(110, 35)
    colorBtn:SetText("")
    function colorBtn:PerformLayout() self:SetPos(self:GetParent():GetWide() - 130, 7) end
    function colorBtn:Paint(w, h)
        local col = main.AppearanceTable.AColor or Color(100, 100, 100)
        draw.RoundedBox(6, 0, 0, w, h, col)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local textCol = (col.r + col.g + col.b) / 3 > 128 and Color(0, 0, 0) or Color(255, 255, 255)
        draw.SimpleText("KOLOR", "DermaDefaultBold", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function colorBtn:DoClick()
        local colorMenu = DermaMenu()
        local colorMixer = vgui.Create("DColorMixer", colorMenu)
        colorMixer:SetSize(200, 200)
        colorMixer:SetColor(main.AppearanceTable.AColor or Color(100, 100, 100))
        colorMixer:SetPalette(true)
        colorMixer:SetAlphaBar(false)
        function colorMixer:ValueChanged(col) main.AppearanceTable.AColor = col end
        colorMenu:AddPanel(colorMixer)
        colorMenu:Open()
    end
    local handsData, handsKey = GetHandsData(sex)
    if not handsData or not handsKey then
        local noLabel = vgui.Create("DLabel", self.ContentScroll)
        noLabel:Dock(TOP)
        noLabel:SetTall(30)
        noLabel:SetText("Brak dostepnych rekawic dla tego modelu")
        noLabel:SetFont("DermaDefaultBold")
        noLabel:SetTextColor(Theme.textDim)
        return
    end
    self.CurrentHandsKey = handsKey
    CreateSearchBar(self.ContentScroll, function(query)
        main.SearchQuery = query
        main:RebuildGlovesGrid(sex, handsData, handsKey)
    end)
    self.GlovesGridParent = vgui.Create("DPanel", self.ContentScroll)
    self.GlovesGridParent:Dock(TOP)
    self.GlovesGridParent:SetTall(500)
    function self.GlovesGridParent:Paint() end
    self:RebuildGlovesGrid(sex, handsData, handsKey)
end

function PANEL:RebuildGlovesGrid(sex, handsData, handsKey)
    if not IsValid(self.GlovesGridParent) then return end
    self.GlovesGridParent:Clear()
    local main = self
    local query = self.SearchQuery or ""
    if not handsData then self.GlovesGridParent:SetTall(50) return end
    local grid = vgui.Create("DIconLayout", self.GlovesGridParent)
    grid:Dock(TOP)
    grid:SetSpaceX(10)
    grid:SetSpaceY(10)
    local glovesNames = {
        ["Gloves"] = "Rekawiczki", ["Gloves fingerless"] = "Bezpalcowe",
        ["Skilet"] = "Szkielet", ["Skilet fingerless"] = "Szkielet Bezp.",
        ["Winter"] = "Zimowe", ["Winter fingerless"] = "Zimowe Bezp.",
        ["Bikers gloves"] = "Motocyklowe", ["Bikers wool"] = "Motocykl. Welna",
        ["Wool fingerless"] = "Welna Bezp.", ["Mitten wool"] = "Lapki",
    }
    if query == "" or string.find("brak", query, 1, true) then
        local noneBtn = vgui.Create("DButton", grid)
        noneBtn:SetSize(140, 55)
        noneBtn:SetText("")
        function noneBtn:Paint(w, h)
            local cur = main.AppearanceTable.ABodygroups and main.AppearanceTable.ABodygroups[handsKey]
            local isSel = not cur or cur == "" or cur == "None" or cur == "Brak"
            draw.RoundedBox(6, 0, 0, w, h, isSel and Theme.accent or (self:IsHovered() and Theme.bgLighter or Theme.bgLight))
            surface.SetDrawColor(isSel and Theme.accentHover or Theme.border)
            surface.DrawOutlinedRect(0, 0, w, h, isSel and 2 or 1)
            draw.SimpleText("BRAK", "DermaDefaultBold", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function noneBtn:DoClick()
            if not main.AppearanceTable.ABodygroups then main.AppearanceTable.ABodygroups = {} end
            main.AppearanceTable.ABodygroups[handsKey] = nil
            surface.PlaySound("UI/buttonclick.wav")
        end
    end
    local count = 0
    for name, data in pairs(handsData) do
        if name == "None" or name == "Brak" then continue end
        if type(name) == "number" then continue end
        local displayName = glovesNames[name] or name
        if query ~= "" and not string.find(string.lower(displayName), query, 1, true) and not string.find(string.lower(name), query, 1, true) then continue end
        count = count + 1
        local btn = vgui.Create("DButton", grid)
        btn:SetSize(140, 55)
        btn:SetText("")
        btn.GloveName = name
        function btn:Paint(w, h)
            local cur = main.AppearanceTable.ABodygroups and main.AppearanceTable.ABodygroups[handsKey]
            local isSel = cur == self.GloveName
            draw.RoundedBox(6, 0, 0, w, h, isSel and Theme.accent or (self:IsHovered() and Theme.bgLighter or Theme.bgLight))
            surface.SetDrawColor(isSel and Theme.accentHover or Theme.border)
            surface.DrawOutlinedRect(0, 0, w, h, isSel and 2 or 1)
            draw.SimpleText(glovesNames[self.GloveName] or self.GloveName, "DermaDefault", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function btn:DoClick()
            if not main.AppearanceTable.ABodygroups then main.AppearanceTable.ABodygroups = {} end
            main.AppearanceTable.ABodygroups[handsKey] = self.GloveName
            surface.PlaySound("UI/buttonclick.wav")
        end
    end
    self.GlovesGridParent:SetTall(math.max(math.ceil((count + 1) / 4) * 65, 70))
    if count == 0 and query ~= "" then
        local noLabel = vgui.Create("DLabel", self.GlovesGridParent)
        noLabel:Dock(TOP)
        noLabel:DockMargin(0, 10, 0, 0)
        noLabel:SetTall(30)
        noLabel:SetText("Nie znaleziono rekawic")
        noLabel:SetFont("DermaDefault")
        noLabel:SetTextColor(Theme.textDim)
        noLabel:SetContentAlignment(5)
    end
end

function PANEL:BuildFacemapContent()
    local main = self
    local tMdl = GetModelData(self.AppearanceTable.AModel)
    local headerPanel = vgui.Create("DPanel", self.ContentScroll)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(50)
    headerPanel:DockMargin(0, 0, 0, 10)
    function headerPanel:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
        draw.SimpleText("Wybierz mape twarzy:", "DermaDefaultBold", 15, h / 2, Theme.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    if not tMdl or not tMdl.mdl then
        local noLabel = vgui.Create("DLabel", self.ContentScroll)
        noLabel:Dock(TOP)
        noLabel:SetTall(30)
        noLabel:SetText("Wybierz najpierw model postaci")
        noLabel:SetFont("DermaDefaultBold")
        noLabel:SetTextColor(Theme.textDim)
        return
    end
    local fmOverride = hg.Appearance.FacemapsModels and hg.Appearance.FacemapsModels[tMdl.mdl]
    local fmSlots = fmOverride and hg.Appearance.FacemapsSlots and hg.Appearance.FacemapsSlots[fmOverride]
    if not fmSlots then
        local noLabel = vgui.Create("DLabel", self.ContentScroll)
        noLabel:Dock(TOP)
        noLabel:SetTall(30)
        noLabel:SetText("Brak map twarzy dla tego modelu")
        noLabel:SetFont("DermaDefaultBold")
        noLabel:SetTextColor(Theme.textDim)
        return
    end
    CreateSearchBar(self.ContentScroll, function(query)
        main.SearchQuery = query
        main:RebuildFacemapGrid(fmSlots)
    end)
    self.FacemapGridParent = vgui.Create("DPanel", self.ContentScroll)
    self.FacemapGridParent:Dock(TOP)
    self.FacemapGridParent:SetTall(500)
    function self.FacemapGridParent:Paint() end
    self:RebuildFacemapGrid(fmSlots)
end

function PANEL:RebuildFacemapGrid(fmSlots)
    if not IsValid(self.FacemapGridParent) then return end
    self.FacemapGridParent:Clear()
    local main = self
    local query = self.SearchQuery or ""
    local grid = vgui.Create("DIconLayout", self.FacemapGridParent)
    grid:Dock(TOP)
    grid:SetSpaceX(10)
    grid:SetSpaceY(10)
    local count = 0
    for name, matPath in pairs(fmSlots) do
        if query ~= "" and not string.find(string.lower(name), query, 1, true) then continue end
        count = count + 1
        local btn = vgui.Create("DButton", grid)
        btn:SetSize(130, 50)
        btn:SetText("")
        btn.FacemapName = name
        function btn:Paint(w, h)
            local isSel = main.AppearanceTable.AFacemap == self.FacemapName
            draw.RoundedBox(6, 0, 0, w, h, isSel and Theme.accent or (self:IsHovered() and Theme.bgLighter or Theme.bgLight))
            surface.SetDrawColor(isSel and Theme.accentHover or Theme.border)
            surface.DrawOutlinedRect(0, 0, w, h, isSel and 2 or 1)
            draw.SimpleText(self.FacemapName, "DermaDefault", w / 2, h / 2, Theme.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function btn:DoClick()
            main.AppearanceTable.AFacemap = self.FacemapName
            main:RefreshContent()
            surface.PlaySound("UI/buttonclick.wav")
        end
    end
    self.FacemapGridParent:SetTall(math.max(math.ceil(count / 4) * 60, 50))
    if count == 0 then
        local noLabel = vgui.Create("DLabel", self.FacemapGridParent)
        noLabel:Dock(TOP)
        noLabel:SetTall(40)
        noLabel:SetText("Nie znaleziono map twarzy")
        noLabel:SetFont("DermaDefault")
        noLabel:SetTextColor(Theme.textDim)
        noLabel:SetContentAlignment(5)
    end
end

local presetsDir = "zcity/appearances/presets/"
local function EnsurePresetsDir()
    if not file.Exists("zcity", "DATA") then file.CreateDir("zcity") end
    if not file.Exists("zcity/appearances", "DATA") then file.CreateDir("zcity/appearances") end
    if not file.Exists(presetsDir, "DATA") then file.CreateDir(presetsDir) end
end
local function SavePreset(name, data)
    EnsurePresetsDir()
    file.Write(presetsDir .. name .. ".json", util.TableToJSON(data, true))
end
local function LoadPreset(name)
    local path = presetsDir .. name .. ".json"
    if not file.Exists(path, "DATA") then return nil end
    local raw = file.Read(path, "DATA")
    if not raw then return nil end
    local tbl = util.JSONToTable(raw)
    if tbl then tbl = EnsureAppearanceStructure(tbl) end
    return tbl
end
local function GetPresetList()
    EnsurePresetsDir()
    local files = file.Find(presetsDir .. "*.json", "DATA")
    local presets = {}
    for _, f in ipairs(files or {}) do table.insert(presets, string.StripExtension(f)) end
    return presets
end
local function DeletePreset(name)
    local path = presetsDir .. name .. ".json"
    if file.Exists(path, "DATA") then file.Delete(path) return true end
    return false
end

function PANEL:BuildPresetsContent()
    local main = self
    local savePanel = vgui.Create("DPanel", self.ContentScroll)
    savePanel:Dock(TOP)
    savePanel:SetTall(85)
    savePanel:DockMargin(0, 0, 0, 15)
    function savePanel:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("ZAPISZ AKTUALNY WYGLAD JAKO PRESET", "DermaDefaultBold", 15, 15, Theme.accent, TEXT_ALIGN_LEFT)
    end
    local saveEntry = vgui.Create("DTextEntry", savePanel)
    saveEntry:SetPos(15, 45)
    saveEntry:SetSize(300, 30)
    saveEntry:SetFont("DermaDefault")
    saveEntry:SetPlaceholderText("Wpisz nazwe presetu...")
    function saveEntry:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Theme.bgDark)
        surface.SetDrawColor(Theme.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        self:DrawTextEntryText(Theme.text, Theme.accent, Theme.text)
    end
    local saveBtn = vgui.Create("DButton", savePanel)
    saveBtn:SetPos(325, 45)
    saveBtn:SetSize(100, 30)
    saveBtn:SetText("ZAPISZ")
    saveBtn:SetFont("DermaDefaultBold")
    saveBtn:SetTextColor(Theme.text)
    function saveBtn:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Theme.successHover or Theme.success) end
    function saveBtn:DoClick()
        local name = saveEntry:GetValue()
        if name == "" or #name < 2 then
            notification.AddLegacy("Wpisz nazwe presetu (min. 2 znaki)", NOTIFY_ERROR, 3)
            surface.PlaySound("buttons/button10.wav")
            return
        end
        name = string.gsub(name, "[^%w%s_-]", "")
        SavePreset(name, main.AppearanceTable)
        notification.AddLegacy("Preset '" .. name .. "' zapisany!", NOTIFY_GENERIC, 3)
        surface.PlaySound("buttons/button14.wav")
        saveEntry:SetText("")
        main:RefreshContent()
    end
    CreateSearchBar(self.ContentScroll, function(query)
        main.SearchQuery = query
        main:RebuildPresetsList()
    end)
    self.PresetsListParent = vgui.Create("DPanel", self.ContentScroll)
    self.PresetsListParent:Dock(TOP)
    self.PresetsListParent:SetTall(1000)
    function self.PresetsListParent:Paint() end
    self:RebuildPresetsList()
end

function PANEL:RebuildPresetsList()
    if not IsValid(self.PresetsListParent) then return end
    self.PresetsListParent:Clear()
    local main = self
    local query = self.SearchQuery or ""
    local presetList = GetPresetList()
    local filtered = {}
    for _, name in ipairs(presetList) do
        if query == "" or string.find(string.lower(name), query, 1, true) then table.insert(filtered, name) end
    end
    if #filtered == 0 then
        local noLabel = vgui.Create("DLabel", self.PresetsListParent)
        noLabel:Dock(TOP)
        noLabel:SetTall(40)
        noLabel:SetText(query ~= "" and "Nie znaleziono presetow" or "Brak zapisanych presetow")
        noLabel:SetFont("DermaDefault")
        noLabel:SetTextColor(Theme.textDim)
        noLabel:SetContentAlignment(5)
        self.PresetsListParent:SetTall(50)
        return
    end
    local listLabel = vgui.Create("DLabel", self.PresetsListParent)
    listLabel:Dock(TOP)
    listLabel:SetTall(30)
    listLabel:SetText("TWOJE PRESETY (" .. #filtered .. ")")
    listLabel:SetFont("DermaDefaultBold")
    listLabel:SetTextColor(Theme.text)
    listLabel:DockMargin(0, 0, 0, 10)
    for _, presetName in ipairs(filtered) do
        local presetPanel = vgui.Create("DPanel", self.PresetsListParent)
        presetPanel:Dock(TOP)
        presetPanel:SetTall(55)
        presetPanel:DockMargin(0, 0, 0, 8)
        function presetPanel:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, Theme.bgLighter)
            surface.SetDrawColor(Theme.border)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        local nameLabel = vgui.Create("DLabel", presetPanel)
        nameLabel:SetPos(15, 17)
        nameLabel:SetSize(250, 20)
        nameLabel:SetText(presetName)
        nameLabel:SetFont("DermaDefaultBold")
        nameLabel:SetTextColor(Theme.text)
        local loadBtn = vgui.Create("DButton", presetPanel)
        loadBtn:SetSize(90, 35)
        loadBtn:SetText("WCZYTAJ")
        loadBtn:SetFont("DermaDefault")
        loadBtn:SetTextColor(Theme.text)
        function loadBtn:PerformLayout() self:SetPos(self:GetParent():GetWide() - 200, 10) end
        function loadBtn:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 120, 200) or Color(50, 100, 180)) end
        function loadBtn:DoClick()
            local data = LoadPreset(presetName)
            if data then
                main.AppearanceTable = data
                if IsValid(main.NameEntry) then main.NameEntry:SetText(data.AName or "Obywatel") end
                notification.AddLegacy("Preset '" .. presetName .. "' wczytany!", NOTIFY_GENERIC, 3)
                surface.PlaySound("buttons/button14.wav")
                main:RefreshContent()
            else
                notification.AddLegacy("Blad wczytywania presetu!", NOTIFY_ERROR, 3)
                surface.PlaySound("buttons/button10.wav")
            end
        end
        local deleteBtn = vgui.Create("DButton", presetPanel)
        deleteBtn:SetSize(80, 35)
        deleteBtn:SetText("USUN")
        deleteBtn:SetFont("DermaDefault")
        deleteBtn:SetTextColor(Theme.text)
        function deleteBtn:PerformLayout() self:SetPos(self:GetParent():GetWide() - 100, 10) end
        function deleteBtn:Paint(w, h) draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(200, 60, 60) or Color(150, 50, 50)) end
        function deleteBtn:DoClick()
            Derma_Query("Czy na pewno chcesz usunac preset '" .. presetName .. "'?", "Potwierdzenie",
                "Tak", function()
                    DeletePreset(presetName)
                    notification.AddLegacy("Preset usuniety!", NOTIFY_HINT, 2)
                    surface.PlaySound("buttons/button15.wav")
                    main:RefreshContent()
                end,
                "Nie", function() end)
        end
    end
    self.PresetsListParent:SetTall(40 + #filtered * 63)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, h, Theme.bgDark)
    local time = CurTime()
    local gridSize = 50
    local offsetX = (time * 20) % gridSize
    local offsetY = (time * 15) % gridSize
    surface.SetDrawColor(Theme.accent.r, Theme.accent.g, Theme.accent.b, 20)
    for x = -gridSize + offsetX, w, gridSize do surface.DrawLine(x, 0, x, h) end
    for y = -gridSize + offsetY, h, gridSize do surface.DrawLine(0, y, w, y) end
    UpdateParticles()
    DrawParticles()
    for i = 0, 300, 10 do
        surface.SetDrawColor(0, 0, 0, (1 - i / 300) * 80)
        surface.DrawOutlinedRect(i, i, w - i * 2, h - i * 2, 10)
    end
end

vgui.Register("ZCity_AppearanceEditor", PANEL, "DFrame")

concommand.Add("hg_appearance_menu", function()
    if IsValid(ZCityAppearanceEditor) then ZCityAppearanceEditor:Remove() end
    if hg.PointShop and hg.PointShop.SendNET then
        hg.PointShop:SendNET("SendPointShopVars", nil, function(data)
            ZCityAppearanceEditor = vgui.Create("ZCity_AppearanceEditor")
        end)
    else
        ZCityAppearanceEditor = vgui.Create("ZCity_AppearanceEditor")
    end
end)

concommand.Add("appearance", function() RunConsoleCommand("hg_appearance_menu") end)