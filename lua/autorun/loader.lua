hg = hg or {}
hg.Version = "Release 1.05/2.137"
hg.GitHub_ReposOwner = "uzelezz123"
hg.GitHub_ReposName = "Z-City" -- please add your real git fork!

if SERVER then
	resource.AddWorkshop("3658718947") -- main addon
	resource.AddWorkshop("3657897364") -- main content addon
	resource.AddWorkshop("3657294321") -- first content addon
	resource.AddWorkshop("3544105055") -- second content addon
	resource.AddWorkshop("3257937532") -- distac content
	resource.AddWorkshop("3665770846") -- ZCITY POLSKA CONTENT PACK
	resource.AddWorkshop("237872885") -- Jezus pm
	resource.AddWorkshop("1286716330") -- nosacz pm
	resource.AddWorkshop("485879458") -- kermit pm
	resource.AddWorkshop("3655753919") -- king tinky winky
	resource.AddWorkshop("1263024280") -- PAPIEZ POLAK
	resource.AddWorkshop("129736354") -- czapki roblox
	resource.AddWorkshop("3382746569") -- fnaf experience
	resource.AddWorkshop("3657166179") -- wyspa epsteina
	resource.AddWorkshop("3630862322") -- Epstein PM
	resource.AddWorkshop("2826620603") -- mapka city apo
	resource.AddWorkshop("811718553") -- thomas gun
end
-- if hg.GitHub_ReposOwner and hg.GitHub_ReposOwner != "" then
-- 	http.Fetch( "https://api.github.com/repos/" .. hg.GitHub_ReposOwner .. "/" .. hg.GitHub_ReposName .. "/commits?sha=" .. hg.GitHub_Branch .. "&per_page=1",
-- 		function( body, length, headers, code )
-- 			--PrintTable(headers)
-- 			local tbl = util.JSONToTable(body)
-- 			hg.Git_LastCommitTime = tbl[1]["committer"]["date"]

-- 		end
-- 	)
-- else
-- 	hg.GitHub_ReposOwner = "Unknown"
-- 	hg.GitHub_ReposName = "Please add your github fork"
-- 	hg.Git_CommitNumber = "Unknown"
-- end
local sides = {
	["sv_"] = "sv_",
	["sh_"] = "sh_",
	["cl_"] = "cl_",
	["_sv"] = "sv_",
	["_sh"] = "sh_",
	["_cl"] = "cl_",
}

local function AddFile(File, dir)
	local fileSide = string.lower(string.Left(File, 3))
	local fileSide2 = string.lower(string.Right(string.sub(File, 1, -5), 3))
	local side = sides[fileSide] or sides[fileSide2]
	if SERVER and side == "sv_" then
		include(dir .. File)
	elseif side == "sh_" then
		if SERVER then AddCSLuaFile(dir .. File) end
		include(dir .. File)
	elseif side == "cl_" then
		if SERVER then
			AddCSLuaFile(dir .. File)
		else
			include(dir .. File)
		end
	else
		if SERVER then AddCSLuaFile(dir .. File) end
		include(dir .. File)
	end
end

local function IncludeDir(dir)
	dir = dir .. "/"
	local files, directories = file.Find(dir .. "*", "LUA")
	if files then
		for k, v in ipairs(files) do
			if string.EndsWith(v, ".lua") then AddFile(v, dir) end
		end
	end

	if directories then
		for k, v in ipairs(directories) do
			IncludeDir(dir .. v)
		end
	end
end

local function Run()
	local time = SysTime()
	print("Loading zcity...") -- Loading homigrad :]
	hg.loaded = false
	if engine.ActiveGamemode() == "ixhl2rp" then return end
	IncludeDir("homigrad")
	hg.loaded = true
	print("Loaded zcity, " .. tostring(math.Round(SysTime() - time, 5)) .. " seconds needed")
	hook.Run("HomigradRun")
end

local initpost
hook.Add("InitPostEntity", "zcity", function()
	initpost = true
	IncludeDir("initpost")
	print("Loading initpost...")
end)
if initpost then Run() end
Run()

if not istable(ulx) then
	for i = 1, 3 do
		MsgC(Color(255, 0, 0), "WARNING: Server doesn't have ULX & ULib installed! Z-City will not work properly without it!\n")
	end
end