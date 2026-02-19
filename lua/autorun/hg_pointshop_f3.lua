if SERVER then
    hook.Add("ShowSpare1", "HG_PointShop_OpenOnF3", function(ply)
        if not IsValid(ply) then return end

        -- Najprostsze: każ klientowi wykonać komendę,
        -- ALE tylko jeśli ta komenda istnieje po stronie klienta.
        ply:ConCommand("hg_pointshop\n")
    end)
end