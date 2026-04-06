-- ==========================================================================
-- ExiliumRBG — UI/ExportFrame.lua
-- Exportación de datos en formato CSV y JSON
-- ==========================================================================

local ADDON_PREFIX = "|cff00aaff[ExiliumRBG]|r "

local exportFrame = nil
local editBox = nil
local currentTab = "CSV"

-- --------------------------------------------------------------------------
-- Generar datos CSV
-- --------------------------------------------------------------------------

local function GenerateCSV()
    local zone = GetRealZoneText() or "Unknown"
    local dateStr = date("%Y-%m-%d %H:%M")

    -- Resultado del BG
    local winner = GetBattlefieldWinner()
    local myFaction = GetBattlefieldArenaFaction()
    local resultStr = "En curso"
    if winner then
        resultStr = (winner == myFaction) and "Victoria" or "Derrota"
    end

    -- Duración
    local duration = "??:??"
    if ExiliumRBG.bgStartTime then
        local elapsed = time() - ExiliumRBG.bgStartTime
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60
        duration = string.format("%02d:%02d", mins, secs)
    end

    local lines = {}
    table.insert(lines, "ExiliumRBG Export — " .. zone .. " — " .. dateStr)
    table.insert(lines, "Resultado: " .. resultStr)
    table.insert(lines, "Duración: " .. duration)
    table.insert(lines, "")
    table.insert(lines, "Jugador,Clase,Grupo,Daño,Sanación,Muertes,KB,HK,Honor")

    for _, p in ipairs(ExiliumRBG.allPlayers or {}) do
        local groupStr = p.group or "-"
        table.insert(lines, string.format("%s,%s,%s,%d,%d,%d,%d,%d,%d",
            p.name or "???",
            p.classToken or "???",
            groupStr,
            p.damage or 0,
            p.healing or 0,
            p.deaths or 0,
            p.kb or 0,
            p.hk or 0,
            p.honorGained or 0
        ))
    end

    return table.concat(lines, "\n")
end

-- --------------------------------------------------------------------------
-- Generar datos JSON
-- --------------------------------------------------------------------------

