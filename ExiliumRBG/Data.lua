-- ==========================================================================
-- ExiliumRBG — Data.lua
-- Única fuente de verdad de estadísticas de battlefield
-- ==========================================================================

local ADDON_PREFIX = "|cff00aaff[ExiliumRBG]|r "
local UPDATE_INTERVAL = 3 -- segundos de respaldo OnUpdate

ExiliumRBG.myTeam = {}
ExiliumRBG.enemyTeam = {}
ExiliumRBG.allPlayers = {}

-- --------------------------------------------------------------------------
-- SafeGetName — pcall para proteger acceso a GetBattlefieldScore
-- --------------------------------------------------------------------------

local function SafeGetName(index)
    local ok, name = pcall(function()
        return (GetBattlefieldScore(index))
    end)
    if ok and type(name) == "string" then
        return name
    end
    return "???"
end

-- --------------------------------------------------------------------------
-- Recolección de objetivos específicos del mapa
-- --------------------------------------------------------------------------

local function GetObjectives(playerIndex)
    local objectives = {}
    local slotIndex = 1
    while true do
        local ok, info = pcall(GetBattlefieldStatInfo, slotIndex)
        if not ok or not info then break end
        local okData, value = pcall(GetBattlefieldStatData, playerIndex, slotIndex)
        if okData then
            objectives[info] = value or 0
        end
        slotIndex = slotIndex + 1
    end
    return objectives
end

-- --------------------------------------------------------------------------
-- Recolección principal de datos
-- --------------------------------------------------------------------------

local function CollectData()
    if not ExiliumRBG.IsInRatedBG() then return end

    local numScores = GetNumBattlefieldScores()
    if numScores == 0 then return end

    local myFaction = GetBattlefieldArenaFaction()
    local players = {}

    for i = 1, numScores do
        local name = SafeGetName(i)
        local ok, killing, hk, deaths, honor, faction, race, class, classToken, damage, healing, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = pcall(function()
            local n, kb2, hk2, d2, h2, f2, r2, c2, ct2, dmg2, heal2, rat2, rc2, pmm2, mmc2, ts2 = GetBattlefieldScore(i)
            return kb2, hk2, d2, h2, f2, r2, c2, ct2, dmg2, heal2, rat2, rc2, pmm2, mmc2, ts2
        end)

        if ok then
            local player = {
                index       = i,
                name        = name,
                classToken  = classToken or "WARRIOR",
                faction     = faction or 0,
                damage      = damage or 0,
                healing     = healing or 0,
                deaths      = deaths or 0,
                kb          = killing or 0,
                hk          = hk or 0,
                honorGained = honor or 0,
                bgRating    = bgRating or 0,
                objectives  = GetObjectives(i),
                group       = nil,
            }

            -- Preservar asignación de grupo existente
            if ExiliumRBGDB.groups then
                for _, g in pairs(ExiliumRBGDB.groups) do
                    if g.name == name then
                        player.group = g.group
                        break
                    end
                end
            end

            table.insert(players, player)
        end
    end

    -- Ordenar según preferencias del usuario
    local sortBy = ExiliumRBGDB.sortBy or "damage"
    local sortDir = ExiliumRBGDB.sortDir or "desc"

    table.sort(players, function(a, b)
        local va = a[sortBy] or 0
        local vb = b[sortBy] or 0
        if type(va) == "table" then va = 0 end
        if type(vb) == "table" then vb = 0 end
        if sortDir == "desc" then
            return va > vb
        else
            return va < vb
        end
    end)

    -- Separar por equipo
    ExiliumRBG.allPlayers = players
    ExiliumRBG.myTeam = {}
    ExiliumRBG.enemyTeam = {}

    for _, p in ipairs(players) do
        if p.faction == myFaction then
            table.insert(ExiliumRBG.myTeam, p)
        else
            table.insert(ExiliumRBG.enemyTeam, p)
        end
    end

    -- Refrescar UI si está disponible
    if ExiliumRBG.RefreshUI then
        ExiliumRBG.RefreshUI()
    end
end

-- --------------------------------------------------------------------------
-- Reset de datos (llamado al inicio de nuevo BG)
-- --------------------------------------------------------------------------

function ExiliumRBG.ResetData()
    ExiliumRBG.myTeam = {}
    ExiliumRBG.enemyTeam = {}
    ExiliumRBG.allPlayers = {}
end

-- --------------------------------------------------------------------------
-- Asignación de grupo
-- --------------------------------------------------------------------------

function ExiliumRBG.AssignGroup(playerName, groupType)
    -- groupType: "attack", "defense", nil (quitar)
    if not ExiliumRBGDB.groups then
        ExiliumRBGDB.groups = {}
    end

    -- Buscar si ya existe
    for i, g in ipairs(ExiliumRBGDB.groups) do
        if g.name == playerName then
            if groupType then
                g.group = groupType
            else
                table.remove(ExiliumRBGDB.groups, i)
            end
            CollectData()
            return
        end
    end

    -- No existe, añadir
    if groupType then
        table.insert(ExiliumRBGDB.groups, { name = playerName, group = groupType })
    end
    CollectData()
end

function ExiliumRBG.GetGroupMembers(groupType)
    local members = {}
    for _, p in ipairs(ExiliumRBG.myTeam) do
        if p.group == groupType then
            table.insert(members, p)
        end
    end
    return members
end

-- --------------------------------------------------------------------------
-- Eventos
-- --------------------------------------------------------------------------

local dataFrame = CreateFrame("Frame")
dataFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
dataFrame:RegisterEvent("PLAYER_DEAD")
dataFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

dataFrame:SetScript("OnEvent", function(self, event)
    if event == "UPDATE_BATTLEFIELD_SCORE" then
        CollectData()
    elseif event == "PLAYER_DEAD" or event == "GROUP_ROSTER_UPDATE" then
        RequestBattlefieldScoreData()
    end
end)

-- --------------------------------------------------------------------------
-- OnUpdate como respaldo cada 3 segundos
-- --------------------------------------------------------------------------

local elapsed = 0
dataFrame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed >= UPDATE_INTERVAL then
        elapsed = 0
        if ExiliumRBG.IsInRatedBG() then
            RequestBattlefieldScoreData()
        end
    end
end)

-- Función pública para forzar actualización
function ExiliumRBG.ForceUpdate()
    RequestBattlefieldScoreData()
end
