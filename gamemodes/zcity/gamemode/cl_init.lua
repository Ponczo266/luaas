zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

function CurrentRound()
	return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
--0 = players can join, 1 = round is active, 2 = endround
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect,prevspect,viewmode = nil,nil,1
local hullscale = Vector(0,0,0)
net.Receive("ZB_SpectatePlayer", function(len)
	spect = net.ReadEntity()
	prevspect = net.ReadEntity()
	viewmode = net.ReadInt(4)

	timer.Simple(0.1,function()
		LocalPlayer():SetHull(-hullscale,hullscale)
		LocalPlayer():SetHullDuck(-hullscale,hullscale)

		if viewmode == 3 then
			LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
		end
	end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime",function()
	local time = net.ReadFloat()
	local time2 = net.ReadFloat()
	local time3 = net.ReadFloat()

	zb.ROUND_TIME = time
	zb.ROUND_START = time2
	zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local blursettings = {}
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	if(hg_potatopc:GetBool())then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		local x, y = panel:LocalToScreen(0, 0)
		if blursettings and blursettings[1] == amount and blursettings[2] == passes then
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			return
		end
		blursettings = {amount, passes}
		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload

hook.Add("HUDPaint","FUCKINGSAMENAMEUSEDINHOOKFUCKME",function()
    if LocalPlayer():Alive() then return end
	local spect = LocalPlayer():GetNWEntity("spect")
	if not IsValid(spect) then return end
	if viewmode == 3 then return end
	
	surface.SetFont("HomigradFont")
	surface.SetTextColor(255, 255, 255, 255)
	local txt = "Spectating player: "..spect:Name()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
	surface.DrawText(txt)
	local txt = "In-game name: "..spect:GetPlayerName()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7 + h)
	surface.DrawText(txt)
end)

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
	if not lply:Alive() then
		if lply:KeyDown(IN_ATTACK) then
			if not keydownattack then
				keydownattack = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK,32)
				net.SendToServer()
			end
		else
			keydownattack = false
		end

		if lply:KeyDown(IN_ATTACK2) then
			if not keydownattack2 then
				keydownattack2 = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK2,32)
				net.SendToServer()
			end
		else
			keydownattack2 = false
		end

		if lply:KeyDown(IN_RELOAD) then
			if not keydownreload then
				keydownreload = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_RELOAD,32)
				net.SendToServer()
			end
		else
			keydownreload = false
		end

		local spect = lply:GetNWEntity("spect",spect)
		if not IsValid(spect) then return end

		local viewmode = lply:GetNWInt("viewmode",viewmode)
		
		if viewmode == 3 then
			if lply:GetMoveType()!=MOVETYPE_NOCLIP then
				lply:SetMoveType(MOVETYPE_NOCLIP)
			end
			lply:SetObserverMode(OBS_MODE_ROAMING)
			return
		else
			lply:SetPos(spect:GetPos())
		end
		
		local ent = hg.GetCurrentCharacter(spect)
		if not IsValid(ent) then return end
		
		local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
		local bon = ent:GetBoneMatrix(headBone)
		
		if not bon then 
			local eyePos = ent:EyePos()
			if eyePos and eyePos ~= vector_origin then
				pos = eyePos
				ang = ent:EyeAngles()
			else
				pos = ent:GetPos() + Vector(0, 0, 64)
				ang = ent:GetAngles()
			end
		else
			pos, ang = bon:GetTranslation(), bon:GetAngles()
		end

		local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()
		
		local tr = {}
		tr.start = pos
		tr.endpos = pos + eyeAng:Forward() * -120
		tr.filter = {ent, lply, spect}
		tr.mins = Vector(-4, -4, -4)
		tr.maxs = Vector(4, 4, 4)
		tr = util.TraceHull(tr)

		if viewmode == 2 then
			pos = tr.HitPos + eyeAng:Forward() * 8
			ang = eyeAng
		elseif viewmode == 1 then
			if ent ~= spect and IsValid(ent) then
				local eyeAtt = ent:GetAttachment(ent:LookupAttachment("eyes"))
				if eyeAtt then
					ang = eyeAtt.Ang
				else
					ang = spect:EyeAngles()
				end
			else
				ang = spect:EyeAngles()
			end
			pos = pos + spect:EyeAngles():Forward() * 8
		else
			pos = eyePos
			ang = eyeAng
		end
		
		ang[3] = 0
		
		local view
		local hg_newspectate = GetConVar("hg_newspectate")
		if hg_newspectate and hg_newspectate:GetBool() then
			if not lply.spectLastPos then
				lply.spectLastPos = pos
				lply.spectLastAng = ang
			end
			
			local lerpFactor = FrameTime() * 10
			lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
			lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

			view = {
				origin = lply.spectLastPos,
				angles = lply.spectLastAng,
				fov = fov,
			}
		else
			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		end

		return view
	else
		lply.spectLastPos = nil
		lply.spectLastAng = nil
		lply:SetObserverMode(OBS_MODE_NONE)
	end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
	if zb.fade > 0 then
		zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)

		surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end)

