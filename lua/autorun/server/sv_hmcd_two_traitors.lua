-- 2 traitors from 16+ active players in HMCD (Homicide)
-- Patch without editing big sv_homicide.lua

hg = hg or {}

local function CountActivePlayers()
    local c = 0
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR then
            c = c + 1
        end
    end
    return c
end

local function GetTraitors()
    local t = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR and ply.isTraitor then
            t[#t + 1] = ply
        end
    end
    return t
end

local function PickExtraTraitor()
    -- 1) prefer karma roll like original code
    for _, ply in RandomPairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if ply:Team() == TEAM_SPECTATOR then continue end
        if ply.isTraitor then continue end

        if math.random(100) > (ply.Karma or 100) then continue end

        return ply
    end

    -- 2) fallback without karma
    for _, ply in RandomPairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if ply:Team() == TEAM_SPECTATOR then continue end
        if ply.isTraitor then continue end
        return ply
    end

    return nil
end

local function ApplyPatch()
    if not zb or not zb.modes or not zb.modes["hmcd"] then return false end
    local MODE = zb.modes["hmcd"]

    if MODE.__TwoTraitorsPatched then return true end
    if not isfunction(MODE.SpawnPlayers) then return false end

    local OldSpawnPlayers = MODE.SpawnPlayers

    MODE.SpawnPlayers = function(spawn_with_subroles)
        -- This function is called only in HMCD round, so we are already in the right mode.
        local activeCount = CountActivePlayers()

        if activeCount >= 16 then
            local traitors = GetTraitors()
            local need = 2 - #traitors

            if need > 0 then
                -- ensure expected amount for HUD etc.
                MODE.TraitorExpectedAmt = math.max(MODE.TraitorExpectedAmt or 1, 2)

                for i = 1, need do
                    local extra = PickExtraTraitor()
                    if not IsValid(extra) then break end

                    extra.isTraitor = true
                    extra.MainTraitor = false -- keep existing main traitor

                    -- optional debug:
                    -- print("[HMCD] Added extra traitor:", extra:Nick(), extra:SteamID())
                end
            end
        end

        return OldSpawnPlayers(spawn_with_subroles)
    end

    MODE.__TwoTraitorsPatched = true
    print("[HMCD PATCH] Enabled: 2 traitors at 16+ active players.")
    return true
end

-- Try patching a few times, because zb/modes load order can vary
hook.Add("Initialize", "HMCD_PatchTwoTraitors_Init", function()
    timer.Create("HMCD_PatchTwoTraitors_Retry", 1, 30, function()
        if ApplyPatch() then
            timer.Remove("HMCD_PatchTwoTraitors_Retry")
        end
    end)
end)