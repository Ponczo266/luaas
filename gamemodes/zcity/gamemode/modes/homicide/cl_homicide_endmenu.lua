local MODE = MODE
local endMenu = nil

if IsValid(endMenu) then
	endMenu:Remove()
	endMenu = nil
end

local RoundData = {}
local CreateEndMenu

local function S(n)
	return math.Round(n * math.Clamp(ScrH() / 1080, 0.7, 1.3))
end

local C = {
	bg = Color(18, 18, 24, 200),
	header = Color(12, 12, 18, 230),
	row1 = Color(28, 28, 36, 180),
	row2 = Color(24, 24, 32, 180),
	hover = Color(38, 38, 48, 200),
	border = Color(50, 50, 60, 150),
	accent = Color(70, 130, 220),
	red = Color(220, 60, 60),
	green = Color(60, 200, 100),
	purple = Color(160, 80, 220),
	gold = Color(255, 200, 50),
	white = Color(240, 240, 245),
	gray = Color(120, 125, 140),
	dark = Color(65, 68, 80, 180),
	alive = Color(70, 200, 110),
	dead = Color(200, 70, 70),
	down = Color(220, 170, 50),
	cyan = Color(60, 190, 220),
}

surface.CreateFont("HMEnd_Title", {font = "Roboto", size = S(32), weight = 700, antialias = true})
surface.CreateFont("HMEnd_Sub", {font = "Roboto", size = S(14), weight = 400, antialias = true})
surface.CreateFont("HMEnd_Name", {font = "Roboto", size = S(17), weight = 600, antialias = true})
surface.CreateFont("HMEnd_Role", {font = "Roboto", size = S(13), weight = 600, antialias = true})
surface.CreateFont("HMEnd_Stats", {font = "Roboto", size = S(12), weight = 400, antialias = true})
surface.CreateFont("HMEnd_Status", {font = "Roboto", size = S(12), weight = 500, antialias = true})
surface.CreateFont("HMEnd_Btn", {font = "Roboto", size = S(13), weight = 500, antialias = true})

hook.Add("OnScreenSizeChanged", "HMEnd_RefreshFonts", function()
	surface.CreateFont("HMEnd_Title", {font = "Roboto", size = S(32), weight = 700, antialias = true})
	surface.CreateFont("HMEnd_Sub", {font = "Roboto", size = S(14), weight = 400, antialias = true})
	surface.CreateFont("HMEnd_Name", {font = "Roboto", size = S(17), weight = 600, antialias = true})
	surface.CreateFont("HMEnd_Role", {font = "Roboto", size = S(13), weight = 600, antialias = true})
	surface.CreateFont("HMEnd_Stats", {font = "Roboto", size = S(12), weight = 400, antialias = true})
	surface.CreateFont("HMEnd_Status", {font = "Roboto", size = S(12), weight = 500, antialias = true})
	surface.CreateFont("HMEnd_Btn", {font = "Roboto", size = S(13), weight = 500, antialias = true})
end)

local GAMEMODE_TITLES = {
	homicide = "Homicide",
	homicide_fear = "Homicide Fear",
	coop = "Co-op",
	criresp = "Crime Response",
	defense = "Defense",
	dm = "Deathmatch",
	gwars = "Gang Wars",
	hl2dm = "HL2 Deathmatch",
	pathowogen = "Pathowogen",
	riot = "Riot",
	scrappers = "Scrappers",
	scugarena = "Scug Arena",
	sfd = "Stick Fight",
	smo = "SMO",
	tdm = "Team Deathmatch",
	tdm_cstrike = "TDM Counter-Strike",
	eventhandler = "Event",
}

local GAMEMODE_COLORS = {
	homicide = Color(220, 60, 60),
	homicide_fear = Color(180, 40, 40),
	coop = Color(60, 200, 100),
	criresp = Color(60, 120, 220),
	defense = Color(220, 140, 40),
	dm = Color(220, 60, 60),
	gwars = Color(160, 80, 220),
	hl2dm = Color(220, 140, 40),
	pathowogen = Color(100, 220, 60),
	riot = Color(220, 60, 60),
	scrappers = Color(180, 120, 60),
	scugarena = Color(60, 190, 220),
	sfd = Color(220, 200, 50),
	smo = Color(70, 130, 220),
	tdm = Color(220, 100, 40),
	tdm_cstrike = Color(200, 180, 60),
	eventhandler = Color(160, 80, 220),
}

local function GetGamemodeKey()
	if MODE and MODE.FolderName then return MODE.FolderName end
	if MODE and MODE.Name then
		for k, v in pairs(GAMEMODE_TITLES) do
			if v == MODE.Name then return k end
		end
	end
	return "homicide"
end