zb.ROUND_STATE = 0
net.Receive("RoundInfo", function()
	local rnd = net.ReadString()
	
	hook.Run("RoundInfoCalled", rnd)

	if zb.CROUND ~= rnd then
		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end
	end

	zb.CROUND = rnd

	zb.ROUND_STATE = net.ReadInt(4)
	
	if zb.ROUND_STATE == 0 then
		zb.fade = 7
	end

	if zb.CROUND ~= "" then
		if CurrentRound() then
			if zb.ROUND_STATE == 3 then
				if CurrentRound().EndRound then
					CurrentRound():EndRound()
				end
			elseif zb.ROUND_STATE == 1 then
				if CurrentRound().RoundStart then
					CurrentRound():RoundStart()
				end
			end
		end
	end
end)

if IsValid(scoreBoardMenu) then
	scoreBoardMenu:Remove()
	scoreBoardMenu = nil
end

hook.Add("Player Disconnected","retrymenu",function(data)
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
end)

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "change every text font to selected because ui customization is cool")
local font = function()
    local usefont = "Bahnschrift"
    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end
    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", {
    font = font(),
    size = ScreenScale(6),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_ScrappersMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMediumLarge", {
    font = font(),
    size = 35,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceLarge", {
    font = font(),
    size = ScreenScale(20),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceHumongous", {
    font = font(),
    size = 200,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_ScoreTitle", {
    font = font(),
    size = 28,
    weight = 700,
    antialias = true
})

surface.CreateFont("ZB_ScoreSection", {
    font = font(),
    size = 18,
    weight = 600,
    antialias = true
})

surface.CreateFont("ZB_ScorePlayer", {
    font = font(),
    size = 15,
    weight = 500,
    antialias = true
})

surface.CreateFont("ZB_ScoreSmall", {
    font = font(),
    size = 12,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_ScoreButton", {
    font = font(),
    size = 13,
    weight = 600,
    antialias = true
})

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
	hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}
	local json = util.TableToJSON(hg.playerInfo)
	file.Write("zcity_muted.txt", json)
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")
		if json then
			hg.playerInfo = util.JSONToTable(json)
		end
	end
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
	local ply = Player(data.userid)
	if IsValid(ply) and ply.SetMuted and hg.playerInfo and hg.playerInfo[data.networkid] then
		ply:SetMuted(hg.playerInfo[data.networkid][1])
		ply:SetVoiceVolumeScale(hg.playerInfo[data.networkid][2])
	end
end)

hook.Add("InitPostEntity", "furryhuy", function()
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")
		if json then
			hg.playerInfo = util.JSONToTable(json)
		end
		if hg.playerInfo then
			for i, ply in player.Iterator() do
				if not istable(hg.playerInfo[ply:SteamID()]) then
					local muted = hg.playerInfo[ply:SteamID()]
					hg.playerInfo[ply:SteamID()] = {}
					hg.playerInfo[ply:SteamID()][1] = muted
					hg.playerInfo[ply:SteamID()][2] = 1
				end
				if hg.playerInfo[ply:SteamID()] then
					ply:SetMuted(hg.playerInfo[ply:SteamID()][1])
					ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
				end
			end	
		end
	end
end)

-- ============================================================
-- KOLORY DLA SCOREBOARDU
-- ============================================================
local COLORS = {
	bg_main = Color(17, 24, 39, 250),
	bg_darker = Color(10, 15, 25, 255),
	bg_card = Color(31, 41, 55, 255),
	bg_card_hover = Color(55, 65, 81, 255),
	bg_spectator = Color(55, 65, 81, 255),
	bg_spectator_hover = Color(75, 85, 99, 255),
	
	border_red = Color(220, 38, 38, 255),
	border_red_dark = Color(153, 27, 27, 255),
	border_gray = Color(75, 85, 99, 255),
	
	text_white = Color(255, 255, 255, 255),
	text_gray = Color(156, 163, 175, 255),
	text_dark = Color(100, 100, 100, 255),
	text_red = Color(248, 113, 113, 255),
	
	ping_green = Color(74, 222, 128, 255),
	ping_yellow = Color(250, 204, 21, 255),
	ping_red = Color(248, 113, 113, 255),
	
	btn_red = Color(220, 38, 38, 255),
	btn_red_hover = Color(185, 28, 28, 255),
	btn_green = Color(34, 197, 94, 255),
	btn_green_hover = Color(22, 163, 74, 255),
	btn_gray = Color(75, 85, 99, 255),
	btn_gray_hover = Color(107, 114, 128, 255),
	
	discord_bg = Color(88, 101, 242, 255),
	discord_hover = Color(71, 82, 196, 255),
	
	scrollbar_bg = Color(31, 41, 55, 255),
	scrollbar_grip = Color(75, 85, 99, 255),
}

hg.muteall = hg.muteall or false
hg.mutespect = hg.mutespect or false

-- DISCORD LINK - ZMIEN NA SWOJ
local DISCORD_LINK = "https://dsc.gg/mgp-zcitypl"

-- IKONA DISCORD Z URL
local discordIconMat = nil
local discordIconLoaded = false

