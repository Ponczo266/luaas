hg.Appearance = hg.Appearance or {}

-- File manager

hg.Appearance.SelectedAppearance = ConVarExists("hg_appearance_selected") and GetConVar("hg_appearance_selected") or CreateClientConVar("hg_appearance_selected","main",true,false,"name of selected appearance json file")
hg.Appearance.ForcedRandom = ConVarExists("hg_appearance_force_random") and GetConVar("hg_appearance_force_random") or CreateClientConVar("hg_appearance_force_random","0",true,false,"forced appearance random",0,1)

local dir = "zcity/appearances/"
function hg.Appearance.CreateAppearanceFile(strFile_name, tblAppearance)
	file.CreateDir(dir)
	file.Write(dir .. strFile_name .. ".json", util.TableToJSON(tblAppearance, true) )
end

function hg.Appearance.LoadAppearanceFile(strFile_name)
	if not file.Exists(dir .. strFile_name .. ".json", "DATA") then return false, "no file [data/zcity/appearances/" .. strFile_name .. ".json]" end
	local tblAppearance = util.JSONToTable(file.Read(dir .. strFile_name .. ".json"))

	if not hg.Appearance.AppearanceValidater(tblAppearance) then return false, "file is damaged [data/zcity/appearances/" .. strFile_name .. ".json]"  end

	return tblAppearance
end

function hg.Appearance.GetAppearanceList()
	local files = file.Find( dir .. "*.json" )
	return files
end

-- Send from client...
net.Receive("Get_Appearance", function()
	local forced_random = hg.Appearance.ForcedRandom:GetBool()
    net.Start("Get_Appearance")
		local tbl,reason

		if not forced_random then
			tbl,reason = hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
		end
		
        net.WriteTable(tbl and tbl or {})
        net.WriteBool(not tbl)
    net.SendToServer()

	if not tbl and not forced_random then lply:ChatPrint("[Appearance] file load failed - " .. reason) end
end)

local function OnlyGetAppearance()
	local forced_random = hg.Appearance.ForcedRandom:GetBool()
    net.Start("OnlyGet_Appearance")
		local tbl,reason

		if not forced_random then 
			tbl,reason = hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
		end

        net.WriteTable(tbl or {})

    net.SendToServer()

	if not tbl and not forced_random then lply:ChatPrint("[Appearance] file load failed - " .. reason) end
end

net.Receive("OnlyGet_Appearance", OnlyGetAppearance)

-- Render things

local whitelist = {
    weapon_physgun = true,
    gmod_tool = true,
    gmod_camera = true,
    weapon_crowbar = true,
    weapon_pistol = true,
    weapon_crossbow = true
}

local islply

function RenderAccessories(ply, accessories, setup)

	if not IsValid(ply) or not accessories then return end

	if accessories == "none" then return end

	local wep = ply:IsPlayer() and ply:GetActiveWeapon()

	local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
	ent = IsValid(ply.OldRagdoll) and ply.OldRagdoll:IsRagdoll() and ply.OldRagdoll or ent

	islply = ((ply:IsRagdoll() and hg.RagdollOwner(ply)) or ply) == (LocalPlayer():Alive() and LocalPlayer() or LocalPlayer():GetNWEntity("spect",LocalPlayer())) and GetViewEntity() == (LocalPlayer():Alive() and LocalPlayer() or LocalPlayer():GetNWEntity("spect",LocalPlayer()))

	if islply and IsValid(wep) and whitelist[wep:GetClass()] then
		if not ent.modelAccess then return end
		for k,v in ipairs(ent.modelAccess) do
			if IsValid(v) then
				v:Remove()
				v = nil
			end
		end
		return
	end

	if not ent.shouldTransmit or ent.NotSeen then
		if not ent.modelAccess then return end
		for k,v in ipairs(ent.modelAccess) do
			if IsValid(v) then
				v:Remove()
				v = nil
			end
		end
		return
	end

	if istable(accessories) then
		for k = 1, #accessories do
			local accessoriess = accessories[k]
			local accessData = hg.Accessories[accessoriess]
			if not accessData then continue end
			if accessData.needcoolRender then continue end

			DrawAccesories(ply, ent, accessoriess, accessData, islply, nil, setup)
		end
	else
		local accessData = hg.Accessories[accessories]
		if not accessData then return end
		if accessData.needcoolRender then return end

		DrawAccesories(ply, ent, accessories, accessData, islply, nil, setup)
	end
