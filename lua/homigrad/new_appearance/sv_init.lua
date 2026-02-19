util.AddNetworkString("Get_Appearance")
util.AddNetworkString("OnlyGet_Appearance")
hg.Appearance = hg.Appearance or {}
local APmodule = hg.Appearance

hg.PointShop = hg.PointShop or {}
local PSmodule = hg.PointShop

local function CheckAttachments(ply, tbl)
    if not IsValid(ply) or not ply:IsPlayer() then return tbl end
    if not istable(tbl) then return tbl end
    if hg.Appearance.GetAccessToAll(ply) then return tbl end

    tbl.AAttachments = tbl.AAttachments or {}
    tbl.ABodygroups  = tbl.ABodygroups or {}
    tbl.AModelBodygroups = tbl.AModelBodygroups or ""
    tbl.ASkin = tbl.ASkin or 0

    local function PSHasSrv(id)
        if id == nil then return false end
        if not ply.PS_HasItem then return false end

        if ply:PS_HasItem(id) then return true end
        if isnumber(id) and ply:PS_HasItem(tostring(id)) then return true end
        if isstring(id) then
            local n = tonumber(id)
            if n and ply:PS_HasItem(n) then return true end
        end
        return false
    end

    local PlayerModels = APmodule.PlayerModels or {}
    local function GetModelData(amodel)
        return (PlayerModels[1] and PlayerModels[1][amodel]) or (PlayerModels[2] and PlayerModels[2][amodel])
    end

    local modelData = GetModelData(tbl.AModel)
    if istable(modelData) and modelData.psItemID then
        if not PSHasSrv(modelData.psItemID) then
            tbl.AModel = (APmodule.SkeletonAppearanceTable and APmodule.SkeletonAppearanceTable.AModel) or "Male 01"
            tbl.AModelBodygroups = ""
            tbl.ASkin = 0
            if ply.ChatPrint then
                ply:ChatPrint("Model wymaga zakupu: " .. tostring(modelData.psItemID) .. " (cofnięto)")
            end
        end
    end

    for i = 1, #tbl.AAttachments do
        local uid = tbl.AAttachments[i]

        if not uid or uid == "" or uid == "none" then
            continue
        end

        local acc = hg.Accessories and hg.Accessories[uid]
        if not acc then
            tbl.AAttachments[i] = "none"
            continue
        end

        if acc.disallowinappearance then
            tbl.AAttachments[i] = "none"
            continue
        end

        local requiresPurchase = (acc.bPointShop ~= false) and not acc.free and not acc.bFree and not acc.noPointShop
        if requiresPurchase then
            local psid = acc.psItemID or acc.pointshopID or acc.ID or acc.id or uid

            if not PSHasSrv(psid) and not PSHasSrv(uid) then
                tbl.AAttachments[i] = "none"
                if ply.ChatPrint then ply:ChatPrint(uid .. " - not bought, removed") end
            end
        end
    end

    local tMdl = GetModelData(tbl.AModel) or tbl.AModel
    local sexIndex = (istable(tMdl) and tMdl.sex) and 2 or 1

    for k, v in pairs(tbl.ABodygroups) do
        if not hg.Appearance.Bodygroups[k] then continue end
        if not hg.Appearance.Bodygroups[k][sexIndex] then continue end

        local bodygroup = hg.Appearance.Bodygroups[k][sexIndex][v]
        if not bodygroup then continue end

        local uid = bodygroup.ID
        if bodygroup[2] and uid and not PSHasSrv(uid) then
            tbl.ABodygroups[k] = nil
            if ply.ChatPrint then ply:ChatPrint(v .. " - not bought, removed") end
        end
    end

    return tbl
end

local function ForceApplyAppearance(ply, tbl, noModelChange)
    local PlayerModels = APmodule.PlayerModels or {}
    local tMdl =
        (PlayerModels[1] and PlayerModels[1][tbl.AModel]) or
        (PlayerModels[2] and PlayerModels[2][tbl.AModel]) or
        tbl.AModel

    local mdl = istable(tMdl) and tMdl.mdl or tMdl
    local sexIndex = (istable(tMdl) and tMdl.sex) and 2 or 1

    if mdl ~= ply:GetModel() and not noModelChange then
        ply:SetModel(mdl)
    end

    local clr = tbl.AColor
    if clr then
        if ply.SetPlayerColor then
            ply:SetPlayerColor(Vector(clr.r / 255, clr.g / 255, clr.b / 255))
        end
        ply:SetNWVector("PlayerColor", Vector(clr.r / 255, clr.g / 255, clr.b / 255))
    end

    ply:SetSubMaterial()

    local mats = ply:GetMaterials()

    if istable(tMdl) then
        for k, v in pairs(tMdl.submatSlots or {}) do
            local slot = 1
            for i = 1, #mats do
                if mats[i] == v then slot = i - 1 break end
            end

            local clothesKey = tbl.AClothes and tbl.AClothes[k] or nil
            local clothesMat =
                (hg.Appearance.Clothes[sexIndex] and clothesKey and hg.Appearance.Clothes[sexIndex][clothesKey])
                or (hg.Appearance.Clothes[sexIndex] and hg.Appearance.Clothes[sexIndex]["normal"])
                or nil

            if clothesMat then
                ply:SetSubMaterial(slot, clothesMat)
            end

            ply:SetNWString("Colthes" .. k, clothesKey or "normal")
        end
    end

    for i = 1, #mats do
        if hg.Appearance.FacemapsSlots[mats[i]] and hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap] then
            ply:SetSubMaterial(i - 1, hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap])
        end
    end

    ply:SetNWString("PlayerName", tbl.AName)

    if tbl.AModelBodygroups and tbl.AModelBodygroups ~= "" then
        ply:SetBodyGroups(tbl.AModelBodygroups)
    else
        ply:SetBodyGroups("00000000000000000000")
    end

    if tbl.ASkin and tbl.ASkin > 0 then
        ply:SetSkin(tbl.ASkin)
    else
        ply:SetSkin(0)
    end

    local bodygroups = ply:GetBodyGroups()
    tbl.ABodygroups = tbl.ABodygroups or {}

    for k, v in ipairs(bodygroups) do
        if not v.name then continue end
        if not tbl.ABodygroups[v.name] then continue end
        if not hg.Appearance.Bodygroups[v.name] then continue end

        for i = 0, #v.submodels do
            local b = v.submodels[i]

            if not hg.Appearance.Bodygroups[v.name][sexIndex] then continue end
            if not hg.Appearance.Bodygroups[v.name][sexIndex][tbl.ABodygroups[v.name]] then continue end
            if hg.Appearance.Bodygroups[v.name][sexIndex][tbl.ABodygroups[v.name]][1] ~= b then continue end

            ply:SetBodygroup(k - 1, i)
        end
    end

    ply:SetNetVar("Accessories", tbl.AAttachments)

    ply:SetNWString("AModelBodygroups", tbl.AModelBodygroups or "")
    ply:SetNWInt("ASkin", tbl.ASkin or 0)

    ply.CurAppearance = {}
    table.CopyFromTo(tbl, ply.CurAppearance)