local function LoadDiscordIcon()
	if discordIconLoaded then return end
	discordIconLoaded = true
	
	http.Fetch("https://cdn.discordapp.com/attachments/911948152381251605/1472977383752601887/discordlogo.png?ex=69948896&is=69933716&hm=d05e07926444d539d20b1553eeaef8235e7407a1fbdbc8e4f3b004b7d371db9f&",
		function(body, size, headers, code)
			if code == 200 then
				file.Write("zcity_discord_icon.png", body)
				discordIconMat = Material("../data/zcity_discord_icon.png", "smooth mips")
				print("[ZCity] Ikona Discord zaladowana pomyslnie!")
			end
		end,
		function(err)
			print("[ZCity] Nie udalo sie pobrac ikony Discord: " .. err)
		end
	)
end

LoadDiscordIcon()

-- Globalne menu do zamykania
local activeMenu = nil
local activeVolumePanel = nil

local function CloseActiveMenu()
	if IsValid(activeMenu) then
		activeMenu:Remove()
		activeMenu = nil
	end
	if IsValid(activeVolumePanel) then
		activeVolumePanel:Remove()
		activeVolumePanel = nil
	end
end

local function GetPingColor(ping)
	if ping < 50 then
		return COLORS.ping_green
	elseif ping < 100 then
		return COLORS.ping_yellow
	else
		return COLORS.ping_red
	end
end

local function CountPlayers()
	local players = 0
	local spectators = 0
	local disappearance = lply:GetNetVar("disappearance", nil)
	
	for _, ply in player.Iterator() do
		if disappearance and ply != lply then continue end
		
		if ply:Team() == TEAM_SPECTATOR then
			if not CurrentRound() or CurrentRound().name ~= "fear" or ply:Alive() then
				spectators = spectators + 1
			end
		else
			if not CurrentRound() or CurrentRound().name ~= "fear" or ply:Alive() then
				players = players + 1
			end
		end
	end
	return players, spectators
end

hook.Add("Player Getup", "nomorespect", function(ply)
	if not hg.mutespect then return end
	ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
	if not hg.mutespect then return end
	ply:SetVoiceVolumeScale(0)
end)

hook.Add("Player_Death", "fixSpectatorVoiceEffect", function(ply)
	if eightbit and eightbit.EnableEffect and ply.UserID then
		eightbit.EnableEffect(ply:UserID(), 0)
	end
end)

