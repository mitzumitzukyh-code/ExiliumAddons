-- ==========================================================================
-- ExiliumRBG — Maps.lua
-- Puntos estratégicos por mapa de Battleground
-- ==========================================================================

ExiliumRBG.Maps = {
    ["Arathi Basin"] = {
        points = { "Mina", "Establo", "Herrería", "Molino", "Granja" },
    },
    ["Battle for Gilneas"] = {
        points = { "Mina", "Puerto", "Cementerio" },
    },
    ["Warsong Gulch"] = {
        points = { "Base Alianza", "Base Horda", "Centro" },
    },
    ["Twin Peaks"] = {
        points = { "Base Alianza", "Base Horda", "Centro" },
    },
    ["Eye of the Storm"] = {
        points = { "Torre BE", "Torre Draenei", "Mage Tower", "Felreaver Ruins", "Centro" },
    },
    ["Silvershard Mines"] = {
        points = { "Cruce Norte", "Cruce Sur", "Depósito" },
    },
    ["Temple of Kotmogu"] = {
        points = { "Centro", "Orbe Norte", "Orbe Sur", "Orbe Este", "Orbe Oeste" },
    },
    ["Deepwind Gorge"] = {
        points = { "Mina Norte", "Mina Sur", "Mercado" },
    },
    ["Seething Shore"] = {
        points = { "Nodo 1", "Nodo 2", "Nodo 3", "Nodo 4", "Nodo 5" },
    },
}

function ExiliumRBG.GetCurrentMapPoints()
    local zone = GetRealZoneText()
    return ExiliumRBG.Maps[zone] and ExiliumRBG.Maps[zone].points or {}
end
