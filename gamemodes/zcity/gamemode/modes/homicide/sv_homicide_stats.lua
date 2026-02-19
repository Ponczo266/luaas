-- ============================================
-- SYSTEM ŚLEDZENIA STATYSTYK RUNDY - HOMICIDE
-- Pełny system server-side do śledzenia wszystkich statystyk graczy
-- ============================================

local MODE = MODE

MODE.RoundStats = MODE.RoundStats or {}
MODE.RoundStartTime = MODE.RoundStartTime or 0
MODE.FirstBloodClaimed = false
MODE.RoundEndReason = nil
MODE.LastKiller = nil

-- ============================================
-- NETWORK STRINGS
-- ============================================

util.AddNetworkString("hmcd_roundend_extended")

-- ============================================
-- INICJALIZACJA STATYSTYK GRACZA
-- ============================================

function MODE:InitPlayerStats(ply)
    if not IsValid(ply) then return nil end
    
    local id = ply:SteamID64() or tostring(ply:EntIndex())
    
    self.RoundStats[id] = {
        -- Podstawowe statystyki
        kills = 0,
        deaths = 0,
        damage_dealt = 0,
        damage_taken = 0,
        
        -- Celność
        headshots = 0,
        shots_fired = 0,
        shots_hit = 0,
        
        -- Typy zabójstw
        knife_kills = 0,
        gun_kills = 0,
        explosive_kills = 0,
        poison_kills = 0,
        melee_kills = 0,
        
        -- Dystans
        longest_kill_distance = 0,
        
        -- Zabójstwa według roli
        innocents_killed = 0,
        traitors_killed = 0,
        gunners_killed = 0,
        
        -- Specjalne osiągnięcia
        first_blood = false,
        last_kill = false,
        
        -- Czas
        survival_time = 0,
        spawn_time = CurTime(),
        death_time = nil,
        
        -- Dodatkowe
        revives = 0,
        assists = 0,
        items_used = 0
    }
    
    return self.RoundStats[id]
end

-- ============================================
-- RESETOWANIE STATYSTYK NA POCZĄTKU RUNDY
-- ============================================

function MODE:ResetAllStats()
    self.RoundStats = {}
    self.RoundStartTime = CurTime()
    self.FirstBloodClaimed = false
    self.RoundEndReason = nil
    self.LastKiller = nil
    
    for _, ply in player.Iterator() do
        if ply:Team() ~= TEAM_SPECTATOR then
            self:InitPlayerStats(ply)
        end
    end
    
    print("[HMCD Statystyki] Wszystkie statystyki graczy zresetowane dla nowej rundy")
end

-- ============================================
-- POBIERANIE STATYSTYK GRACZA
-- ============================================

function MODE:GetPlayerStats(ply)
    if not IsValid(ply) then return nil end
    
    local id = ply:SteamID64() or tostring(ply:EntIndex())
    
    if not self.RoundStats[id] then
        return self:InitPlayerStats(ply)
    end
    
    return self.RoundStats[id]
end

-- ============================================
-- HOOK: ŚLEDZENIE OBRAŻEŃ
-- ============================================

hook.Add("EntityTakeDamage", "HMCD_TrackDamage", function(target, dmginfo)
    if not MODE.RoundStats then return end
    if not MODE.RoundStartTime or MODE.RoundStartTime == 0 then return end
    
    local attacker = dmginfo:GetAttacker()
    local damage = dmginfo:GetDamage()
    
    -- Sprawdź czy to gracze
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(target) or not target:IsPlayer() then return end
    if attacker == target then return end
    
    local attacker_stats = MODE:GetPlayerStats(attacker)
    local target_stats = MODE:GetPlayerStats(target)
    
    if not attacker_stats or not target_stats then return end
    
    -- Dodaj zadane obrażenia
    attacker_stats.damage_dealt = attacker_stats.damage_dealt + damage
    target_stats.damage_taken = target_stats.damage_taken + damage
    
    -- Wykryj headshot
    if dmginfo:IsDamageType(DMG_BULLET) then
        local hitgroup = target:LastHitGroup()
        if hitgroup == HITGROUP_HEAD then
            attacker_stats.headshots = attacker_stats.headshots + 1
        end
        
        -- Trafienie pociskiem
        attacker_stats.shots_hit = attacker_stats.shots_hit + 1
    end
    
    -- Śledzenie najdłuższego dystansu
    local distance = attacker:GetPos():Distance(target:GetPos())
    if distance > attacker_stats.longest_kill_distance then
        attacker_stats.longest_kill_distance = distance
    end
end)

