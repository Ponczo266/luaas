if SERVER then AddCSLuaFile() end

hg = hg or {}
hg.PointShop = hg.PointShop or {}

local PLUGIN = hg.PointShop
PLUGIN.Items = PLUGIN.Items or {}

-- + vecCamPos (opcjonalne, do podglądu twarzy)
function PLUGIN:CreateItem(uid, strName, strModel, strBodyGroups, iSkin, vecPos, intPrice, bIsDPoints, tData, fCallback, fov, vecCamPos)
    PLUGIN.Items[uid] = {
        ID = uid,
        NAME = strName,
        MDL = strModel or "models/dav0r/hoverball.mdl",
        BODYGROUP = strBodyGroups or "00000",
        SKIN = iSkin or 0,
        VPos = vecPos or Vector(0,0,0),
        CAM_POS = vecCamPos, -- do cl_pointshop.lua
        PRICE = intPrice,
        ISDONATE = bIsDPoints or false,
        DATA = tData or {},
        CALLBACK = fCallback or nil,
        FOV = fov or 15
    }
end

if CLIENT then
    local callbacks = {} -- FIFO

    -- Odpowiedzi na requesty (tu odpalamy callback)
    net.Receive("hg_pointshop_net", function()
        local vars = net.ReadTable()
        LocalPlayer().PS_MyItensens = vars

        if callbacks[1] then
            callbacks[1](vars)
            table.remove(callbacks, 1)
        end
    end)

    -- Push z serwera (timer/spawn) - NIE odpalamy callbacków
    net.Receive("hg_pointshop_vars", function()
        LocalPlayer().PS_MyItensens = net.ReadTable()
    end)

    function PLUGIN:SendNET(strFunc, tVars, callback)
        net.Start("hg_pointshop_net")
            net.WriteString(strFunc)
            net.WriteTable(tVars or {})
        net.SendToServer()

        if callback then
            callbacks[#callbacks + 1] = callback
        end
    end

    local plyMeta = FindMetaTable("Player")

    function plyMeta:PS_HasItem(uid)
        local vars = LocalPlayer().PS_MyItensens
        if not vars or not vars.items then return false end
        return vars.items[uid] or false
    end

    net.Receive("hg_pointshop_send_notificate", function()
        local txt = net.ReadString()
        sound.PlayURL("https://www.myinstants.com/media/sounds/short-notice.mp3", "mono", function()
            Derma_Message(txt, "Result", "OK")
        end)
    end)
end

hook.Add("Think", "ZPointshopLoaded", function()
    hook.Run("ZPointshopLoaded")
    hook.Remove("Think", "ZPointshopLoaded")
end)