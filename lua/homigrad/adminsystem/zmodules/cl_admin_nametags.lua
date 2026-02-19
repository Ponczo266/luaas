local ENABLED = false
local avatars = {}
local roleData = {}

surface.CreateFont("RoleESP_Name", {
    font = "Arial",
    size = 20,
    weight = 800,
    antialias = true,
    outline = true
})

surface.CreateFont("RoleESP_Role", {
    font = "Arial",
    size = 18,
    weight = 700,
    antialias = true,
    outline = true
})

local function RequestRoleUpdate()
    if not LocalPlayer():IsSuperAdmin() then return end
    net.Start("AdminNametags_RequestRoles")
    net.SendToServer()
end

local function GetRoleInfo(ply)
    local idx = ply:EntIndex()
    local data = roleData[idx]
    
    if data then
        if data.isTraitor == true then
            return data.MainTraitor and "MAIN TRAITOR" or "TRAITOR"
        end
        
        if data.isGunner == true then
            return "GUNNER"
        end
        
        if data.isPolice == true then
            return "POLICE"
        end
        
        if data.SubRole and data.SubRole ~= "" and data.SubRole ~= "none" then
            return string.upper(data.SubRole)
        end
        
        if data.Profession and data.Profession ~= "" and data.Profession ~= "none" then
            return string.upper(data.Profession)
        end
    end
    
    local teamName = team.GetName(ply:Team())
    
    if teamName == "Players" then
        if data then
            return "INNOCENT"
        else
            return "WAITING"
        end
    end
    
    return string.upper(teamName)
end

local function GetRoleColor(role)
    local r = string.lower(role)
    
    if string.find(r, "main traitor") then
        return Color(180, 0, 0)
    elseif string.find(r, "traitor") then
        return Color(255, 60, 60)
    elseif string.find(r, "gunner") then
        return Color(180, 80, 255)
    elseif string.find(r, "police") then
        return Color(60, 150, 255)
    elseif string.find(r, "innocent") then
        return Color(60, 255, 60)
    elseif string.find(r, "waiting") then
        return Color(180, 180, 180)
    else
        return Color(230, 230, 230)
    end
end

local function GetAvatar(ply)
    local sid = ply:SteamID64()
    if not sid then return nil end

    if avatars[sid] and IsValid(avatars[sid]) then
        return avatars[sid]
    end

    local av = vgui.Create("AvatarImage")
    av:SetSize(36, 36)
    av:SetPlayer(ply, 64)
    av:SetPaintedManually(true)
    avatars[sid] = av

    return av
end

local function DrawGlowBox(x, y, w, h, col, glow)
    for i = 5, 1, -1 do
        local alpha = glow * (1 - i/5)
        draw.RoundedBox(8, x - i*2, y - i*2, w + i*4, h + i*4, Color(col.r, col.g, col.b, alpha))
    end
end

hook.Add("HUDPaint", "AdminNametags_Draw", function()
    if not ENABLED then return end

    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if not lp:IsSuperAdmin() then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply == lp then continue end
        if not IsValid(ply) then continue end
        if not ply:Alive() then continue end

        local headPos = ply:GetPos() + Vector(0, 0, 82)

        local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
        if bone then
            local bp = ply:GetBonePosition(bone)
            if bp then headPos = bp + Vector(0, 0, 12) end
        end

        local screenPos = headPos:ToScreen()
        if not screenPos.visible then continue end

        local dist = lp:GetPos():Distance(ply:GetPos())
        if dist > 3000 then continue end

        local x = screenPos.x
        local y = screenPos.y

        local nick = ply:Nick()
        local role = GetRoleInfo(ply)
        local roleCol = GetRoleColor(role)

        local boxW = 200
        local boxH = 52
        local bx = x - boxW / 2
        local by = y - boxH - 10

        local fadeAlpha = math.Clamp(1 - (dist / 3000), 0.3, 1)

        DrawGlowBox(bx, by, boxW, boxH, roleCol, 20 * fadeAlpha)

        draw.RoundedBox(8, bx, by, boxW, boxH, Color(10, 10, 10, 230 * fadeAlpha))
        
        draw.RoundedBox(8, bx + 1, by + 1, boxW - 2, boxH - 2, Color(30, 30, 30, 220 * fadeAlpha))
        
        draw.RoundedBoxEx(8, bx + 1, by + 1, boxW - 2, 4, ColorAlpha(roleCol, 255 * fadeAlpha), true, true, false, false)

        local av = GetAvatar(ply)
        if av and IsValid(av) then
            local avSize = 36
            local avX = bx + 7
            local avY = by + 8
            av:SetPos(avX, avY)
            av:SetSize(avSize, avSize)
            av:PaintManual()
            
            draw.RoundedBox(4, avX - 1, avY - 1, avSize + 2, avSize + 2, Color(roleCol.r, roleCol.g, roleCol.b, 100 * fadeAlpha))
        end

        surface.SetDrawColor(255, 255, 255, 255 * fadeAlpha)
        draw.SimpleText(nick, "RoleESP_Name", bx + 48, by + 8, Color(255, 255, 255, 255 * fadeAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        surface.SetDrawColor(roleCol.r, roleCol.g, roleCol.b, 255 * fadeAlpha)
        draw.SimpleText("• " .. role, "RoleESP_Role", bx + 48, by + 28, ColorAlpha(roleCol, 255 * fadeAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if dist < 500 then
            local distText = math.Round(dist * 0.01905) .. "m"
            draw.SimpleText(distText, "DermaDefault", x, by - 5, Color(255, 255, 255, 150 * fadeAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end
end)

timer.Create("AdminNametags_UpdateRoles", 1, 0, function()
    if ENABLED and LocalPlayer():IsSuperAdmin() then
        RequestRoleUpdate()
    end
end)

hook.Add("PlayerDisconnected", "AdminNametags_CleanupAvatar", function(ply)
    local sid = ply:SteamID64()
    if sid and avatars[sid] and IsValid(avatars[sid]) then
        avatars[sid]:Remove()
        avatars[sid] = nil
    end
end)

net.Receive("AdminNametags_Toggle", function()
    ENABLED = net.ReadBool()
    local col = ENABLED and Color(50, 255, 50) or Color(255, 50, 50)
    
    chat.AddText(
        Color(255, 200, 0), "[Admin ESP] ",
        Color(255, 255, 255), "ESP: ",
        col, ENABLED and "WŁĄCZONE" or "WYŁĄCZONE"
    )
    
    surface.PlaySound(ENABLED and "ui/buttonclick.wav" or "ui/buttonclickrelease.wav")
    
    if ENABLED then
        RequestRoleUpdate()
    else
        roleData = {}
    end
end)

net.Receive("AdminNametags_SendRoles", function()
    roleData = net.ReadTable()
end)