local function GetRoleInfo(p)
	if p.isTraitor then
		return "ZDRAJCA", C.red
	elseif p.isGunner or p.isDetective then
		return "DETEKTYW", C.purple
	elseif p.isPolice then
		return "POLICJA", C.cyan
	elseif p.team and p.team == "red" then
		return "CZERWONI", C.red
	elseif p.team and p.team == "blue" then
		return "NIEBIESCY", C.accent
	elseif p.team and p.team == "gang1" then
		return "GANG 1", C.red
	elseif p.team and p.team == "gang2" then
		return "GANG 2", C.accent
	elseif p.isFurry then
		return "FURRY", C.green
	elseif p.isInfected then
		return "ZARAZONY", C.green
	else
		return "NIEWINNY", C.green
	end
end

local function BuildPlayerList()
	local players = {}
	for _, ply in player.Iterator() do
		if not IsValid(ply) then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end

		local p = {
			ent = ply,
			name = ply:Nick() or "?",
			nick = ply:Nick() or "?",
			steamid = ply:IsBot() and "BOT" or (ply:SteamID64() or ""),
			isTraitor = ply.isTraitor or false,
			isGunner = ply.isGunner or false,
			isDetective = ply.isDetective or false,
			isPolice = ply.isPolice or false,
			isFurry = ply.isFurry or false,
			isInfected = ply.isInfected or false,
			alive = ply:Alive(),
			incapacitated = ply.organism and ply.organism.otrub or false,
			stats = {
				kills = ply:Frags() or 0,
				deaths = ply:Deaths() or 0,
			},
		}

		if ply.GetPlayerName then
			local rpname = ply:GetPlayerName()
			if rpname and rpname ~= "" then
				p.name = rpname
			end
		end

		if ply:Team() == 1 or ply:Team() == TEAM_TERRORISTS then
			p.team = "red"
		elseif ply:Team() == 2 or ply:Team() == TEAM_COUNTERTERRORISTS then
			p.team = "blue"
		end

		table.insert(players, p)
	end
	return players
end

net.Receive("hmcd_roundend_extended", function()
	RoundData = {
		win_reason = net.ReadString(),
		winning_team = net.ReadString(),
		duration = net.ReadFloat(),
		round_type = net.ReadString(),
		traitors = {},
		players = {},
	}

	local traitor_count = net.ReadUInt(8)
	for i = 1, traitor_count do
		RoundData.traitors[i] = {
			ent = net.ReadEntity(),
			name = net.ReadString(),
			nick = net.ReadString(),
			isMainTraitor = net.ReadBool(),
			alive = net.ReadBool(),
			subrole = net.ReadString(),
			color = net.ReadVector(),
		}
	end

	local player_count = net.ReadUInt(8)
	for i = 1, player_count do
		RoundData.players[i] = {
			ent = net.ReadEntity(),
			name = net.ReadString(),
			nick = net.ReadString(),
			steamid = net.ReadString(),
			isTraitor = net.ReadBool(),
			isGunner = net.ReadBool(),
			alive = net.ReadBool(),
			incapacitated = net.ReadBool(),
			color = net.ReadVector(),
			subrole = net.ReadString(),
			profession = net.ReadString(),
			stats = {
				kills = net.ReadUInt(8),
				deaths = net.ReadUInt(8),
				damage_dealt = net.ReadUInt(16),
				headshots = net.ReadUInt(8),
				accuracy = net.ReadUInt(7),
				longest_kill = net.ReadUInt(10),
				innocents_killed = net.ReadUInt(8),
				traitors_killed = net.ReadUInt(8),
				first_blood = net.ReadBool(),
				knife_kills = net.ReadUInt(8),
				gun_kills = net.ReadUInt(8),
				explosive_kills = net.ReadUInt(8),
			},
		}
	end

	timer.Simple(0, function()
		CreateEndMenu(RoundData)
	end)
end)

net.Receive("hmcd_roundend", function()
	local traitors, gunners = {}, {}

	for key = 1, net.ReadUInt(MODE.TraitorExpectedAmtBits) do
		local t = net.ReadEntity()
		traitors[key] = t
		if IsValid(t) then t.isTraitor = true end
	end

	for key = 1, net.ReadUInt(MODE.TraitorExpectedAmtBits) do
		local g = net.ReadEntity()
		gunners[key] = g
		if IsValid(g) then g.isGunner = true end
	end

	timer.Simple(2.5, function()
		lply.isPolice = false
		lply.isTraitor = false
		lply.isGunner = false
		lply.MainTraitor = false
		lply.SubRole = nil
		lply.Profession = nil
	end)

	local data = {
		win_reason = "homicide",
		winning_team = "nieznany",
		traitors = {},
		players = BuildPlayerList(),
	}

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply.isTraitor then
			table.insert(data.traitors, {
				ent = ply,
				name = ply:Nick(),
				nick = ply:Nick(),
				isMainTraitor = (ply == traitors[1]),
				alive = ply:Alive(),
			})
		end
	end

	CreateEndMenu(data)
end)