end

local huy_addvec = Vector(0.4,0,0.4)
function DrawAccesories(ply, ent, accessories,accessData, islply, force, setup)
	if not accessories then return end
	if not accessData then return end

	ply.modelAccess = ply.modelAccess or {}

	local fem = ThatPlyIsFemale(ent)
	if not IsValid(ply.modelAccess[accessories]) then
		if not accessData["model"] then return end
		ply.modelAccess[accessories] = ClientsideModel(fem and accessData["femmodel"] or accessData["model"], RENDERGROUP_BOTH)

		local model = ply.modelAccess[accessories]
		model:SetNoDraw(true)
		model:SetModelScale( accessData[fem and "fempos" or "malepos"][3] )
		model:SetSkin( isfunction(accessData["skin"]) and accessData["skin"](ent) or accessData["skin"] )
		model:SetBodyGroups( accessData["bodygroups"] or "" )
		model:SetParent(ent, ent:LookupBone(accessData["bone"]))
		if accessData.bonemerge then
			model:AddEffects(EF_BONEMERGE)
		end
		if accessData["bSetColor"] then
			if ply.GetPlayerColor then 
				model:SetColor(ply:GetPlayerColor():ToColor())
			else
				model:SetColor(ply:GetNWVector("PlayerColor",Vector(1,1,1)):ToColor())
			end
		end

		if accessData["SubMat"] then
			model:SetSubMaterial(0,accessData["SubMat"])
		end

		ply:CallOnRemove("RemoveAccessories"..accessories,function() 
			if ply.modelAccess and IsValid(model) then
				model:Remove()
				model = nil
			end
		end)
		ent:CallOnRemove("RemoveAccessories2"..accessories,function() 
			if ply.modelAccess and IsValid(model) then
				model:Remove()
				model = nil
			end
		end)
	end

	local model = ply.modelAccess[accessories]
	--print(ent:GetModel(),ent)
	local mdl = string.Split(string.sub(ent:GetModel(),1,-5),"/")[#string.Split(string.sub(ent:GetModel(),1,-5),"/")]
	if mdl and model:GetFlexIDByName(mdl) then
		model:SetFlexWeight(model:GetFlexIDByName(mdl),1)
	end
	--if model:GetFlexIDByName(ThatPlyIsFemale(ply) and "F" or "M") then
	--	model:SetFlexWeight(model:GetFlexIDByName(ThatPlyIsFemale(ply) and "F" or "M"),1)
	--end
	model:SetSkin( isfunction(accessData["skin"]) and accessData["skin"](ent) or accessData["skin"] )

	if not IsValid(model) then ply.modelAccess[accessories] = nil return end

	if ply.armors and accessData["placement"] and ply.armors[accessData["placement"]] then

		return
	end

	if not force and ((ent.NotSeen or not ent.shouldTransmit) or (ply:IsPlayer() and not ply:Alive())) then

		return
	end

	if setup != false then
		local bone = ent:LookupBone(accessData["bone"])
		if not bone then return end
		if ent:GetManipulateBoneScale(bone):LengthSqr() < 0.1 then return end
		local matrix = ent:GetBoneMatrix(bone)
		if not matrix then return end

		local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()

		local addvec = ((ent:GetModel() == "models/player/group01/male_06.mdl") and ((accessData.placement == "head") or (accessData.placement == "face"))) and huy_addvec or vector_origin

		local pos, ang = LocalToWorld(accessData[fem and "fempos" or "malepos"][1], accessData[fem and "fempos" or "malepos"][2], bonePos, boneAng)
		local pos = LocalToWorld(addvec, angle_zero, pos, ang)
		
		--model:SetupBones()
		model:SetRenderOrigin(pos)
		model:SetRenderAngles(ang)
	end

	if model:GetParent() != ent then model:SetParent(ent, bone) end
	if !(islply and accessData.norender) and (!setup or accessData.bonemerge) then
		if accessData["bSetColor"] then
			local colorDraw = accessData["vecColorOveride"] or ( ply.GetPlayerColor and ply:GetPlayerColor() or ply:GetNWVector("PlayerColor",Vector(1,1,1)) )
			render.SetColorModulation( colorDraw[1],colorDraw[2],colorDraw[3] )
		end
		
		model:DrawModel()
		
		if accessData["bSetColor"] then
			render.SetColorModulation( 1, 1, 1 )
		end
	end
end

local flpos,flang = Vector(4,-1,0),Angle(0,0,0)

local offsetVec,offsetAng = Vector(1,0,0),Angle(100,90,0)

local mat2 = Material("sprites/light_glow02_add_noz")
local mat3 = Material("effects/flashlight/soft")

function DrawAppearance(ent, ply, setup)
    local Access = ent:GetNetVar("Accessories") or ent.PredictedAccessories
	
	if IsValid(ent) and Access then
		RenderAccessories(ply, Access, setup)
	end
	
	if setup then return end
	
	if not ply:IsPlayer() then return end
	
	local inv = ply:GetNetVar("Inventory",{})
	if not inv["Weapons"] or not inv["Weapons"]["hg_flashlight"] then
		if ply.flashlight then
			ply.flashlight:Remove()
			ply.flashlight = nil
		end
		if ply.flmodel then
			ply.flmodel:Remove()
			ply.flmodel = nil
		end
		return
	end

	local wep = ply:GetActiveWeapon()
	local flashlightwep

	if IsValid(wep) then
		local laser = wep.attachments and wep.attachments.underbarrel
		local attachmentData
		if ( laser and !table.IsEmpty(laser) ) or wep.laser then
			if laser and !table.IsEmpty(laser) then
				attachmentData = hg.attachments.underbarrel[laser[1]]
			else
				attachmentData = wep.laserData
			end
		end

		if attachmentData then flashlightwep = attachmentData.supportFlashlight end
	end

	if IsValid(ply.flmodel) then
		ply.flmodel:SetNoDraw(!(ply:GetNetVar("flashlight") and (!wep.IsPistolHoldType or wep:IsPistolHoldType())) or wep.reload or flashlightwep)
	end

	-- =========================================================================
	-- FIX LATARKI: HYBRYDA (Model w ręce + Światło w oczach)
	-- =========================================================================
	
	local isOn = ply:GetNetVar("flashlight")
	
	-- 1. RYSOWANIE MODELU 3D (Tylko wizualnie)
	-- Model podczepiamy pod rękę, żeby inni gracze widzieli, że masz latarkę.
	local canDrawHand = isOn 
		and not flashlightwep 
		and not wep.reload 
		-- and hg.CanUseLeftHand(ply) -- Wyłączone, żeby model był zawsze

	if canDrawHand then
		local hand = ent:LookupBone("ValveBiped.Bip01_L_Hand")
		if hand then
			local handmat = ent:GetBoneMatrix(hand)
			if handmat then
				-- Pozycja ręki
				local pos, ang = handmat:GetTranslation(), handmat:GetAngles()
				
				-- Jeśli skrypt ma zdefiniowane offsety (zmienne offsetVec/Ang), używamy ich
				if offsetVec then
					pos, ang = LocalToWorld(offsetVec, offsetAng, pos, ang)
				end

				ply.flmodel = IsValid(ply.flmodel) and ply.flmodel or ClientsideModel("models/runaway911/props/item/flashlight.mdl")
				ply.flmodel:SetModelScale(0.75)
				ply.flmodel:SetNoDraw(false)

				if ent ~= ply then pos = handmat:GetTranslation() end
				
				if flpos then
					pos, _ = LocalToWorld(flpos, flang, pos, handmat:GetAngles())
				end
				
				if IsValid(ply.flmodel) and (ply ~= LocalPlayer() or ply ~= GetViewEntity()) then
					local veclh, lang = hg.FlashlightTransform(ply)
				end

				ply.flmodel:SetPos(pos)
				ply.flmodel:SetAngles(ang)
				ply.flmodel:DrawModel()
			end
		end
	else
		-- Ukrywamy model, jeśli np. przeładowujesz
		if IsValid(ply.flmodel) then ply.flmodel:SetNoDraw(true) end
	end

	-- 2. RYSOWANIE ŚWIATŁA (Sterowane wzrokiem!)
	-- To naprawia problem "świecenia w niebo".
	if isOn then
		ply.flashlight = IsValid(ply.flashlight) and ply.flashlight or ProjectedTexture()
		
		if ply.flashlight and ply.flashlight:IsValid() then
			local flash = ply.flashlight
			
			flash:SetTexture(mat3:GetTexture("$basetexture"))
			flash:SetFarZ(1500)
			flash:SetNearZ(5)
			flash:SetHorizontalFOV(60)
			flash:SetVerticalFOV(60)
			flash:SetConstantAttenuation(0.1)
			flash:SetLinearAttenuation(50)
			
			-- Cienie WYŁĄCZONE (Dzięki temu światło nie jest blokowane przez ciało)
			flash:SetEnableShadows(false) 

			-- POZYCJONOWANIE IDEALNE (PODĄŻANIE ZA WZROKIEM)
			-- Bierzemy kąt patrzenia gracza (EyeAngles)
			local aimAng = ply:EyeAngles()
			local eyePos = ply:GetShootPos()
			
			-- Przesuwamy światło:
			-- 20 przód (żeby wyjść z głowy)
			-- 10 prawo (żeby było lekko z boku, jak w prawej ręce/na ramieniu)
			-- 5 dół (żeby nie wychodziło z czubka głowy)
			local lightOffset = (aimAng:Forward() * 20) + (aimAng:Right() * 10) - (aimAng:Up() * 5)

			flash:SetPos(eyePos + lightOffset)
			flash:SetAngles(aimAng) -- !!! TO JEST KLUCZ: Kąt identyczny jak wzrok !!!
			
			flash:Update()
		end
	else
		-- Czyszczenie
		if ply.flashlight and IsValid(ply.flashlight) then
			ply.flashlight:Remove()
			ply.flashlight = nil
		end
		if ply.flmodel and IsValid(ply.flmodel) then
			ply.flmodel:Remove()
			ply.flmodel = nil
		end
	end
end

hook.Add("RenderScreenspaceEffects","AppearanceShitty",function()
	if (not LocalPlayer():Alive()) or LocalPlayer():GetViewEntity() ~= LocalPlayer() then return end
	local ply = LocalPlayer()
	local acsses = ply:GetNetVar("Accessories", "none")

	if istable(acsses) then
		for k,accessoriess in ipairs(acsses) do
			local accessData = hg.Accessories[accessoriess]
			if not accessData then continue end
			if ply.armors and accessData["placement"] and ply.armors[accessData["placement"]] then continue end
			if accessData.ScreenSpaceEffects then
				accessData.ScreenSpaceEffects()
			end
		end
	elseif acsses then
		local accessData = hg.Accessories[acsses]
		if not accessData then return end
		if ply.armors and accessData["placement"] and ply.armors[accessData["placement"]] then return end
		if accessData.ScreenSpaceEffects then
			accessData.ScreenSpaceEffects()
		end
	end
end)

function CoolRenderAccessories(ply, accessories)

	if not IsValid(ply) or not accessories then return end

	if accessories == "none" then return end

	local wep = ply:IsPlayer() and ply:GetActiveWeapon()

	local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply

	islply = ((ply:IsRagdoll() and hg.RagdollOwner(ply)) or ply) == (LocalPlayer():Alive() and LocalPlayer() or LocalPlayer():GetNWEntity("spect",LocalPlayer())) and GetViewEntity() == (LocalPlayer():Alive() and LocalPlayer() or LocalPlayer():GetNWEntity("spect",LocalPlayer()))

	if islply and IsValid(wep) and whitelist[wep:GetClass()] then
		if not ent.modelAccess then return end
		for k,v in ipairs(ent.modelAccess) do
			if IsValid(v) then
				v:Remove()
				v = nil
			end
		end
		return
	end

	if not ent.shouldTransmit or ent.NotSeen then
		if not ent.modelAccess then return end
		for k,v in ipairs(ent.modelAccess) do
			if IsValid(v) then
				v:Remove()
				v = nil
			end
		end
		return
	end

	if istable(accessories) then
		for k = 1, #accessories do
			local accessoriess = accessories[k]
			local accessData = hg.Accessories[accessoriess]
			if not accessData then continue end
			if not accessData.needcoolRender then continue end

			DrawAccesories(ply,ent,accessoriess,accessData,islply)
		end
	else
		local accessData = hg.Accessories[accessories]
		if not accessData then return end
		if not accessData.needcoolRender then return end

		DrawAccesories(ply,ent,accessories,accessData,islply)
	end
end

function RenderAccessoriesCool(ent,ply)
	if IsValid(ent) and ent:GetNetVar("Accessories") then
		CoolRenderAccessories(ent, ent:GetNetVar("Accessories", "none"))
	end
end