local function GenerateJSON()
    local zone = GetRealZoneText() or "Unknown"
    local dateStr = date("%Y-%m-%d")

    local winner = GetBattlefieldWinner()
    local myFaction = GetBattlefieldArenaFaction()
    local resultStr = "In Progress"
    if winner then
        resultStr = (winner == myFaction) and "Victory" or "Defeat"
    end

    local duration = "??:??"
    if ExiliumRBG.bgStartTime then
        local elapsed = time() - ExiliumRBG.bgStartTime
        local mins = math.floor(elapsed / 60)
        local secs = elapsed % 60
        duration = string.format("%02d:%02d", mins, secs)
    end

    local lines = {}
    table.insert(lines, "{")
    table.insert(lines, '  "map": "' .. zone .. '",')
    table.insert(lines, '  "result": "' .. resultStr .. '",')
    table.insert(lines, '  "duration": "' .. duration .. '",')
    table.insert(lines, '  "date": "' .. dateStr .. '",')
    table.insert(lines, '  "players": [')

    local players = ExiliumRBG.allPlayers or {}
    for i, p in ipairs(players) do
        local comma = (i < #players) and "," or ""
        local groupStr = p.group and ('"' .. p.group .. '"') or "null"
        table.insert(lines, "    {")
        table.insert(lines, '      "name": "' .. (p.name or "???") .. '",')
        table.insert(lines, '      "class": "' .. (p.classToken or "???") .. '",')
        table.insert(lines, '      "group": ' .. groupStr .. ',')
        table.insert(lines, '      "damage": ' .. tostring(p.damage or 0) .. ',')
        table.insert(lines, '      "healing": ' .. tostring(p.healing or 0) .. ',')
        table.insert(lines, '      "deaths": ' .. tostring(p.deaths or 0) .. ',')
        table.insert(lines, '      "kb": ' .. tostring(p.kb or 0) .. ',')
        table.insert(lines, '      "hk": ' .. tostring(p.hk or 0) .. ',')
        table.insert(lines, '      "honor": ' .. tostring(p.honorGained or 0))
        table.insert(lines, "    }" .. comma)
    end

    table.insert(lines, "  ]")
    table.insert(lines, "}")

    return table.concat(lines, "\n")
end

-- --------------------------------------------------------------------------
-- Crear el frame de exportación
-- --------------------------------------------------------------------------

local function CreateExportFrame()
    exportFrame = CreateFrame("Frame", "ExiliumRBGExportFrame", UIParent, "BackdropTemplate")
    exportFrame:SetSize(500, 400)
    exportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    exportFrame:SetClampedToScreen(true)
    exportFrame:SetMovable(true)
    exportFrame:EnableMouse(true)
    exportFrame:SetFrameStrata("DIALOG")

    exportFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local theme = ExiliumRBG.GetTheme()
    local bg = theme.bgColor
    exportFrame:SetBackdropColor(bg[1], bg[2], bg[3], 0.95)
    local bc = theme.borderColor
    exportFrame:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4])

    -- Drag
    exportFrame:RegisterForDrag("LeftButton")
    exportFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    exportFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Título
    local titleText = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", exportFrame, "TOPLEFT", 12, -10)
    titleText:SetText("|cff00aaffExiliumRBG — Exportar|r")

    -- Botón X
    local closeBtn = CreateFrame("Button", nil, exportFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", exportFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() exportFrame:Hide() end)

    -- ----- Tabs: CSV / JSON -----
    local csvTab = CreateFrame("Button", nil, exportFrame, "BackdropTemplate")
    csvTab:SetSize(60, 24)
    csvTab:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
    csvTab:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    csvTab:SetBackdropColor(0.3, 0.3, 0.5, 1)
    local csvText = csvTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    csvText:SetPoint("CENTER")
    csvText:SetText("CSV")

    local jsonTab = CreateFrame("Button", nil, exportFrame, "BackdropTemplate")
    jsonTab:SetSize(60, 24)
    jsonTab:SetPoint("LEFT", csvTab, "RIGHT", 4, 0)
    jsonTab:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    jsonTab:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    local jsonText = jsonTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    jsonText:SetPoint("CENTER")
    jsonText:SetText("JSON")

    -- ----- EditBox (multilínea) -----
    local scrollFrame = CreateFrame("ScrollFrame", "ExiliumRBGExportScroll", exportFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", csvTab, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", exportFrame, "BOTTOMRIGHT", -30, 40)

    editBox = CreateFrame("EditBox", "ExiliumRBGExportEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(scrollFrame:GetWidth() or 440)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollFrame:SetScrollChild(editBox)

    -- ----- Función para actualizar contenido -----
    local function RefreshExport()
        if currentTab == "CSV" then
            editBox:SetText(GenerateCSV())
            csvTab:SetBackdropColor(0.3, 0.3, 0.5, 1)
            jsonTab:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        else
            editBox:SetText(GenerateJSON())
            csvTab:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            jsonTab:SetBackdropColor(0.3, 0.3, 0.5, 1)
        end
    end

    csvTab:SetScript("OnClick", function()
        currentTab = "CSV"
        RefreshExport()
    end)
    jsonTab:SetScript("OnClick", function()
        currentTab = "JSON"
        RefreshExport()
    end)

    -- ----- Botón "Seleccionar todo" -----
    local selectAllBtn = CreateFrame("Button", nil, exportFrame, "BackdropTemplate")
    selectAllBtn:SetSize(110, 22)
    selectAllBtn:SetPoint("BOTTOMLEFT", exportFrame, "BOTTOMLEFT", 12, 10)
    selectAllBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    selectAllBtn:SetBackdropColor(0.2, 0.2, 0.3, 0.9)
    local selectAllText = selectAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    selectAllText:SetPoint("CENTER")
    selectAllText:SetText("Seleccionar todo")
    selectAllBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    selectAllBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.5, 1)
    end)
    selectAllBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.3, 0.9)
    end)

    exportFrame.RefreshExport = RefreshExport
    exportFrame:Hide()

    return exportFrame
end

-- --------------------------------------------------------------------------
-- Toggle
-- --------------------------------------------------------------------------

function ExiliumRBG.ToggleExportFrame()
    if not exportFrame then
        CreateExportFrame()
    end

    if exportFrame:IsShown() then
        exportFrame:Hide()
    else
        exportFrame.RefreshExport()
        exportFrame:Show()
    end
end
