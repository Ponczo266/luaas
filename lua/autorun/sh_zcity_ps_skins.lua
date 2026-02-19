if SERVER then AddCSLuaFile() end

hg = hg or {}
hg.PointShop = hg.PointShop or {}
hg.Appearance = hg.Appearance or {}

-- Uwaga:
-- donate = false -> ZP
-- donate = true  -> DZP
--
-- vpos/campos/fov to ustawienia podglądu w PointShop (twarz zamiast nóg).
-- Jeśli jakiś model wygląda źle w podglądzie, zmieniamy tylko te 3 wartości.

local SKINS = {
    {
        id = "skin_papaj",
        name = "Papaj",
        mdl = "models/t37/papaj.mdl",

        price = 2,
        donate = true,

        sexIndex = 1,
        fov = 18,
        vpos = Vector(0, 0, 72),
        campos = Vector(28, 0, 72),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },





-- ==================== NOWE SKÓRKI (dodatkowe) ====================

{
    id = "skin_zombie_fast",
    name = "Fast Zombie",
    mdl = "models/player/zombie_fast.mdl",

    price = 2,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_zombie_classic",
    name = "Classic Zombie",
    mdl = "models/player/zombie_classic.mdl",

    price = 2,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_police",
    name = "Police",
    mdl = "models/player/police.mdl",

    price = 2,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_police_fem",
    name = "Police Female",
    mdl = "models/player/police_fem.mdl",

    price = 2,
    donate = true,

    sexIndex = 2,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_dod_american",
    name = "DoD American",
    mdl = "models/player/dod_american.mdl",

    price = 2,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_dod_german",
    name = "DoD German",
    mdl = "models/player/dod_german.mdl",

    price = 2,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_charple",
    name = "Charple",
    mdl = "models/player/charple.mdl",

    price = 1,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_corpse",
    name = "Corpse",
    mdl = "models/player/corpse1.mdl",

    price = 1,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_gman",
    name = "G-Man",
    mdl = "models/player/gman_high.mdl",

    price = 1,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_skeleton",
    name = "Skeleton",
    mdl = "models/player/skeleton.mdl",

    price = 1,
    donate = true,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_zombie_soldier",
    name = "Zombie Soldier",
    mdl = "models/player/zombie_soldier.mdl",

    price = 31313,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_barney",
    name = "Barney",
    mdl = "models/player/barney.mdl",

    price = 1200,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_chell",
    name = "Chell (Portal 2)",
    mdl = "models/player/p2_chell.mdl",

    price = 1800,
    donate = false,

    sexIndex = 2,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_guerilla",
    name = "Guerilla",
    mdl = "models/player/guerilla.mdl",

    price = 900,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_phoenix",
    name = "Phoenix",
    mdl = "models/player/phoenix.mdl",

    price = 1500,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_arctic",
    name = "Arctic",
    mdl = "models/player/arctic.mdl",

    price = 1100,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_alyx",
    name = "Alyx",
    mdl = "models/player/alyx.mdl",

    price = 2000,
    donate = false,

    sexIndex = 2,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_hostage",
    name = "Hostage",
    mdl = "models/player/hostage/hostage_04.mdl",

    price = 700,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_monk",
    name = "Monk (Father Grigori)",
    mdl = "models/player/monk.mdl",

    price = 2200,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_odessa",
    name = "Odessa Cubbage",
    mdl = "models/player/odessa.mdl",

    price = 1600,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},

{
    id = "skin_soldier_stripped",
    name = "Soldier Stripped",
    mdl = "models/player/soldier_stripped.mdl",

    price = 2500,
    donate = false,

    sexIndex = 1,
    fov = 20,
    vpos = Vector(0, 0, 66),
    campos = Vector(45, 0, 66),

    bodygroups = "00000",
    skin = 0,
    data = {},
},











-- ==================== NOWE SKÓRKI ====================

    {
        id = "skin_harry_potter",
        name = "Harry Potter",
        mdl = "models/player/harry_potter.mdl",

        price = 3,
        donate = true,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_jack_sparrow",
        name = "Jack Sparrow",
        mdl = "models/player/jack_sparrow.mdl",

        price = 4,
        donate = true,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_joker",
        name = "Joker",
        mdl = "models/player/joker.mdl",

        price = 4,
        donate = true,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_chewbacca",
        name = "Chewbacca",
        mdl = "models/player/chewbacca.mdl",

        price = 5,
        donate = true,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_stormtrooper",
        name = "Stormtrooper",
        mdl = "models/player/stormtrooper.mdl",

        price = 4,
        donate = true,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_ddlc_monika",
        name = "DDLC Monika",
        mdl = "models/player/ddlc_lp/ddlc_monika_lp.mdl",

        price = 1,
        donate = true,

        sexIndex = 2,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_ddlc_natsuki",
        name = "DDLC Natsuki",
        mdl = "models/player/ddlc_lp/ddlc_natsuki_lp.mdl",

        price = 1,
        donate = true,

        sexIndex = 2,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_ddlc_sayori",
        name = "DDLC Sayori",
        mdl = "models/player/ddlc_lp/ddlc_sayori_lp.mdl",

        price = 1,
        donate = true,

        sexIndex = 2,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_ddlc_yuri",
        name = "DDLC Yuri",
        mdl = "models/player/ddlc_lp/ddlc_yuri_lp.mdl",

        price = 1,
        donate = true,

        sexIndex = 2,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_dude",
        name = "Dude",
        mdl = "models/postal1_dude.mdl",

        price = 2,
        donate = true,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_nicole_demara",
        name = "Nicole Demara (Zenless)",
        mdl = "models/player/zenless_nicole_demara.mdl",

        price = 10,
        donate = true,

        sexIndex = 2,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_zerotwo",
        name = "Zero Two",
        mdl = "models/cyanblue/darlingfranxx/zerotwo/zerotwo.mdl",

        price = 5,
        donate = true,

        sexIndex = 2,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_ironman_mark46",
        name = "Iron Man Mark 46",
        mdl = "models/player/mrp/ironmen/mk46.mdl",

        price = 5,
        donate = true,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_mrbean",
        name = "Mr. Bean",
        mdl = "models/mrbeangta/mrbeangta_pm.mdl",

        price = 3500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_taa",
        name = "TAA",
        mdl = "models/player/taa.mdl",

        price = 2500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_amir",
        name = "Amir",
        mdl = "models/player/amir/amir_v2.mdl",

        price = 3000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_agent47",
        name = "Agent 47",
        mdl = "models/agent_47/agent_47.mdl",

        price = 4500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_macdguy",
        name = "MacDGuy",
        mdl = "models/player/macdguy.mdl",

        price = 2000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_leon",
        name = "Leon",
        mdl = "models/player/leon.mdl",

        price = 4000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_red",
        name = "Red",
        mdl = "models/player/red.mdl",

        price = 2500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_smith",
        name = "Smith",
        mdl = "models/player/smith.mdl",

        price = 3000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_robber",
        name = "Robber",
        mdl = "models/player/robber.mdl",

        price = 2000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_spy",
        name = "Spy",
        mdl = "models/player/drpyspy/spy.mdl",

        price = 3500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_sunabouzu",
        name = "Sunabouzu",
        mdl = "models/player/sunabouzu.mdl",

        price = 3000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_gordon",
        name = "Gordon Freeman",
        mdl = "models/player/gordon.mdl",

        price = 1500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_freddykruger",
        name = "Freddy Kruger",
        mdl = "models/player/freddykruger.mdl",

        price = 5000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_zelda",
        name = "Zelda",
        mdl = "models/player/zelda.mdl",

        price = 4000,
        donate = false,

        sexIndex = 2,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_bigboss",
        name = "Big Boss",
        mdl = "models/player/big_boss.mdl",

        price = 4500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_knight",
        name = "Knight",
        mdl = "models/player/knight.mdl",

        price = 5500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_spartan",
        name = "Spartan Classic",
        mdl = "models/player/lordvipes/haloce/spartan_classic.mdl",

        price = 6000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_anon",
        name = "Anonymous",
        mdl = "models/player/anon/anon.mdl",

        price = 4000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

-- dssd






















    {
        id = "skin_jesus",
        name = "Jesus",
        mdl = "models/player/jesus/jesus.mdl",

        price = 5000,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(45, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_kermit",
        name = "Kermit",
        mdl = "models/player/kermit.mdl",

        price = 3500,
        donate = false,

        sexIndex = 1,
        fov = 22,
        vpos = Vector(0, 0, 62),
        campos = Vector(42, 0, 62),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_nosacz",
        name = "Nosacz",
        mdl = "models/player/nosaczt37/nosacz.mdl",

        price = 1,
        donate = true,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 66),
        campos = Vector(48, 0, 66),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_kleiner",
        name = "Kleiner",
        mdl = "models/player/kleiner.mdl",

        price = 500,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 64),
        campos = Vector(45, 0, 64),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },

    {
        id = "skin_eli",
        name = "Eli",
        mdl = "models/player/eli.mdl",

        price = 750,
        donate = false,

        sexIndex = 1,
        fov = 20,
        vpos = Vector(0, 0, 64),
        campos = Vector(45, 0, 64),

        bodygroups = "00000",
        skin = 0,
        data = {},
    },
}

