local MODE = MODE
MODE.name = "hmcd"

--\\Local Functions
local function screen_scale_2(num)
	return ScreenScale(num) / (ScrW() / ScrH())
end
--//

MODE.TypeSounds = {
	["standard"] = {"snd_jack_hmcd_psycho.mp3","snd_jack_hmcd_shining.mp3"},
	["soe"] = "snd_jack_hmcd_disaster.mp3",
	["gunfreezone"] = "snd_jack_hmcd_panic.mp3" ,
	["suicidelunatic"] = "zbattle/jihadmode.mp3",
	["wildwest"] = "snd_jack_hmcd_wildwest.mp3",
	["supermario"] = "snd_jack_hmcd_psycho.mp3"
}
local fade = 0
net.Receive("HMCD_RoundStart",function()
	for i, ply in player.Iterator() do
		ply.isTraitor = false
		ply.isGunner = false
	end

	--\\
	lply.isTraitor = net.ReadBool()
	lply.isGunner = net.ReadBool()
	MODE.Type = net.ReadString()
	local screen_time_is_default = net.ReadBool()
	lply.SubRole = net.ReadString()
	lply.MainTraitor = net.ReadBool()
	MODE.TraitorWord = net.ReadString()
	MODE.TraitorWordSecond = net.ReadString()
	MODE.TraitorExpectedAmt = net.ReadUInt(MODE.TraitorExpectedAmtBits)
	StartTime = CurTime()
	MODE.TraitorsLocal = {}

	if(lply.isTraitor and screen_time_is_default)then
		if(MODE.TraitorExpectedAmt == 1)then
			chat.AddText("Jesteś sam w swojej misji.")
		else
			if(MODE.TraitorExpectedAmt == 2)then
				chat.AddText("Masz 1 wspólnika.")
			else
				chat.AddText("Jest jeszcze " .. MODE.TraitorExpectedAmt - 1 .. " zdrajca(ów) oprócz ciebie.")
			end

			chat.AddText("Tajne hasła zdrajcy to: \"" .. MODE.TraitorWord .. "\" i \"" .. MODE.TraitorWordSecond .. "\".")
		end

		if(lply.MainTraitor)then
			if(MODE.TraitorExpectedAmt > 1)then
				chat.AddText("Imiona zdrajców (tylko ty, jako główny zdrajca, możesz je zobaczyć):")
			end

			for key = 1, MODE.TraitorExpectedAmt do
				local traitor_info = {net.ReadColor(false), net.ReadString()}

				if(MODE.TraitorExpectedAmt > 1)then
					MODE.TraitorsLocal[#MODE.TraitorsLocal + 1] = traitor_info

					chat.AddText(traitor_info[1], "\t" .. traitor_info[2])
				end
			end
		end
	end

	lply.Profession = net.ReadString()
	--//

	if(MODE.RoleChooseRoundTypes[MODE.Type] and !screen_time_is_default)then
		MODE.DynamicFadeScreenEndTime = CurTime() + MODE.RoleChooseRoundStartTime
	else
		MODE.DynamicFadeScreenEndTime = CurTime() + MODE.DefaultRoundStartTime
	end

	MODE.RoleEndedChosingState = screen_time_is_default

	if(screen_time_is_default)then
		if istable(MODE.TypeSounds[MODE.Type]) then
			surface.PlaySound(table.Random(MODE.TypeSounds[MODE.Type]))
		else
			surface.PlaySound(MODE.TypeSounds[MODE.Type])
		end
	end

	fade = 0
end)

MODE.TypeNames = {
	["standard"] = "Standardowy",
	["soe"] = "Stan Wyjątkowy",
	["gunfreezone"] = "Strefa Bez Broni",
	["suicidelunatic"] = "Szaleniec Samobójca",
	["wildwest"] = "Dziki Zachód",
	["supermario"] = "Super Mario"
}

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "change every text font to selected because ui customization is cool")
local font = function()
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZB_HomicideSmall", {
	font = font(),
	size = ScreenScale(15),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideMedium", {
	font = font(),
	size = ScreenScale(15),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideMediumLarge", {
	font = font(),
	size = ScreenScale(25),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideLarge", {
	font = font(),
	size = ScreenScale(30),
	weight = 400,
	antialias = true
})

surface.CreateFont("ZB_HomicideHumongous", {
	font = font(),
	size = 255,
	weight = 400,
	antialias = true
})