-- ============================================================
-- GLOWNA FUNKCJA SCOREBOARDU
-- ============================================================
function GM:ScoreboardShow()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
	
	CloseActiveMenu()
	
	local sizeX, sizeY = math.min(ScrW() * 0.8, 1100), math.min(ScrH() * 0.8, 700)
	local posX, posY = ScrW() / 2 - sizeX / 2, ScrH() / 2 - sizeY / 2

	scoreBoardMenu = vgui.Create("DFrame")
	scoreBoardMenu:SetPos(posX, posY)
	scoreBoardMenu:SetSize(sizeX, sizeY)
	scoreBoardMenu:SetTitle("")
	scoreBoardMenu:SetDraggable(true)
	scoreBoardMenu:MakePopup()
	scoreBoardMenu:SetKeyboardInputEnabled(false)
	scoreBoardMenu:ShowCloseButton(false)
	
	local playerCount, spectatorCount = CountPlayers()
	local ServerName = GetHostName() or "ZCity Server"
	
	scoreBoardMenu.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, COLORS.bg_main)
		
		for i = 0, 80 do
			local alpha = 100 - (i * 1.25)
			surface.SetDrawColor(0, 0, 0, alpha)
			surface.DrawRect(0, i, w, 1)
		end
		
		surface.SetDrawColor(COLORS.border_red)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end
	
	-- ============ NAGLOWEK ============
	local headerHeight = 110
	local header = vgui.Create("DPanel", scoreBoardMenu)
	header:SetPos(0, 0)
	header:SetSize(sizeX, headerHeight)
	header.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.border_red_dark)
		surface.DrawRect(0, h - 1, w, 1)
	end
	
	-- Nazwa serwera
	local titleLabel = vgui.Create("DLabel", header)
	titleLabel:SetPos(0, 8)
	titleLabel:SetSize(sizeX, 28)
	titleLabel:SetText(ServerName)
	titleLabel:SetFont("ZB_ScoreTitle")
	titleLabel:SetTextColor(COLORS.text_white)
	titleLabel:SetContentAlignment(5)
	
	-- SV Tick pod hostname
	local tickLabel = vgui.Create("DLabel", header)
	tickLabel:SetPos(0, 34)
	tickLabel:SetSize(sizeX, 18)
	tickLabel:SetFont("ZB_ScoreSmall")
	tickLabel:SetTextColor(COLORS.text_gray)
	tickLabel:SetContentAlignment(5)
	tickLabel.Think = function(self)
		local tick = math.Round(1 / engine.ServerFrameTime())
		self:SetText("SV Tick: " .. tick)
	end
	
	-- Przycisk Discord z ikona z URL
	local discordBtn = vgui.Create("DButton", header)
	discordBtn:SetPos(sizeX/2 - 125, 58)
	discordBtn:SetSize(250, 40)
	discordBtn:SetText("")
	discordBtn.Paint = function(self, w, h)
		local bgCol = self:IsHovered() and COLORS.discord_hover or COLORS.discord_bg
		draw.RoundedBox(6, 0, 0, w, h, bgCol)
		
		-- Ikona Discord z URL (jesli zaladowana)
		if discordIconMat and not discordIconMat:IsError() then
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(discordIconMat)
			surface.DrawTexturedRect(14, 8, 24, 24)
		else
			-- Fallback - prosty ksztalt jesli ikona nie zaladowana
			draw.RoundedBox(4, 14, 10, 20, 20, Color(255, 255, 255, 255))
		end
		
		-- Tekst
		surface.SetFont("ZB_ScoreButton")
		surface.SetTextColor(255, 255, 255, 255)
		local txt = "DOLACZ NA DISCORD"
		local tw, th = surface.GetTextSize(txt)
		surface.SetTextPos(50, h/2 - th/2)
		surface.DrawText(txt)
	end
	discordBtn.DoClick = function()
		gui.OpenURL(DISCORD_LINK)
	end
	
	-- ============ KONTENER GLOWNY ============
	local contentY = headerHeight + 5
	local contentHeight = sizeY - headerHeight - 65
	local columnWidth = (sizeX - 50) / 2
	local columnGap = 20
	
	-- ============ KOLUMNA GRACZY ============
	local playersPanel = vgui.Create("DPanel", scoreBoardMenu)
	playersPanel:SetPos(15, contentY)
	playersPanel:SetSize(columnWidth, contentHeight)
	playersPanel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLORS.bg_darker)
		surface.SetDrawColor(COLORS.border_gray)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	
	-- Naglowek graczy
	local playersHeaderPanel = vgui.Create("DPanel", playersPanel)
	playersHeaderPanel:SetPos(0, 0)
	playersHeaderPanel:SetSize(columnWidth, 45)
	playersHeaderPanel.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.border_red_dark)
		surface.DrawRect(0, h - 1, w, 1)
	end
	
	local playersTitle = vgui.Create("DLabel", playersHeaderPanel)
	playersTitle:SetPos(0, 8)
	playersTitle:SetSize(columnWidth, 25)
	playersTitle:SetText("Gracze (" .. playerCount .. ")")
	playersTitle:SetFont("ZB_ScoreSection")
	playersTitle:SetTextColor(COLORS.text_white)
	playersTitle:SetContentAlignment(5)
	
	-- Przycisk Dolacz dla obserwatorow
	local joinBtnOffset = 50
	if LocalPlayer():Team() == TEAM_SPECTATOR then
		local joinPlayersBtn = vgui.Create("DButton", playersPanel)
		joinPlayersBtn:SetPos(columnWidth/2 - 55, 50)
		joinPlayersBtn:SetSize(110, 28)
		joinPlayersBtn:SetText("Dolacz")
		joinPlayersBtn:SetFont("ZB_ScoreButton")
		joinPlayersBtn:SetTextColor(COLORS.text_white)
		joinPlayersBtn.Paint = function(self, w, h)
			local col = self:IsHovered() and COLORS.btn_green_hover or COLORS.btn_green
			draw.RoundedBox(4, 0, 0, w, h, col)
		end
		joinPlayersBtn.DoClick = function()
			net.Start("ZB_SpecMode")
			net.WriteBool(false)
			net.SendToServer()
			if IsValid(scoreBoardMenu) then
				scoreBoardMenu:Remove()
				scoreBoardMenu = nil
			end
		end
		joinBtnOffset = 85
	end
	
	-- Lista graczy
	local playersScroll = vgui.Create("DScrollPanel", playersPanel)
	playersScroll:SetPos(8, joinBtnOffset)
	playersScroll:SetSize(columnWidth - 16, contentHeight - joinBtnOffset - 8)
	
	local sbar = playersScroll:GetVBar()
	sbar:SetWide(6)
	sbar.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, COLORS.scrollbar_bg) end
	sbar.btnUp.Paint = function() end
	sbar.btnDown.Paint = function() end
	sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, COLORS.scrollbar_grip) end
	
	local disappearance = lply:GetNetVar("disappearance", nil)
	
	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if CurrentRound() and CurrentRound().name == "fear" and !ply:Alive() then continue end
		if disappearance and ply != lply then continue end
		
		local card = vgui.Create("DButton", playersScroll)
		card:SetSize(columnWidth - 28, 52)
		card:Dock(TOP)
		card:DockMargin(0, 4, 0, 0)
		card:SetText("")
		
		card.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			local bgCol = self:IsHovered() and COLORS.bg_card_hover or COLORS.bg_card
			draw.RoundedBox(4, 0, 0, w, h, bgCol)
			
			-- Nazwa gracza
			surface.SetFont("ZB_ScorePlayer")
			surface.SetTextColor(COLORS.text_white)
			surface.SetTextPos(52, 10)
			surface.DrawText(ply:Name() or "???")
			
			-- Ping
			local ping = ply:Ping()
			local pingCol = GetPingColor(ping)
			surface.SetFont("ZB_ScoreSmall")
			surface.SetTextColor(pingCol)
			local pingText = ping .. " ms"
			local tw = surface.GetTextSize(pingText)
			surface.SetTextPos(w - tw - 45, 18)
			surface.DrawText(pingText)
		end
		
		-- Avatar
		local avatar = vgui.Create("AvatarImage", card)
		avatar:SetPos(8, 8)
		avatar:SetSize(36, 36)
		avatar:SetPlayer(ply, 64)
		avatar:SetMouseInputEnabled(false)
		
		-- Przycisk glosnosci
		local volBtn = vgui.Create("DButton", card)
		volBtn:SetPos(card:GetWide() - 36, 14)
		volBtn:SetSize(24, 24)
		volBtn:SetText("")
		volBtn.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			local col = self:IsHovered() and Color(90, 90, 90, 255) or Color(60, 70, 80, 255)
			draw.RoundedBox(4, 0, 0, w, h, col)
			
			if ply:IsMuted() then
				surface.SetDrawColor(COLORS.ping_red)
				surface.DrawLine(5, 5, 19, 19)
				surface.DrawLine(6, 5, 20, 19)
			else
				surface.SetDrawColor(COLORS.text_white)
			end
			surface.DrawRect(6, 10, 4, 5)
			surface.DrawRect(10, 8, 5, 9)
		end
		
		volBtn.DoClick = function()
			CloseActiveMenu()
			
			if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then 
				addToPlayerInfo(ply, false, 1) 
			end
			
			local volPanel = vgui.Create("DPanel")
			volPanel:SetSize(180, 75)
			local bx, by = volBtn:LocalToScreen(0, 0)
			volPanel:SetPos(bx - 145, by + 28)
			volPanel:MakePopup()
			volPanel:SetKeyboardInputEnabled(false)
			volPanel.Paint = function(self, w, h)
				draw.RoundedBox(6, 0, 0, w, h, COLORS.bg_card)
				surface.SetDrawColor(COLORS.border_gray)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end
			
			activeVolumePanel = volPanel
			
			local muteCheck = vgui.Create("DCheckBoxLabel", volPanel)
			muteCheck:SetPos(10, 8)
			muteCheck:SetText("Wycisz gracza")
			muteCheck:SetTextColor(COLORS.text_white)
			muteCheck:SetChecked(ply:IsMuted())
			muteCheck.OnChange = function(self, val)
				if hg.muteall or hg.mutespect then return end
				ply:SetMuted(val)
				addToPlayerInfo(ply, val, hg.playerInfo[ply:SteamID()][2])
			end
			
			local volLabel = vgui.Create("DLabel", volPanel)
			volLabel:SetPos(10, 30)
			volLabel:SetSize(160, 14)
			volLabel:SetText("Glosnosc: " .. math.Round((hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) * 100) .. "%")
			volLabel:SetTextColor(COLORS.text_white)
			volLabel:SetFont("ZB_ScoreSmall")
			
			local volSlider = vgui.Create("DSlider", volPanel)
			volSlider:SetPos(10, 48)
			volSlider:SetSize(160, 18)
			volSlider:SetLockY(0.5)
			volSlider:SetTrapInside(true)
			volSlider:SetSlideX(hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1)
			volSlider.Paint = function(self, w, h)
				draw.RoundedBox(3, 0, 5, w, 8, Color(40, 50, 60, 255))
				draw.RoundedBox(3, 0, 5, w * self:GetSlideX(), 8, COLORS.border_red)
			end
			volSlider.Knob.Paint = function(self, w, h)
				draw.RoundedBox(5, 0, 0, 10, 10, COLORS.text_white)
			end
			volSlider.Knob:SetSize(10, 10)
			volSlider.OnValueChanged = function(self, x, y)
				if not IsValid(ply) then return end
				if hg.muteall or (hg.mutespect and !ply:Alive()) then return end
				hg.playerInfo[ply:SteamID()][2] = x
				ply:SetVoiceVolumeScale(x)
				addToPlayerInfo(ply, ply:IsMuted(), x)
				if IsValid(volLabel) then
					volLabel:SetText("Glosnosc: " .. math.Round(x * 100) .. "%")
				end
			end
		end
		
		card.DoClick = function()
			CloseActiveMenu()
			if ply:IsBot() then 
				chat.AddText(Color(255, 100, 100), "To jest bot!") 
				return 
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end
		
		card.DoRightClick = function()
			CloseActiveMenu()
			
			local menu = DermaMenu()
			menu:AddOption("Profil Steam", function()
				if not ply:IsBot() then
					gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
				end
			end):SetIcon("icon16/user.png")
			
			menu:AddOption("Kopiuj SteamID", function()
				SetClipboardText(ply:SteamID())
				chat.AddText(Color(100, 255, 100), "Skopiowano SteamID: " .. ply:SteamID())
			end):SetIcon("icon16/page_copy.png")
			
			menu:AddOption("Konto", function()
				if zb.Experience and zb.Experience.AccountMenu then
					zb.Experience.AccountMenu(ply)
				end
			end):SetIcon("icon16/report.png")
			
			menu:Open()
			activeMenu = menu
		end
	end
	
	-- ============ KOLUMNA OBSERWATOROW ============
	local spectatorsPanel = vgui.Create("DPanel", scoreBoardMenu)
	spectatorsPanel:SetPos(15 + columnWidth + columnGap, contentY)
	spectatorsPanel:SetSize(columnWidth, contentHeight)
	spectatorsPanel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLORS.bg_darker)
		surface.SetDrawColor(COLORS.border_gray)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	
	-- Naglowek obserwatorow
	local specHeaderPanel = vgui.Create("DPanel", spectatorsPanel)
	specHeaderPanel:SetPos(0, 0)
	specHeaderPanel:SetSize(columnWidth, 45)
	specHeaderPanel.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.border_gray)
		surface.DrawRect(0, h - 1, w, 1)
	end
	
	local specTitle = vgui.Create("DLabel", specHeaderPanel)
	specTitle:SetPos(0, 8)
	specTitle:SetSize(columnWidth, 25)
	specTitle:SetText("Obserwatorzy (" .. spectatorCount .. ")")
	specTitle:SetFont("ZB_ScoreSection")
	specTitle:SetTextColor(COLORS.text_white)
	specTitle:SetContentAlignment(5)
	
	-- Przycisk Dolacz dla graczy
	local specJoinBtnOffset = 50
	if LocalPlayer():Team() ~= TEAM_SPECTATOR then
		local joinSpecBtn = vgui.Create("DButton", spectatorsPanel)
		joinSpecBtn:SetPos(columnWidth/2 - 55, 50)
		joinSpecBtn:SetSize(110, 28)
		joinSpecBtn:SetText("Dolacz")
		joinSpecBtn:SetFont("ZB_ScoreButton")
		joinSpecBtn:SetTextColor(COLORS.text_white)
		joinSpecBtn.Paint = function(self, w, h)
			local col = self:IsHovered() and COLORS.btn_gray_hover or COLORS.btn_gray
			draw.RoundedBox(4, 0, 0, w, h, col)
		end
		joinSpecBtn.DoClick = function()
			net.Start("ZB_SpecMode")
			net.WriteBool(true)
			net.SendToServer()
			if IsValid(scoreBoardMenu) then
				scoreBoardMenu:Remove()
				scoreBoardMenu = nil
			end
		end
		specJoinBtnOffset = 85
	end
	
	-- Lista obserwatorow
	local specScroll = vgui.Create("DScrollPanel", spectatorsPanel)
	specScroll:SetPos(8, specJoinBtnOffset)
	specScroll:SetSize(columnWidth - 16, contentHeight - specJoinBtnOffset - 8)
	
	local sbar2 = specScroll:GetVBar()
	sbar2:SetWide(6)
	sbar2.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, COLORS.scrollbar_bg) end
	sbar2.btnUp.Paint = function() end
	sbar2.btnDown.Paint = function() end
	sbar2.btnGrip.Paint = function(self, w, h) draw.RoundedBox(3, 0, 0, w, h, COLORS.scrollbar_grip) end
	
	for i, ply in player.Iterator() do
		if ply:Team() ~= TEAM_SPECTATOR then continue end
		if CurrentRound() and CurrentRound().name == "fear" and !ply:Alive() then continue end
		if disappearance and ply != lply then continue end
		
		local card = vgui.Create("DButton", specScroll)
		card:SetSize(columnWidth - 28, 52)
		card:Dock(TOP)
		card:DockMargin(0, 4, 0, 0)
		card:SetText("")
		
		card.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			local bgCol = self:IsHovered() and COLORS.bg_spectator_hover or COLORS.bg_spectator
			draw.RoundedBox(4, 0, 0, w, h, bgCol)
			
			surface.SetFont("ZB_ScorePlayer")
			surface.SetTextColor(COLORS.text_gray)
			surface.SetTextPos(52, 10)
			surface.DrawText(ply:Name() or "???")
			
			local ping = ply:Ping()
			local pingCol = GetPingColor(ping)
			surface.SetFont("ZB_ScoreSmall")
			surface.SetTextColor(pingCol)
			local pingText = ping .. " ms"
			local tw = surface.GetTextSize(pingText)
			surface.SetTextPos(w - tw - 45, 18)
			surface.DrawText(pingText)
		end
		
		-- Avatar
		local avatar = vgui.Create("AvatarImage", card)
		avatar:SetPos(8, 8)
		avatar:SetSize(36, 36)
		avatar:SetPlayer(ply, 64)
		avatar:SetMouseInputEnabled(false)
		
		-- Przycisk glosnosci
		local volBtn = vgui.Create("DButton", card)
		volBtn:SetPos(card:GetWide() - 36, 14)
		volBtn:SetSize(24, 24)
		volBtn:SetText("")
		volBtn.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			local col = self:IsHovered() and Color(100, 100, 100, 255) or Color(70, 80, 90, 255)
			draw.RoundedBox(4, 0, 0, w, h, col)
			
			if ply:IsMuted() then
				surface.SetDrawColor(COLORS.ping_red)
				surface.DrawLine(5, 5, 19, 19)
				surface.DrawLine(6, 5, 20, 19)
			else
				surface.SetDrawColor(COLORS.text_white)
			end
			surface.DrawRect(6, 10, 4, 5)
			surface.DrawRect(10, 8, 5, 9)
		end
		
		volBtn.DoClick = function()
			CloseActiveMenu()
			
			if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then 
				addToPlayerInfo(ply, false, 1) 
			end
			
			local volPanel = vgui.Create("DPanel")
			volPanel:SetSize(180, 75)
			local bx, by = volBtn:LocalToScreen(0, 0)
			volPanel:SetPos(bx - 145, by + 28)
			volPanel:MakePopup()
			volPanel:SetKeyboardInputEnabled(false)
			volPanel.Paint = function(self, w, h)
				draw.RoundedBox(6, 0, 0, w, h, COLORS.bg_card)
				surface.SetDrawColor(COLORS.border_gray)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end
			
			activeVolumePanel = volPanel
			
			local muteCheck = vgui.Create("DCheckBoxLabel", volPanel)
			muteCheck:SetPos(10, 8)
			muteCheck:SetText("Wycisz gracza")
			muteCheck:SetTextColor(COLORS.text_white)
			muteCheck:SetChecked(ply:IsMuted())
			muteCheck.OnChange = function(self, val)
				if hg.muteall or hg.mutespect then return end
				ply:SetMuted(val)
				addToPlayerInfo(ply, val, hg.playerInfo[ply:SteamID()][2])
			end
			
			local volLabel = vgui.Create("DLabel", volPanel)
			volLabel:SetPos(10, 30)
			volLabel:SetSize(160, 14)
			volLabel:SetText("Glosnosc: " .. math.Round((hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) * 100) .. "%")
			volLabel:SetTextColor(COLORS.text_white)
			volLabel:SetFont("ZB_ScoreSmall")
			
			local volSlider = vgui.Create("DSlider", volPanel)
			volSlider:SetPos(10, 48)
			volSlider:SetSize(160, 18)
			volSlider:SetLockY(0.5)
			volSlider:SetTrapInside(true)
			volSlider:SetSlideX(hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1)
			volSlider.Paint = function(self, w, h)
				draw.RoundedBox(3, 0, 5, w, 8, Color(40, 50, 60, 255))
				draw.RoundedBox(3, 0, 5, w * self:GetSlideX(), 8, COLORS.border_red)
			end
			volSlider.Knob.Paint = function(self, w, h)
				draw.RoundedBox(5, 0, 0, 10, 10, COLORS.text_white)
			end
			volSlider.Knob:SetSize(10, 10)
			volSlider.OnValueChanged = function(self, x, y)
				if not IsValid(ply) then return end
				if hg.muteall or (hg.mutespect and !ply:Alive()) then return end
				hg.playerInfo[ply:SteamID()][2] = x
				ply:SetVoiceVolumeScale(x)
				addToPlayerInfo(ply, ply:IsMuted(), x)
				if IsValid(volLabel) then
					volLabel:SetText("Glosnosc: " .. math.Round(x * 100) .. "%")
				end
			end
		end
		
		card.DoClick = function()
			CloseActiveMenu()
			if ply:IsBot() then 
				chat.AddText(Color(255, 100, 100), "To jest bot!") 
				return 
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end
		
		card.DoRightClick = function()
			CloseActiveMenu()
			
			local menu = DermaMenu()
			menu:AddOption("Profil Steam", function()
				if not ply:IsBot() then
					gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
				end
			end):SetIcon("icon16/user.png")
			
			menu:AddOption("Kopiuj SteamID", function()
				SetClipboardText(ply:SteamID())
				chat.AddText(Color(100, 255, 100), "Skopiowano SteamID: " .. ply:SteamID())
			end):SetIcon("icon16/page_copy.png")
			
			menu:AddOption("Konto", function()
				if zb.Experience and zb.Experience.AccountMenu then
					zb.Experience.AccountMenu(ply)
				end
			end):SetIcon("icon16/report.png")
			
			menu:Open()
			activeMenu = menu
		end
	end
	
	-- ============ STOPKA ============
	local footerY = sizeY - 55
	local footer = vgui.Create("DPanel", scoreBoardMenu)
	footer:SetPos(0, footerY)
	footer:SetSize(sizeX, 55)
	footer.Paint = function(self, w, h)
		surface.SetDrawColor(COLORS.border_red_dark)
		surface.DrawRect(0, 0, w, 1)
	end
	
	local btnW, btnH = 150, 30
	local gap = 15
	local totalW = btnW * 2 + gap
	local startX = sizeX/2 - totalW/2
	
	-- Wycisz wszystkich
	local muteAllBtn = vgui.Create("DButton", footer)
	muteAllBtn:SetPos(startX, 12)
	muteAllBtn:SetSize(btnW, btnH)
	muteAllBtn:SetText("Wycisz wszystkich")
	muteAllBtn:SetFont("ZB_ScoreButton")
	muteAllBtn:SetTextColor(COLORS.text_white)
	muteAllBtn.Paint = function(self, w, h)
		local col
		if hg.muteall then
			col = self:IsHovered() and COLORS.btn_green_hover or COLORS.btn_green
		else
			col = self:IsHovered() and COLORS.btn_red_hover or COLORS.btn_red
		end
		draw.RoundedBox(4, 0, 0, w, h, col)
	end
	muteAllBtn.DoClick = function()
		hg.muteall = not hg.muteall
		for _, ply in player.Iterator() do
			if hg.muteall then
				ply:SetVoiceVolumeScale(0)
			else
				ply:SetVoiceVolumeScale((!hg.mutespect or ply:Alive()) and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
			end
		end
	end
	
	-- Wycisz obserwatorow
	local muteSpecBtn = vgui.Create("DButton", footer)
	muteSpecBtn:SetPos(startX + btnW + gap, 12)
	muteSpecBtn:SetSize(btnW, btnH)
	muteSpecBtn:SetText("Wycisz obserwatorow")
	muteSpecBtn:SetFont("ZB_ScoreButton")
	muteSpecBtn:SetTextColor(COLORS.text_white)
	muteSpecBtn.Paint = function(self, w, h)
		local col
		if hg.mutespect then
			col = self:IsHovered() and COLORS.btn_green_hover or COLORS.btn_green
		else
			col = self:IsHovered() and COLORS.btn_gray_hover or COLORS.btn_gray
		end
		draw.RoundedBox(4, 0, 0, w, h, col)
	end
	muteSpecBtn.DoClick = function()
		hg.mutespect = not hg.mutespect
		for _, ply in player.Iterator() do
			if ply:Alive() then continue end
			if hg.mutespect then
				ply:SetVoiceVolumeScale(0)
			else
				ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
			end
		end
	end
	
	-- Wersja
	local versionLabel = vgui.Create("DLabel", footer)
	versionLabel:SetPos(0, 42)
	versionLabel:SetSize(sizeX, 12)
	versionLabel:SetText("ZC Version: " .. (hg.Version or "1.0"))
	versionLabel:SetFont("ZB_ScoreSmall")
	versionLabel:SetTextColor(COLORS.text_dark)
	versionLabel:SetContentAlignment(5)
	
	return true
end

function GM:ScoreboardHide()
	CloseActiveMenu()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
end

local AdminShowVoiceChat = CreateClientConVar("zb_admin_show_voicechat","0",false,false,"Shows voicechat panles",0,1)
hook.Add("PlayerStartVoice", "asd", function(ply)
	if !IsValid(ply) then return end
	if LocalPlayer():IsAdmin() and AdminShowVoiceChat:GetBool() then return end

	local other_alive = (ply:Alive() and LocalPlayer() != ply) or (ply.organism and (ply.organism.otrub or (ply.organism.brain and ply.organism.brain > 0.05)))

	return other_alive or nil
end)

if CLIENT then
	net.Receive("PunishLightningEffect", function()
		local target = net.ReadEntity()
		if not IsValid(target) then return end
		local dlight = DynamicLight(target:EntIndex())
		if dlight then
			dlight.pos = target:GetPos()
			dlight.r = 126
			dlight.g = 139
			dlight.b = 212
			dlight.brightness = 1
			dlight.Decay = 1000
			dlight.Size = 500
			dlight.DieTime = CurTime() + 1
		end
	end)
end

local lightningMaterial = Material("sprites/lgtning")

net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
	if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-20,20))
    end
    hook.Add( "PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend( false )
    end )
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint( name, delay )
	return false