hook.Add("ZPointshopLoaded", "ZCity_AddSkinsToPointShopAndAppearance", function()
    local PS = hg.PointShop
    if not PS or not PS.CreateItem then
        print("[ZCity Skins] PointShop nie gotowy (brak CreateItem).")
        return
    end

    -- 1) Dodaj do PointShopa
    for _, s in ipairs(SKINS) do
        PS:CreateItem(
            s.id,
            "Skin: " .. s.name,
            s.mdl,
            s.bodygroups or "00000",
            s.skin or 0,
            s.vpos or Vector(0, 0, 0),
            s.price or 0,
            s.donate or false,
            s.data or {},
            nil,
            s.fov or 15,
            s.campos -- kamera do podglądu twarzy (wymaga obsługi CAM_POS w PS + UI)
        )
    end

    -- 2) Dodaj do Appearance (z blokadą psItemID)
    timer.Simple(0, function()
        if not hg.Appearance or not hg.Appearance.PlayerModels then
            print("[ZCity Skins] Appearance nie gotowe (brak PlayerModels).")
            return
        end

        hg.Appearance.FuckYouModels = hg.Appearance.FuckYouModels or { {}, {} }

        for _, s in ipairs(SKINS) do
            local sexIndex = s.sexIndex or 1

            hg.Appearance.PlayerModels[sexIndex] = hg.Appearance.PlayerModels[sexIndex] or {}
            hg.Appearance.PlayerModels[sexIndex][s.name] = {
                mdl = s.mdl,
                submatSlots = {},  -- ważne: {} a nie nil
                sex = (sexIndex == 2),
                psItemID = s.id
            }

            hg.Appearance.FuckYouModels[sexIndex][s.mdl] = hg.Appearance.PlayerModels[sexIndex][s.name]
        end
    end)
end)