MODE.TypeObjectives = {}
MODE.TypeObjectives.soe = {
	traitor = {
		objective = "Masz przy sobie przedmioty, trucizny, materiały wybuchowe i broń ukrytą w kieszeniach. Zamorduj wszystkich.",
		name = "Zdrajcą",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Jesteś niewinnym z bronią myśliwską. Znajdź i zneutralizuj zdrajcę, zanim będzie za późno.",
		name = "Niewinnym",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "Jesteś niewinnym, polegaj tylko na sobie, ale trzymaj się w grupie, żeby utrudnić zdrajcy zadanie.",
		name = "Niewinnym",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.standard = {
	traitor = {
		objective = "Masz przy sobie przedmioty, trucizny, materiały wybuchowe i broń ukrytą w kieszeniach. Zamorduj wszystkich.",
		name = "Mordercą",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Jesteś przechodniem z ukrytą bronią palną. Postawiłeś sobie za zadanie pomóc policji szybciej znaleźć przestępcę.",
		name = "Przechodniem",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "Jesteś świadkiem morderstwa, choć to nie tobie się przydarzyło, lepiej bądź ostrożny.",
		name = "Przechodniem",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.wildwest = {
	traitor = {
		objective = "To miasto nie jest wystarczająco duże dla nas wszystkich.",
		name = "Zabójcą",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Jesteś szeryfem tego miasta. Musisz znaleźć i zabić tego bezprawnego drania.",
		name = "Szeryfem",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "Musimy tu wymierzyć sprawiedliwość, jakiś bezprawny drań morduje ludzi.",
		name = "Kowbojem",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},
}

MODE.TypeObjectives.gunfreezone = {
	traitor = {
		objective = "Masz przy sobie przedmioty, trucizny, materiały wybuchowe i broń ukrytą w kieszeniach. Zamorduj wszystkich.",
		name = "Mordercą",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Jesteś świadkiem morderstwa, choć to nie tobie się przydarzyło, lepiej bądź ostrożny.",
		name = "Przechodniem",
		color1 = Color(0,120,190)
	},

	innocent = {
		objective = "Jesteś świadkiem morderstwa, choć to nie tobie się przydarzyło, lepiej bądź ostrożny.",
		name = "Przechodniem",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.suicidelunatic = {
	traitor = {
		objective = "Mój bracie, insha'Allah, nie zawiedź go.",
		name = "Szahidem",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Szaleniec oszalał, teraz musisz przeżyć.",
		name = "Niewinnym",
		color1 = Color(0,120,190)
	},

	innocent = {
		objective = "Szaleniec oszalał, teraz musisz przeżyć.",
		name = "Niewinnym",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.supermario = {
	traitor = {
		objective = "Jesteś złym Mario! Skacz i pokonaj wszystkich.",
		name = "Zdrajcą Mario",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Jesteś bohaterem Mario! Użyj swojej zdolności skakania, żeby powstrzymać zdrajcę.",
		name = "Bohaterem Mario",
		color1 = Color(158,0,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "Jesteś niewinnym Mario, przeżyj i unikaj pułapek zdrajcy!",
		name = "Niewinnym Mario",
		color1 = Color(0,120,190)
	},
}

function MODE:RenderScreenspaceEffects()
	fade_end_time = MODE.DynamicFadeScreenEndTime or 0
	local time_diff = fade_end_time - CurTime()

	if(time_diff > 0)then
		zb.RemoveFade()

		local fade = math.min(time_diff / MODE.FadeScreenTime, 1)

		surface.SetDrawColor(0, 0, 0, 255 * fade)
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end

local handicap = {
	[1] = "Masz upośledzenie: twoja prawa noga jest złamana.",
	[2] = "Masz upośledzenie: cierpisz na ciężką otyłość.",
	[3] = "Masz upośledzenie: cierpisz na hemofilię.",
	[4] = "Masz upośledzenie: jesteś fizycznie niesprawny."
}

function MODE:HUDPaint()
	if not MODE.Type or not MODE.TypeObjectives[MODE.Type] then return end
	if lply:Team() == TEAM_SPECTATOR then return end
	if StartTime + 12 < CurTime() then return end
	
	fade = Lerp(FrameTime()*1, fade, math.Clamp(StartTime + 5 - CurTime(),-2,2))

	draw.SimpleText("Homicide | " .. (MODE.TypeNames[MODE.Type] or "Nieznany"), "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Rolename = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.name ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.name ) or MODE.TypeObjectives[MODE.Type].innocent.name
	local ColorRole = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color1 ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color1 ) or MODE.TypeObjectives[MODE.Type].innocent.color1
	ColorRole.a = 255 * fade

	local color_role_innocent = MODE.TypeObjectives[MODE.Type].innocent.color1
	color_role_innocent.a = 255 * fade

	local color_white_faded = Color(255, 255, 255, 255 * fade)
	color_white_faded.a = 255 * fade

	draw.SimpleText("Jesteś "..Rolename , "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local cur_y = sh * 0.5

	if(lply.SubRole and lply.SubRole != "")then
		cur_y = cur_y + ScreenScale(20)

		draw.SimpleText("" .. ((MODE.SubRoles[lply.SubRole] and MODE.SubRoles[lply.SubRole].Name or lply.SubRole) or lply.SubRole), "ZB_HomicideMediumLarge", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if(!lply.MainTraitor and lply.isTraitor)then
		cur_y = cur_y + ScreenScale(20)

		draw.SimpleText("Asystent", "ZB_HomicideMedium", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if(lply.isTraitor)then
		cur_y = cur_y + ScreenScale(20)

		if(lply.MainTraitor)then
			MODE.TraitorsLocal = MODE.TraitorsLocal or {}

			if(#MODE.TraitorsLocal > 1)then
				draw.SimpleText("Lista zdrajców:", "ZB_HomicideMedium", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				for _, traitor_info in ipairs(MODE.TraitorsLocal) do
					local traitor_color = Color(traitor_info[1].r, traitor_info[1].g, traitor_info[1].b, 255 * fade)
					cur_y = cur_y + ScreenScale(15)

					draw.SimpleText(traitor_info[2], "ZB_HomicideMedium", sw * 0.5, cur_y, traitor_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end
		else
			draw.SimpleText("Tajne hasła zdrajcy:", "ZB_HomicideMedium", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			cur_y = cur_y + ScreenScale(15)

			draw.SimpleText("\"" .. MODE.TraitorWord .. "\"", "ZB_HomicideMedium", sw * 0.5, cur_y, color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			cur_y = cur_y + ScreenScale(15)

			draw.SimpleText("\"" .. MODE.TraitorWordSecond .. "\"", "ZB_HomicideMedium", sw * 0.5, cur_y, color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	if(lply.Profession and lply.Profession != "")then
		cur_y = cur_y + ScreenScale(20)

		draw.SimpleText("Zawód: " .. ((MODE.Professions[lply.Profession] and MODE.Professions[lply.Profession].Name or lply.Profession) or lply.Profession), "ZB_HomicideMedium", sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	if(handicap[lply:GetLocalVar("karma_sickness", 0)])then
		cur_y = cur_y + ScreenScale(20)

		draw.SimpleText(handicap[lply:GetLocalVar("karma_sickness", 0)], "ZB_HomicideMedium", sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local Objective = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.objective ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.objective ) or MODE.TypeObjectives[MODE.Type].innocent.objective

	if(lply.SubRole and lply.SubRole != "")then
		if(MODE.SubRoles[lply.SubRole] and MODE.SubRoles[lply.SubRole].Objective)then
			Objective = MODE.SubRoles[lply.SubRole].Objective
		end
	end

	if(!lply.MainTraitor and lply.isTraitor)then
		Objective = "Nie masz żadnego wyposażenia. Pomóż innym zdrajcom wygrać."
	end

	if(!MODE.RoleEndedChosingState)then
		Objective = "Runda się rozpoczyna..."
	end

	local ColorObj = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color2 ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color2 ) or MODE.TypeObjectives[MODE.Type].innocent.color2 or Color(255,255,255)
	ColorObj.a = 255 * fade
	draw.SimpleText( Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("GDZIEŚ W PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- ============================================
-- NOWE MENU KOŃCA RUNDY
-- ============================================

local hmcdEndMenu = nil

local EC = {
    bg      = Color(25, 25, 32, 250),
    row     = Color(35, 35, 44, 255),
    row2    = Color(30, 30, 38, 255),
    hover   = Color(45, 45, 56, 255),
    border  = Color(55, 55, 65, 100),
    red     = Color(180, 50, 50, 255),
    blue    = Color(50, 120, 180, 255),
    purple  = Color(130, 60, 180, 255),
    alive   = Color(80, 185, 105, 255),
    dead    = Color(180, 60, 60, 255),
    down    = Color(200, 155, 45, 255),
    white   = Color(230, 230, 235, 255),
    gray    = Color(130, 135, 150, 255),
    dark    = Color(70, 72, 85, 255),
}

local es = math.Clamp(ScrH() / 1080, 0.6, 1.3)
surface.CreateFont("HMEnd_Big",   { font = "Roboto", size = math.Round(26 * es), weight = 700, antialias = true })
surface.CreateFont("HMEnd_Med",   { font = "Roboto", size = math.Round(14 * es), weight = 500, antialias = true })
surface.CreateFont("HMEnd_Small", { font = "Roboto", size = math.Round(12 * es), weight = 400, antialias = true })
surface.CreateFont("HMEnd_Kills", { font = "Roboto", size = math.Round(16 * es), weight = 700, antialias = true })

hook.Add("OnScreenSizeChanged", "HMEnd_Fonts", function()
    es = math.Clamp(ScrH() / 1080, 0.6, 1.3)
    surface.CreateFont("HMEnd_Big",   { font = "Roboto", size = math.Round(26 * es), weight = 700, antialias = true })
    surface.CreateFont("HMEnd_Med",   { font = "Roboto", size = math.Round(14 * es), weight = 500, antialias = true })
    surface.CreateFont("HMEnd_Small", { font = "Roboto", size = math.Round(12 * es), weight = 400, antialias = true })
    surface.CreateFont("HMEnd_Kills", { font = "Roboto", size = math.Round(16 * es), weight = 700, antialias = true })
end)

if IsValid(hmcdEndMenu) then
    hmcdEndMenu:Remove()
    hmcdEndMenu = nil
end

local CreateEndMenu

CreateEndMenu = function(traitor)
    if IsValid(hmcdEndMenu) then hmcdEndMenu:Remove() end

    local players = {}
    local traitorName = IsValid(traitor) and traitor:GetPlayerName() or "Nieznany"
    local traitorNick = IsValid(traitor) and traitor:Nick() or "Nieznany"

    for _, ply in player.Iterator() do
        if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then continue end

        players[#players + 1] = {
            name    = ply:GetPlayerName() or "?",
            nick    = ply:Nick() or "?",
            traitor = ply.isTraitor or false,
            gunner  = ply.isGunner or false,
            main    = IsValid(traitor) and ply == traitor,
            alive   = ply:Alive(),
            down    = ply.organism and ply.organism.otrub or false,
            kills   = ply:Frags() or 0,
            steam   = ply:IsBot() and "BOT" or ply:SteamID64(),
            color   = ply:GetPlayerColor():ToColor(),
        }
    end

    table.sort(players, function(a, b)
        if a.kills ~= b.kills then return a.kills > b.kills end
        return a.alive and not b.alive
    end)

    surface.PlaySound("ambient/alarms/warningbell1.wav")

    local sizeX = math.floor(ScrW() / 2.5)
    local sizeY = math.floor(ScrH() / 1.2)
    local posX = math.floor(ScrW() / 1.3 - sizeX / 2)
    local posY = math.floor(ScrH() / 2 - sizeY / 2)

    hmcdEndMenu = vgui.Create("DFrame")
    hmcdEndMenu:SetPos(posX, posY)
    hmcdEndMenu:SetSize(sizeX, sizeY)
    hmcdEndMenu:SetTitle("")
    hmcdEndMenu:SetDraggable(true)
    hmcdEndMenu:ShowCloseButton(false)
    hmcdEndMenu:MakePopup()
    hmcdEndMenu:SetKeyboardInputEnabled(false)

    hmcdEndMenu.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, EC.bg)
        surface.SetDrawColor(EC.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(traitorName .. " był zdrajcą (" .. traitorNick .. ")", "HMEnd_Big", w / 2, 30, EC.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(EC.dark)
        surface.DrawRect(10, 55, w - 20, 1)
    end

    local close = vgui.Create("DButton", hmcdEndMenu)
    close:SetPos(sizeX - 75, 8)
    close:SetSize(65, 24)
    close:SetText("")
    close:SetCursor("hand")
    close.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and EC.red or EC.row)
        draw.SimpleText("Zamknij", "HMEnd_Small", w / 2, h / 2, EC.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = function()
        if IsValid(hmcdEndMenu) then hmcdEndMenu:Close() end
    end

    local list = vgui.Create("DScrollPanel", hmcdEndMenu)
    list:SetPos(8, 64)
    list:SetSize(sizeX - 16, sizeY - 72)

    local sbar = list:GetVBar()
    sbar:SetWide(3)
    sbar:SetHideButtons(true)
    sbar.Paint = function() end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, EC.gray)
    end

    for i, p in ipairs(players) do
        local row = vgui.Create("DButton", list)
        row:SetText("")
        row:Dock(TOP)
        row:DockMargin(0, 2, 0, 0)
        row:SetTall(44)
        row:SetCursor("hand")

        row.Paint = function(self, w, h)
            local bg = self:IsHovered() and EC.hover or (i % 2 == 0 and EC.row2 or EC.row)
            draw.RoundedBox(4, 0, 0, w, h, bg)

            local rc = p.traitor and EC.red or (p.gunner and EC.purple or EC.blue)
            surface.SetDrawColor(rc)
            surface.DrawRect(0, 6, 3, h - 12)

            draw.RoundedBox(4, 12, 6, 32, 32, p.color)

            local nameCol = p.alive and EC.white or EC.gray
            draw.SimpleText(p.name, "HMEnd_Med", 52, h / 2 - 1, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local rn = p.traitor and "Zdrajca" or (p.gunner and "Strzelec" or "Niewinny")
            draw.SimpleText(rn, "HMEnd_Small", w * 0.55, h / 2, rc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            draw.SimpleText(p.kills, "HMEnd_Kills", w * 0.72, h / 2, p.kills > 0 and EC.white or EC.dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local st, sc
            if p.alive then
                st = p.down and "Nieprzytomny" or "Żywy"
                sc = p.down and EC.down or EC.alive
            else
                st = "Martwy"
                sc = EC.dead
            end
            draw.SimpleText(st, "HMEnd_Small", w * 0.88, h / 2, sc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        row.DoClick = function()
            if p.steam == "BOT" then return end
            gui.OpenURL("https://steamcommunity.com/profiles/" .. p.steam)
        end

        list:AddItem(row)
    end
end

-- ============================================
-- SIEĆ
-- ============================================

net.Receive("hmcd_roundend", function()
    local traitors, gunners = {}, {}

    for key = 1, net.ReadUInt(MODE.TraitorExpectedAmtBits) do
        local traitor = net.ReadEntity()
        traitors[key] = traitor
        traitor.isTraitor = true
    end

    for key = 1, net.ReadUInt(MODE.TraitorExpectedAmtBits) do
        local gunner = net.ReadEntity()
        gunners[key] = gunner
        gunner.isGunner = true
    end

    timer.Simple(2.5, function()
        lply.isPolice = false
        lply.isTraitor = false
        lply.isGunner = false
        lply.MainTraitor = false
        lply.SubRole = nil
        lply.Profession = nil
    end)

    traitor = traitors[1] or Entity(0)

    CreateEndMenu(traitor)
end)

net.Receive("hmcd_announce_traitor_lose", function()
    local traitor = net.ReadEntity()
    local traitor_alive = net.ReadBool()

    if(IsValid(traitor))then
        chat.AddText(color_white, "Zdrajca ", traitor:GetPlayerColor():ToColor(), traitor:GetPlayerName() .. ", " .. traitor:Nick(), color_white, " został " .. (traitor_alive and "aresztowany." or "zabity."))
    end
end)

function MODE:RoundStart()
end

-- ============================================
-- RESZTA
-- ============================================

net.Receive("HMCD(StartPlayersRoleSelection)", function()
    local role = net.ReadString()

    hg.SelectPlayerRole(role)
end)

function hg.SelectPlayerRole(role, mode)
    role = role or "Traitor"
    mode = mode or "soe"

    if(IsValid(VGUI_HMCD_RolePanelList))then
        VGUI_HMCD_RolePanelList:Remove()
    end

    if(MODE.RoleChooseRoundTypes[mode])then
        VGUI_HMCD_RolePanelList = vgui.Create("HMCD_RolePanelList")
        VGUI_HMCD_RolePanelList.RolesIDsList = MODE.RoleChooseRoundTypes[mode][role]
        VGUI_HMCD_RolePanelList.Mode = mode
        VGUI_HMCD_RolePanelList:SetSize(screen_scale_2(700), screen_scale_2(300))
        VGUI_HMCD_RolePanelList:Center()
        VGUI_HMCD_RolePanelList:InvalidateParent(false)
        VGUI_HMCD_RolePanelList:Construct()
        VGUI_HMCD_RolePanelList:MakePopup()
    end
end

net.Receive("HMCD(EndPlayersRoleSelection)", function()
    if(IsValid(VGUI_HMCD_RolePanelList))then
        VGUI_HMCD_RolePanelList:Remove()
    end
end)

net.Receive("HMCD(SetSubRole)", function(len, ply)
    lply.SubRole = net.ReadString()
end)

MODE.CreateEndMenu = CreateEndMenu

MODE.CloseEndMenu = function()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Close()
        hmcdEndMenu = nil
    end
end

concommand.Add("hmcd_test_endmenu", function()
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply.isTraitor = true
        CreateEndMenu(ply)
    end
end)