net.Receive("zcity_roundend", function()
	local winnerTeam = net.ReadString()
	local reason = net.ReadString()

	timer.Simple(0.5, function()
		local data = {
			win_reason = reason or "",
			winning_team = winnerTeam or "",
			traitors = {},
			players = BuildPlayerList(),
		}

		CreateEndMenu(data)
	end)
end)

CreateEndMenu = function(data)
	if IsValid(endMenu) then
		endMenu:Remove()
		endMenu = nil
	end

	if not data or not data.players or #data.players == 0 then return end

	surface.PlaySound("ambient/alarms/warningbell1.wav")

	local w = math.min(S(700), ScrW() * 0.9)
	local h = math.min(S(800), ScrH() * 0.85)
	local headerH = S(80)
	local rowH = S(64)
	local pad = S(12)
	local avSize = S(46)

	local gmKey = GetGamemodeKey()
	local gmTitle = GAMEMODE_TITLES[gmKey] or gmKey
	local gmColor = GAMEMODE_COLORS[gmKey] or C.accent

	local titleText = "Koniec rundy"
	local hasTraitors = data.traitors and #data.traitors > 0

	if hasTraitors then
		local traitorName = data.traitors[1].nick or data.traitors[1].name or "Nieznany"
		if #data.traitors > 1 then
			titleText = traitorName .. " i " .. (#data.traitors - 1) .. " innych bylo zdrajcami"
		else
			titleText = traitorName .. " byl zdrajca"
		end
	elseif data.winning_team and data.winning_team ~= "" and data.winning_team ~= "nieznany" then
		titleText = "Wygrywa: " .. data.winning_team
	end

	endMenu = vgui.Create("DFrame")
	endMenu:SetSize(w, h)
	endMenu:Center()
	endMenu:SetTitle("")
	endMenu:SetDraggable(true)
	endMenu:ShowCloseButton(false)
	endMenu:MakePopup()
	endMenu:SetKeyboardInputEnabled(false)

	endMenu.Paint = function(self, pw, ph)
		draw.RoundedBox(S(12), 0, 0, pw, ph, C.bg)
		draw.RoundedBoxEx(S(12), 0, 0, pw, headerH, C.header, true, true, false, false)

		draw.SimpleText(titleText, "HMEnd_Title", pw / 2, headerH / 2 - S(12), C.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		surface.SetFont("HMEnd_Sub")
		local gmTagW = surface.GetTextSize(gmTitle) + S(16)
		local gmTagH = S(20)
		local gmTagX = pw / 2 - gmTagW / 2
		local gmTagY = headerH / 2 + S(8)
		draw.RoundedBox(S(4), gmTagX, gmTagY, gmTagW, gmTagH, ColorAlpha(gmColor, 40))
		draw.SimpleText(gmTitle, "HMEnd_Sub", pw / 2, gmTagY + gmTagH / 2, gmColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		surface.SetDrawColor(C.border)
		surface.DrawLine(0, headerH, pw, headerH)
		surface.DrawOutlinedRect(0, 0, pw, ph, 1)
	end

	endMenu.OnClose = function()
		endMenu = nil
	end

	local btnW = S(90)
	local btnH = S(32)
	local closeBtn = vgui.Create("DButton", endMenu)
	closeBtn:SetPos(w - btnW - pad, (headerH - btnH) / 2)
	closeBtn:SetSize(btnW, btnH)
	closeBtn:SetText("")
	closeBtn:SetCursor("hand")
	closeBtn.Paint = function(self, bw, bh)
		local col = self:IsHovered() and C.red or C.dark
		draw.RoundedBox(S(6), 0, 0, bw, bh, col)
		draw.SimpleText("Zamknij", "HMEnd_Btn", bw / 2, bh / 2, C.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function()
		if IsValid(endMenu) then endMenu:Close() end
	end

	local list = vgui.Create("DScrollPanel", endMenu)
	list:SetPos(pad, headerH + pad)
	list:SetSize(w - pad * 2, h - headerH - pad * 2)

	local sbar = list:GetVBar()
	sbar:SetWide(S(5))
	sbar:SetHideButtons(true)
	sbar.Paint = function(self, sw, sh)
		draw.RoundedBox(S(3), 0, 0, sw, sh, C.dark)
	end
	sbar.btnGrip.Paint = function(self, sw, sh)
		draw.RoundedBox(S(3), 0, 0, sw, sh, C.accent)
	end

	for i, p in ipairs(data.players) do
		local isBot = (p.steamid == "BOT" or p.steamid == "")
		local roleText, roleCol = GetRoleInfo(p)

		local row = vgui.Create("DButton", list)
		row:Dock(TOP)
		row:DockMargin(0, i == 1 and 0 or S(4), 0, 0)
		row:SetTall(rowH)
		row:SetText("")
		row:SetCursor("hand")

		row.Paint = function(self, rw, rh)
			local bg = self:IsHovered() and C.hover or (i % 2 == 0 and C.row2 or C.row1)
			draw.RoundedBox(S(8), 0, 0, rw, rh, bg)

			draw.RoundedBox(S(4), 0, S(8), S(5), rh - S(16), roleCol)

			local avX = S(16)
			local avY = (rh - avSize) / 2
			draw.RoundedBox(S(6), avX, avY, avSize, avSize, C.dark)
			if isBot then
				draw.SimpleText("BOT", "HMEnd_Role", avX + avSize / 2, avY + avSize / 2, C.gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			local textX = avX + avSize + S(14)

			local nameCol = p.alive and C.white or C.gray
			draw.SimpleText(p.nick, "HMEnd_Name", textX, rh / 2 - S(10), nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local tagW = S(70)
			local tagH2 = S(20)
			local tagX = textX
			local tagY = rh / 2 + S(4)
			draw.RoundedBox(S(4), tagX, tagY, tagW, tagH2, ColorAlpha(roleCol, 40))
			draw.SimpleText(roleText, "HMEnd_Role", tagX + tagW / 2, tagY + tagH2 / 2, roleCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			if p.subrole and p.subrole ~= "" then
				local srTagX = tagX + tagW + S(6)
				local srTagW = S(60)
				draw.RoundedBox(S(4), srTagX, tagY, srTagW, tagH2, ColorAlpha(C.accent, 40))
				draw.SimpleText(p.subrole, "HMEnd_Role", srTagX + srTagW / 2, tagY + tagH2 / 2, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			local statusText, statusCol
			if p.alive then
				if p.incapacitated then
					statusText = "Nieprzytomny"
					statusCol = C.down
				else
					statusText = "Zywy"
					statusCol = C.alive
				end
			else
				statusText = "Martwy"
				statusCol = C.dead
			end

			local rightX = rw - S(16)
			local dotSize = S(8)
			surface.SetFont("HMEnd_Status")
			local stW = surface.GetTextSize(statusText)
			local totalW = dotSize + S(4) + stW
			local stStartX = rightX - totalW

			draw.RoundedBox(dotSize / 2, stStartX, rh / 2 - dotSize / 2, dotSize, dotSize, statusCol)
			draw.SimpleText(statusText, "HMEnd_Status", stStartX + dotSize + S(4), rh / 2, statusCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		row.DoClick = function()
			if isBot then
				chat.AddText(Color(255, 80, 80), "To jest bot.")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. p.steamid)
		end

		if not isBot then
			local av = vgui.Create("AvatarImage", row)
			av:SetPos(S(16), (rowH - avSize) / 2)
			av:SetSize(avSize, avSize)
			av:SetMouseInputEnabled(false)
			av:SetKeyboardInputEnabled(false)
			if IsValid(p.ent) then
				av:SetPlayer(p.ent, 184)
			elseif p.steamid and p.steamid ~= "" and p.steamid ~= "BOT" then
				av:SetSteamID(util.SteamIDFrom64(p.steamid), 184)
			end
		end

		list:AddItem(row)
	end
end

MODE.CreateEndMenu = function(traitor)
	local data = {
		win_reason = "nieznany",
		winning_team = "nieznany",
		traitors = {},
		players = BuildPlayerList(),
	}

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply.isTraitor then
			table.insert(data.traitors, {
				ent = ply,
				name = ply:Nick(),
				nick = ply:Nick(),
				isMainTraitor = IsValid(traitor) and ply == traitor,
				alive = ply:Alive(),
			})
		end
	end

	CreateEndMenu(data)
end

MODE.CloseEndMenu = function()
	if IsValid(endMenu) then
		endMenu:Close()
		endMenu = nil
	end
end

concommand.Add("hmcd_test_endmenu", function()
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply.isTraitor = true

		local test = {
			win_reason = "test",
			winning_team = "zdrajcy",
			traitors = {{
				ent = ply,
				name = ply:Nick(),
				nick = ply:Nick(),
				isMainTraitor = true,
				alive = true,
			}},
			players = {},
		}

		for _, p in player.Iterator() do
			if not IsValid(p) then continue end
			table.insert(test.players, {
				ent = p,
				name = p:Nick(),
				nick = p:Nick(),
				steamid = p:IsBot() and "BOT" or p:SteamID64(),
				isTraitor = p == ply,
				isGunner = false,
				isDetective = false,
				isPolice = false,
				alive = p:Alive(),
				incapacitated = false,
				stats = {
					kills = math.random(0, 8),
					deaths = math.random(0, 3),
				},
			})
		end

		CreateEndMenu(test)
	end
end)