end

local snakeGameOpen = false

concommand.Add("zb_snake", function()
    if snakeGameOpen then
        print("[Snake Game] Gra juz uruchomiona!")
        return
    end

    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)  
    snakeGameOpen = true  

    local gridSize = 20
    local gridWidth = 19  
    local gridHeight = 19  
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)

    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = {
        {x = 10, y = 10},
    }
	
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = {
                x = math.random(0, gridWidth - 1), 
                y = math.random(0, gridHeight - 1)
            }
            validPosition = true

            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false
                    break
                end
            end

            if validPosition then
                food = newFood
            end
        end
    end

    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

    local function moveSnake()
        if not gameRunning then return end

        local head = table.Copy(snake[1])

        if snakeDirection == "UP" then
            head.y = head.y - 1
        elseif snakeDirection == "DOWN" then
            head.y = head.y + 1
        elseif snakeDirection == "LEFT" then
            head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then
            head.x = head.x + 1
        end

        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then
            gameRunning = false
        end

        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameRunning = false
            end
        end

        table.insert(snake, 1, head)

        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()
        else
            table.remove(snake)
        end
    end

    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()
    end

    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)

        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Nacisnij R aby zrestartowac", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText("Wynik: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    function frame:OnKeyCodePressed(key)
        if key == KEY_W and snakeDirection ~= "DOWN" then
            snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then
            snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then
            snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then
            snakeDirection = "RIGHT"
        elseif key == KEY_R then
            resetGame()
        end
    end

    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then
            moveSnake()
        end
        snakePanel:InvalidateLayout(true)
    end)

    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false
        print("[Snake Game] Gra zamknieta.")
    end

    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
	if ply == LocalPlayer() then
		system.FlashWindow()
	end
end)