end

local function WearAppearance(ply, tbl)
    local checked = CheckAttachments(ply, tbl)
    ForceApplyAppearance(ply, checked)
end

APmodule.ForceApplyAppearance = ForceApplyAppearance

local tWaitResponse = {}

function ApplyAppearance(Client, tAppearance, bRandom, bResponeIsValid, bUseCahsed)
    if not IsValid(Client) then return end
    if bRandom or (Client.IsBot and Client:IsBot()) or (Client.IsRagdoll and Client:IsRagdoll()) then
        tAppearance = APmodule.GetRandomAppearance()
        WearAppearance(Client, tAppearance)
        return
    end

    if bUseCahsed then
        tAppearance = APmodule.GetRandomAppearance()
        tAppearance = Client.CachedAppearance or tAppearance
        if not APmodule.AppearanceValidater(tAppearance) then tAppearance = APmodule.GetRandomAppearance() end
        net.Start("OnlyGet_Appearance")
        net.Send(Client)
        WearAppearance(Client, tAppearance)
        return
    end

    if not bResponeIsValid then
        tWaitResponse[Client] = CurTime() + 3
        net.Start("Get_Appearance")
        net.Send(Client)
        return
    end

    if not tWaitResponse[Client] then return end
    if tWaitResponse[Client] < CurTime() then
        ApplyAppearance(Client, nil, true)
        return
    end

    if not tAppearance then ApplyAppearance(Client, nil, true) return end
    if not APmodule.AppearanceValidater(tAppearance) then ApplyAppearance(Client, nil, true) return end

    WearAppearance(Client, tAppearance)
end

net.Receive("Get_Appearance", function(len, client)
    local tAppearance = net.ReadTable()
    local bRandom = net.ReadBool()
    if not APmodule.AppearanceValidater(tAppearance) then bRandom = true end

    ApplyAppearance(client, tAppearance, table.IsEmpty(tAppearance) and true or bRandom, true)
end)

net.Receive("OnlyGet_Appearance", function(len, client)
    local tAppearance = net.ReadTable()

    if not tAppearance or table.IsEmpty(tAppearance) then
        client.CachedAppearance = APmodule.GetRandomAppearance()
        return
    end

    if not APmodule.AppearanceValidater(tAppearance) then
        client.CachedAppearance = APmodule.GetRandomAppearance()
        return
    end

    tAppearance = CheckAttachments(client, tAppearance)
    client.CachedAppearance = tAppearance
end)

APmodule.ApplyAppearance = ApplyAppearance

function ApplyAppearanceRagdoll(ent, ply)
    local Appearance = ply.CurAppearance
    if not Appearance then return end
    ent:SetNWString("PlayerName", ply:GetNWString("PlayerName", Appearance.AName))
    ent:SetNetVar("Accessories", ply:GetNetVar("Accessories", ""))

    if Appearance.AModelBodygroups and Appearance.AModelBodygroups ~= "" then
        ent:SetBodyGroups(Appearance.AModelBodygroups)
    end

    if Appearance.ASkin then
        ent:SetSkin(Appearance.ASkin)
    end

    local PlayerModels = APmodule.PlayerModels or {}
    local tMdl =
        (PlayerModels[1] and PlayerModels[1][ent:GetModel()]) or
        (PlayerModels[2] and PlayerModels[2][ent:GetModel()]) or
        ent:GetModel()

    if istable(tMdl) then
        for k, v in pairs(tMdl.submatSlots or {}) do
            ent:SetNWString("Colthes" .. k, ply:GetNWString("Colthes" .. k, "normal"))
        end
    end
end

if engine.ActiveGamemode() == "sandbox" then
    hook.Add("PlayerSpawn", "SetAppearance", function(ply)
        if OverrideSpawn then return end
        timer.Simple(0, function()
            ApplyAppearance(ply, nil, nil, nil, true)
        end)
    end)
end