-- ============================================
-- HOOK: ŚLEDZENIE ZABÓJSTW
-- ============================================

hook.Add("PlayerDeath", "HMCD_TrackKills", function(victim, inflictor, attacker)
    if not MODE.RoundStats then return end
    if not MODE.RoundStartTime or MODE.RoundStartTime == 0 then return end
    
    -- Statystyki ofiary
    if IsValid(victim) then
        local victim_stats = MODE:GetPlayerStats(victim)
        
        if victim_stats then
            victim_stats.deaths = victim_stats.deaths + 1
            victim_stats.death_time = CurTime()
            victim_stats.survival_time = CurTime() - (victim_stats.spawn_time or MODE.RoundStartTime)
        end
    end
    
    -- Statystyki zabójcy
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        local attacker_stats = MODE:GetPlayerStats(attacker)
        
        if attacker_stats then
            attacker_stats.kills = attacker_stats.kills + 1
            MODE.LastKiller = attacker
            
            -- Pierwsza krew
            if not MODE.FirstBloodClaimed then
                MODE.FirstBloodClaimed = true
                attacker_stats.first_blood = true
            end
            
            -- Typ zabójstwa na podstawie broni
            local wep = attacker:GetActiveWeapon()
            local wep_class = IsValid(wep) and string.lower(wep:GetClass()) or ""
            local inflictor_class = IsValid(inflictor) and string.lower(inflictor:GetClass()) or ""
            
            -- Wykryj typ broni
            local kill_type = "gun"
            
            -- Nóż/broń biała
            if string.find(wep_class, "knife") or string.find(inflictor_class, "knife") or
               string.find(wep_class, "machete") or string.find(inflictor_class, "machete") or
               string.find(wep_class, "axe") or string.find(inflictor_class, "axe") or
               string.find(wep_class, "crowbar") or string.find(inflictor_class, "crowbar") or
               string.find(wep_class, "bat") or string.find(inflictor_class, "bat") or
               string.find(wep_class, "melee") or string.find(inflictor_class, "melee") or
               string.find(wep_class, "shovel") or string.find(inflictor_class, "shovel") or
               string.find(wep_class, "hammer") or string.find(inflictor_class, "hammer") or
               string.find(wep_class, "spear") or string.find(inflictor_class, "spear") then
                kill_type = "knife"
                attacker_stats.knife_kills = attacker_stats.knife_kills + 1
                
            -- Eksplozje
            elseif string.find(inflictor_class, "grenade") or string.find(inflictor_class, "explosive") or
                   string.find(inflictor_class, "bomb") or string.find(inflictor_class, "c4") or
                   string.find(inflictor_class, "rpg") or string.find(inflictor_class, "rocket") or
                   string.find(inflictor_class, "molotov") or string.find(inflictor_class, "pipebomb") or
                   dmginfo:IsDamageType(DMG_BLAST) then
                kill_type = "explosive"
                attacker_stats.explosive_kills = attacker_stats.explosive_kills + 1
                
            -- Trucizna
            elseif string.find(inflictor_class, "poison") or string.find(wep_class, "poison") or
                   string.find(inflictor_class, "cyanide") or string.find(inflictor_class, "toxic") or
                   string.find(inflictor_class, "fentanyl") then
                kill_type = "poison"
                attacker_stats.poison_kills = attacker_stats.poison_kills + 1
                
            -- Broń palna (domyślnie)
            else
                attacker_stats.gun_kills = attacker_stats.gun_kills + 1
            end
            
            -- Śledzenie zabójstw według roli ofiary
            if IsValid(victim) then
                if victim.isTraitor then
                    attacker_stats.traitors_killed = attacker_stats.traitors_killed + 1
                elseif victim.isGunner then
                    attacker_stats.gunners_killed = attacker_stats.gunners_killed + 1
                else
                    attacker_stats.innocents_killed = attacker_stats.innocents_killed + 1
                end
            end
        end
    end
end)

-- ============================================
-- HOOK: ŚLEDZENIE STRZAŁÓW
-- ============================================

hook.Add("EntityFireBullets", "HMCD_TrackShots", function(entity, data)
    if not MODE.RoundStats then return end
    if not MODE.RoundStartTime or MODE.RoundStartTime == 0 then return end
    
    if IsValid(entity) and entity:IsPlayer() then
        local stats = MODE:GetPlayerStats(entity)
        if stats then
            stats.shots_fired = stats.shots_fired + (data.Num or 1)
        end
    end
end)

