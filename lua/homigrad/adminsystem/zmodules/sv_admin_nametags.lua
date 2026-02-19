util.AddNetworkString("AdminNametags_Toggle")
util.AddNetworkString("AdminNametags_RequestRoles")
util.AddNetworkString("AdminNametags_SendRoles")
AddCSLuaFile("cl_admin_nametags.lua")

local enabled = {}

COMMANDS = COMMANDS or {}

local function Toggle(ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("Tylko Super Admini mogą używać ESP.")
        return
    end

    local sid = ply:SteamID64()
    enabled[sid] = not enabled[sid]

    net.Start("AdminNametags_Toggle")
        net.WriteBool(enabled[sid])
    net.Send(ply)
end

COMMANDS.adminesp = {function(ply, args)
    Toggle(ply)
end, 0}

net.Receive("AdminNametags_RequestRoles", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    
    local data = {}
    for _, p in ipairs(player.GetAll()) do
        data[p:EntIndex()] = {
            isTraitor = p.isTraitor or false,
            isGunner = p.isGunner or false,
            isPolice = p.isPolice or false,
            MainTraitor = p.MainTraitor or false,
            SubRole = p.SubRole or "",
            Profession = p.Profession or ""
        }
    end
    
    net.Start("AdminNametags_SendRoles")
        net.WriteTable(data)
    net.Send(ply)
end)

hook.Add("PlayerDisconnected", "AdminNametags_Cleanup", function(ply)
    if IsValid(ply) then enabled[ply:SteamID64()] = nil end
end)

concommand.Add("adminesp", function(ply)
    if not IsValid(ply) then return end
    Toggle(ply)
end)