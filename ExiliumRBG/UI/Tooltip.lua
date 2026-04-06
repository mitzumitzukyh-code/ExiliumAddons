-- ==========================================================================
-- ExiliumRBG — UI/Tooltip.lua
-- Tooltip detallado al hacer hover sobre un jugador
-- ==========================================================================

local tooltipFrame = nil

-- --------------------------------------------------------------------------
-- Crear el frame del tooltip
-- --------------------------------------------------------------------------

local function EnsureTooltip()
    if tooltipFrame then return tooltipFrame end

    tooltipFrame = CreateFrame("Frame", "ExiliumRBGTooltip", UIParent, "BackdropTemplate")
    tooltipFrame:SetSize(220, 200)
    tooltipFrame:SetFrameStrata("TOOLTIP")
    tooltipFrame:SetClampedToScreen(true)

    tooltipFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    tooltipFrame:SetBackdropColor(0.05, 0.05, 0.15, 0.95)
    tooltipFrame:SetBackdropBorderColor(0, 0.6, 1, 0.8)

    tooltipFrame.lines = {}
    tooltipFrame:Hide()

    return tooltipFrame
end

-- --------------------------------------------------------------------------
-- Añadir línea al tooltip
-- --------------------------------------------------------------------------

local function AddLine(text, r, g, b)
    local tt = EnsureTooltip()
    local lineIndex = #tt.lines + 1

    if not tt.lines[lineIndex] then
        tt.lines[lineIndex] = tt:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    end

    local line = tt.lines[lineIndex]
    line:SetPoint("TOPLEFT", tt, "TOPLEFT", 10, -10 - (lineIndex - 1) * 14)
    line:SetPoint("TOPRIGHT", tt, "TOPRIGHT", -10, -10 - (lineIndex - 1) * 14)
    line:SetJustifyH("LEFT")
    line:SetText(text)
    line:SetTextColor(r or 1, g or 1, b or 1)
    line:Show()
end

-- --------------------------------------------------------------------------
-- Limpiar líneas
-- --------------------------------------------------------------------------

local function ClearLines()
    local tt = EnsureTooltip()
    for _, line in ipairs(tt.lines) do
        line:Hide()
    end
    tt.lines = {}
end

-- --------------------------------------------------------------------------
-- Mostrar tooltip para un jugador
-- --------------------------------------------------------------------------

function ExiliumRBG.ShowPlayerTooltip(anchor, playerData)
    if not playerData then return end

    ClearLines()
    local tt = EnsureTooltip()

    -- Nombre con color de clase
    local colorCode = GetClassColor(playerData.classToken)
    AddLine(colorCode .. playerData.name .. "|r", 1, 1, 1)

    -- Clase y facción
    local factionStr = (playerData.faction == 1) and "Alianza" or "Horda"
    AddLine("Clase: " .. (playerData.classToken or "???") .. " | " .. factionStr, 0.8, 0.8, 0.8)

    -- Separador
    AddLine("---", 0.4, 0.4, 0.4)

    -- Estadísticas detalladas
    AddLine("Daño: " .. FormatNumber(playerData.damage or 0), 1, 0.3, 0.3)
    AddLine("Sanación: " .. FormatNumber(playerData.healing or 0), 0.3, 1, 0.3)
    AddLine("Muertes: " .. tostring(playerData.deaths or 0), 0.8, 0.8, 0.8)
    AddLine("Killing Blows: " .. tostring(playerData.kb or 0), 1, 0.8, 0)
    AddLine("Honorable Kills: " .. tostring(playerData.hk or 0), 1, 0.8, 0)
    AddLine("Honor ganado: " .. tostring(playerData.honorGained or 0), 1, 1, 0.5)

    -- RBG Rating
    if playerData.bgRating and playerData.bgRating > 0 then
        AddLine("RBG Rating: " .. tostring(playerData.bgRating), 0, 0.8, 1)
    end

    -- Grupo asignado
    if playerData.group then
        local groupLabel = playerData.group == "attack" and "|cffff4444Ataque|r" or "|cff4444ffDefensa|r"
        AddLine("Grupo: " .. groupLabel, 1, 1, 1)
    end

    -- Objetivos
    if playerData.objectives and next(playerData.objectives) then
        AddLine("---", 0.4, 0.4, 0.4)
        AddLine("Objetivos:", 1, 1, 0)
        for k, v in pairs(playerData.objectives) do
            AddLine("  " .. tostring(k) .. ": " .. tostring(v), 0.9, 0.9, 0.7)
        end
    end

    -- Ajustar tamaño del tooltip
    local numLines = #tt.lines
    tt:SetHeight(20 + numLines * 14)

    -- Posicionar junto al anchor
    tt:ClearAllPoints()
    tt:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
    tt:Show()
end

-- --------------------------------------------------------------------------
-- Ocultar tooltip
-- --------------------------------------------------------------------------

function ExiliumRBG.HidePlayerTooltip()
    if tooltipFrame then
        tooltipFrame:Hide()
    end
end
