-- ============================================
-- LOADER DLA SYSTEMU MENU KOŃCA RUNDY
-- Ten plik ładuje wszystkie komponenty systemu
-- ============================================

local MODE = MODE

-- Ładuj pliki w odpowiedniej kolejności
if SERVER then
    -- Server: ładuj system śledzenia statystyk
    include("sv_homicide_stats.lua")
    
    -- Wyślij plik klienta
    AddCSLuaFile("cl_homicide_endmenu.lua")
    
    print("[HMCD Loader] Załadowano pliki serwerowe")
end

if CLIENT then
    -- Client: ładuj menu końca rundy
    include("cl_homicide_endmenu.lua")
    
    print("[HMCD Loader] Załadowano pliki klienckie")
end

print("[HMCD Loader] System menu końca rundy gotowy")