-- ============================================
-- HOOK: RESET NA POCZĄTKU RUNDY
-- ============================================

hook.Add("HMCD_RoundStart", "HMCD_ResetStats", function()
    MODE:ResetAllStats()
end)

hook.Add("OnRoundStart", "HMCD_ResetStats_Alt", function()
    MODE:ResetAllStats()
end)

-- ============================================
-- WYSYŁANIE ROZSZERZONYCH STATYSTYK NA KONIEC RUNDY
-- ============================================

function MODE:SendExtendedRoundEnd(win_reason, winning_team)
    self.RoundEndReason = win_reason or "nieznany"
    local round_duration = CurTime() - (self.RoundStartTime or CurTime())
    
    -- Zbierz wszystkich zdrajców i graczy
    local traitors = {}
    local gunners = {}
    local all_players_data = {}
    
    for _, ply in player.Iterator() do
        if not IsValid(ply) then continue end
        if ply:Team() == TEAM_SPECTATOR then continue end
        
        local stats = self:GetPlayerStats(ply) or {}
        
        -- Oblicz celność
        local accuracy = 0
        if stats.shots_fired and stats.shots_fired > 0 then
            accuracy = math.Round((stats.shots_hit or 0) / stats.shots_fired * 100)
        end
        
        -- Konwertuj dystans na metry (52.49 jednostek = 1 metr)
        local longest_kill_meters = math.Round((stats.longest_kill_distance or 0) / 52.49)
        
        local player_data = {
            ent = ply,
            nick = ply:Nick() or "Nieznany",
            name = ply:GetPlayerName() or ply:Nick() or "Nieznany",
            steamid = ply:IsBot() and "BOT" or (ply:SteamID64() or "NIEZNANY"),
            isTraitor = ply.isTraitor or false,
            isGunner = ply.isGunner or false,
            isMainTraitor = ply.MainTraitor or false,
            alive = ply:Alive(),
            incapacitated = (ply.organism and ply.organism.otrub) or (ply.organism and ply.organism.incapacitated) or false,
            color = ply:GetPlayerColor() or Vector(0.5, 0.5, 0.5),
            subrole = ply.SubRole or "",
            profession = ply.Profession or "",
            stats = {
                kills = stats.kills or 0,
                deaths = stats.deaths or 0,
                damage_dealt = math.Round(stats.damage_dealt or 0),
                damage_taken = math.Round(stats.damage_taken or 0),
                headshots = stats.headshots or 0,
                knife_kills = stats.knife_kills or 0,
                gun_kills = stats.gun_kills or 0,
                explosive_kills = stats.explosive_kills or 0,
                poison_kills = stats.poison_kills or 0,
                shots_fired = stats.shots_fired or 0,
                shots_hit = stats.shots_hit or 0,
                accuracy = accuracy,
                longest_kill = longest_kill_meters,
                innocents_killed = stats.innocents_killed or 0,
                traitors_killed = stats.traitors_killed or 0,
                gunners_killed = stats.gunners_killed or 0,
                first_blood = stats.first_blood or false,
                survival_time = math.Round(stats.survival_time or (CurTime() - (stats.spawn_time or MODE.RoundStartTime)))
            }
        }
        
        table.insert(all_players_data, player_data)
        
        if ply.isTraitor then
            table.insert(traitors, player_data)
        end
        if ply.isGunner then
            table.insert(gunners, player_data)
        end
    end
    
    -- Sortuj graczy po zabójstwach, potem po obrażeniach
    table.sort(all_players_data, function(a, b)
        if a.stats.kills ~= b.stats.kills then
            return a.stats.kills > b.stats.kills
        end
        return a.stats.damage_dealt > b.stats.damage_dealt
    end)
    
    -- Sortuj zdrajców - główny zdrajca pierwszy
    table.sort(traitors, function(a, b)
        if a.isMainTraitor ~= b.isMainTraitor then
            return a.isMainTraitor
        end
        return a.stats.kills > b.stats.kills
    end)
    
    -- Oznacz ostatnie zabójstwo
    if IsValid(self.LastKiller) then
        local last_killer_stats = self:GetPlayerStats(self.LastKiller)
        if last_killer_stats then
            last_killer_stats.last_kill = true
        end
    end
    
    -- Wyślij dane do wszystkich graczy
    net.Start("hmcd_roundend_extended")
    
        -- Informacje o rundzie
        net.WriteString(win_reason or "nieznany")
        net.WriteString(winning_team or "nieznany")
        net.WriteFloat(round_duration)
        net.WriteString(self.Type or "standard")
        
        -- Liczba i dane zdrajców
        net.WriteUInt(math.min(#traitors, 255), 8)
        for i = 1, math.min(#traitors, 255) do
            local t = traitors[i]
            net.WriteEntity(t.ent)
            net.WriteString(t.name or "Nieznany")
            net.WriteString(t.nick or "Nieznany")
            net.WriteBool(t.isMainTraitor or false)
            net.WriteBool(t.alive or false)
            net.WriteString(t.subrole or "")
            net.WriteVector(t.color or Vector(0.5, 0.5, 0.5))
        end
        
        -- Liczba i dane wszystkich graczy
        net.WriteUInt(math.min(#all_players_data, 255), 8)
        for i = 1, math.min(#all_players_data, 255) do
            local p = all_players_data[i]
            net.WriteEntity(p.ent)
            net.WriteString(p.name or "Nieznany")
            net.WriteString(p.nick or "Nieznany")
            net.WriteString(p.steamid or "NIEZNANY")
            net.WriteBool(p.isTraitor or false)
            net.WriteBool(p.isGunner or false)
            net.WriteBool(p.alive or false)
            net.WriteBool(p.incapacitated or false)
            net.WriteVector(p.color or Vector(0.5, 0.5, 0.5))
            net.WriteString(p.subrole or "")
            net.WriteString(p.profession or "")
            
            -- Statystyki (z limitami dla bezpieczeństwa)
            net.WriteUInt(math.min(p.stats.kills or 0, 255), 8)
            net.WriteUInt(math.min(p.stats.deaths or 0, 255), 8)
            net.WriteUInt(math.min(p.stats.damage_dealt or 0, 65535), 16)
            net.WriteUInt(math.min(p.stats.headshots or 0, 255), 8)
            net.WriteUInt(math.min(p.stats.accuracy or 0, 100), 7)
            net.WriteUInt(math.min(p.stats.longest_kill or 0, 1023), 10)
            net.WriteUInt(math.min(p.stats.innocents_killed or 0, 255), 8)
            net.WriteUInt(math.min(p.stats.traitors_killed or 0, 255), 8)
            net.WriteBool(p.stats.first_blood or false)
            net.WriteUInt(math.min(p.stats.knife_kills or 0, 255), 8)
            net.WriteUInt(math.min(p.stats.gun_kills or 0, 255), 8)
            net.WriteUInt(math.min(p.stats.explosive_kills or 0, 255), 8)
        end
        
    net.Broadcast()
    
    print("[HMCD] Wysłano dane końca rundy do wszystkich klientów")
    print("[HMCD] Zwycięzca: " .. winning_team .. " | Powód: " .. win_reason)
    print("[HMCD] Czas trwania: " .. string.format("%.1f", round_duration) .. " sekund")
    print("[HMCD] Gracze: " .. #all_players_data .. " | Zdrajcy: " .. #traitors)
end

-- ============================================
-- FUNKCJA DO ZAKOŃCZENIA RUNDY ZE STATYSTYKAMI
-- ============================================

function MODE:EndRoundWithStats(win_reason, winning_team)
    self:SendExtendedRoundEnd(win_reason, winning_team)
end

-- ============================================
-- KOMPATYBILNOŚĆ ZE STARYM SYSTEMEM
-- ============================================

function MODE:SendLegacyRoundEnd()
    local traitors = {}
    local gunners = {}
    
    for _, ply in player.Iterator() do
        if not IsValid(ply) then continue end
        if ply.isTraitor then table.insert(traitors, ply) end
        if ply.isGunner then table.insert(gunners, ply) end
    end
    
    net.Start("hmcd_roundend")
        net.WriteUInt(#traitors, self.TraitorExpectedAmtBits or 4)
        for _, t in ipairs(traitors) do
            net.WriteEntity(t)
        end
        
        net.WriteUInt(#gunners, self.TraitorExpectedAmtBits or 4)
        for _, g in ipairs(gunners) do
            net.WriteEntity(g)
        end
    net.Broadcast()
end

print("[HMCD] System śledzenia statystyk rundy załadowany")