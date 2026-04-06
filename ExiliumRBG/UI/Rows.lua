-- ==========================================================================
-- ExiliumRBG — UI/Rows.lua
-- Filas de jugadores con estadísticas, barras y scroll
-- ==========================================================================

local ADDON_PREFIX = "|cff00aaff[ExiliumRBG]|r "
local ROW_HEIGHT = 22
local MAX_VISIBLE_ROWS = 15
local HEADER_HEIGHT = 24
local CELL_PADDING = 6

local rowPool = {}
local headerFrame = nil
local scrollFrame = nil
local scrollChild = nil
local contentFrame = nil

-- --------------------------------------------------------------------------
-- Columnas definidas
-- --------------------------------------------------------------------------

local COLUMNS = {
    { key = "class",      label = "",          width = 24,  dbKey = "class" },
    { key = "name",       label = "Nombre",    width = 140, dbKey = "name" },
    { key = "damage",     label = "Daño",      width = 80,  dbKey = "damage" },
    { key = "healing",    label = "Sanación",  width = 80,  dbKey = "healing" },
    { key = "deaths",     label = "Muertes",   width = 65,  dbKey = "deaths" },
    { key = "kb",         label = "KB",        width = 50,  dbKey = "kb" },
    { key = "honor",      label = "Honor",     width = 55,  dbKey = "honor" },
    { key = "objectives", label = "Objetivos", width = 80,  dbKey = "objectives" },
}

-- --------------------------------------------------------------------------
-- Obtener columnas visibles
-- --------------------------------------------------------------------------

local function GetVisibleColumns()
    local visible = {}
    for _, col in ipairs(COLUMNS) do
        if ExiliumRBGDB.columns[col.dbKey] then
            table.insert(visible, col)
        end
    end
    return visible
end

-- --------------------------------------------------------------------------
-- Crear una fila de jugador
-- --------------------------------------------------------------------------

local function CreateRow(parent, index)
    local row = CreateFrame("Frame", "ExiliumRBGRow" .. index, parent, "BackdropTemplate")
    row:SetHeight(ROW_HEIGHT)
    row:EnableMouse(true)

    -- Fondo alternado
    row:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    })

    -- Icono de clase
    row.classIcon = row:CreateTexture(nil, "ARTWORK")
    row.classIcon:SetSize(18, 18)
    row.classIcon:SetPoint("LEFT", row, "LEFT", CELL_PADDING, 0)

    -- Nombre
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", row.classIcon, "RIGHT", CELL_PADDING, 0)
    row.nameText:SetWidth(134)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)

    -- Estadísticas (se crean dinámicamente)
    row.statTexts = {}

    -- Barra de progreso (opcional)
    row.bar = row:CreateTexture(nil, "BACKGROUND")
    row.bar:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.bar:SetHeight(ROW_HEIGHT)
    row.bar:SetColorTexture(1, 1, 1, 0.1)

    -- Click derecho → menú contextual
    row:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" and self.playerData then
            ExiliumRBG.ShowPlayerContextMenu(self, self.playerData)
        end
    end)

    -- Hover → tooltip
    row:SetScript("OnEnter", function(self)
        if self.playerData then
            self:SetBackdropColor(0.3, 0.3, 0.5, 0.5)
            ExiliumRBG.ShowPlayerTooltip(self, self.playerData)
        end
    end)
    row:SetScript("OnLeave", function(self)
        local alpha = (self.rowIndex and self.rowIndex % 2 == 0) and 0.1 or 0.05
        self:SetBackdropColor(0.1, 0.1, 0.1, alpha)
        if ExiliumRBG.HidePlayerTooltip then
            ExiliumRBG.HidePlayerTooltip()
        end
    end)

    return row
end

-- --------------------------------------------------------------------------
-- Menú contextual de jugador
-- --------------------------------------------------------------------------

function ExiliumRBG.ShowPlayerContextMenu(anchor, playerData)
    if not playerData or not playerData.name then return end

    local menu = CreateFrame("Frame", "ExiliumRBGContextMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(menu, function(self, level)
        local info

        info = UIDropDownMenu_CreateInfo()
        info.text = playerData.name
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)

        info = UIDropDownMenu_CreateInfo()
        info.text = "Asignar a Ataque"
        info.notCheckable = true
        info.func = function()
            ExiliumRBG.AssignGroup(playerData.name, "attack")
        end
        UIDropDownMenu_AddButton(info)

        info = UIDropDownMenu_CreateInfo()
        info.text = "Asignar a Defensa"
        info.notCheckable = true
        info.func = function()
            ExiliumRBG.AssignGroup(playerData.name, "defense")
        end
        UIDropDownMenu_AddButton(info)

        info = UIDropDownMenu_CreateInfo()
        info.text = "Quitar de grupo"
        info.notCheckable = true
        info.func = function()
            ExiliumRBG.AssignGroup(playerData.name, nil)
        end
        UIDropDownMenu_AddButton(info)
    end, "MENU")
    ToggleDropDownMenu(1, nil, menu, anchor, 0, 0)
end

-- --------------------------------------------------------------------------
-- Headers clicables para ordenar
-- --------------------------------------------------------------------------

local function CreateHeaders(parent)
    if headerFrame then headerFrame:Hide() end

    headerFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    headerFrame:SetHeight(HEADER_HEIGHT)
    headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    headerFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    headerFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    })
    headerFrame:SetBackdropColor(0.03, 0.03, 0.08, 0.95)

    local theme = ExiliumRBG.GetTheme()
    local visibleCols = GetVisibleColumns()
    local xOffset = 0

    for _, col in ipairs(visibleCols) do
        local btn = CreateFrame("Button", nil, headerFrame)
        btn:SetSize(col.width, HEADER_HEIGHT)
        btn:SetPoint("LEFT", headerFrame, "LEFT", xOffset, 0)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", btn, "LEFT", CELL_PADDING, 0)
        text:SetTextColor(theme.headerColor[1], theme.headerColor[2], theme.headerColor[3])
        text:SetWordWrap(false)

        local sortIndicator = ""
        if ExiliumRBGDB.sortBy == col.key then
            sortIndicator = ExiliumRBGDB.sortDir == "desc" and " ▼" or " ▲"
        end
        text:SetText(col.label .. sortIndicator)

        if col.key ~= "class" and col.key ~= "objectives" then
            btn:SetScript("OnClick", function()
                if ExiliumRBGDB.sortBy == col.key then
                    ExiliumRBGDB.sortDir = (ExiliumRBGDB.sortDir == "desc") and "asc" or "desc"
                else
                    ExiliumRBGDB.sortBy = col.key
                    ExiliumRBGDB.sortDir = "desc"
                end
                ExiliumRBG.ForceUpdate()
            end)
        end

        xOffset = xOffset + col.width
    end
end

-- --------------------------------------------------------------------------
-- Poblar filas para un equipo
-- --------------------------------------------------------------------------

local function PopulateTeamRows(team, startIndex, yOffset, parent, maxDamage)
    local visibleCols = GetVisibleColumns()

    for idx, player in ipairs(team) do
        local rowIdx = startIndex + idx
        if not rowPool[rowIdx] then
            rowPool[rowIdx] = CreateRow(parent, rowIdx)
        end
        local row = rowPool[rowIdx]
        row.playerData = player
        row.rowIndex = rowIdx

        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, yOffset)

        -- Fondo alternado
        local alpha = (idx % 2 == 0) and 0.1 or 0.05
        row:SetBackdropColor(0.1, 0.1, 0.1, alpha)

        -- Icono clase
        if ExiliumRBGDB.columns.class then
            GetClassIcon(player.classToken, row.classIcon)
            row.classIcon:Show()
        else
            row.classIcon:Hide()
        end

        -- Nombre coloreado
        if ExiliumRBGDB.columns.name then
            local colorCode = GetClassColor(player.classToken)
            local groupTag = ""
            if player.group == "attack" then
                groupTag = " |cffff4444[A]|r"
            elseif player.group == "defense" then
                groupTag = " |cff4444ff[D]|r"
            end
            row.nameText:SetText(colorCode .. player.name .. "|r" .. groupTag)
            row.nameText:Show()
        else
            row.nameText:Hide()
        end

        -- Barra de progreso
        if ExiliumRBGDB.showBars and maxDamage > 0 then
            local ratio = (player.damage or 0) / maxDamage
            row.bar:SetWidth(math.max(1, row:GetWidth() * ratio))
            row.bar:Show()
        else
            row.bar:Hide()
        end

        -- Estadísticas numéricas — posición basada en anchos acumulados de columna
        local statIdx = 0
        local accumulatedWidth = 0
        for _, col in ipairs(visibleCols) do
            if col.key == "class" or col.key == "name" then
                accumulatedWidth = accumulatedWidth + col.width
            else
                statIdx = statIdx + 1
                if not row.statTexts[statIdx] then
                    row.statTexts[statIdx] = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                end
                local st = row.statTexts[statIdx]
                st:ClearAllPoints()
                st:SetPoint("LEFT", row, "LEFT", accumulatedWidth + CELL_PADDING, 0)
                st:SetWidth(col.width - CELL_PADDING * 2)
                st:SetJustifyH("RIGHT")
                st:SetWordWrap(false)

                if col.key == "objectives" then
                    local objStr = ""
                    if type(player.objectives) == "table" then
                        for k, v in pairs(player.objectives) do
                            if objStr ~= "" then objStr = objStr .. ", " end
                            objStr = objStr .. tostring(v)
                        end
                    end
                    st:SetText(objStr ~= "" and objStr or "-")
                else
                    local val = player[col.key]
                    if type(val) == "number" then
                        st:SetText(FormatNumber(val))
                    else
                        st:SetText(tostring(val or "-"))
                    end
                end
                st:SetTextColor(0.9, 0.9, 0.9)
                st:Show()
                accumulatedWidth = accumulatedWidth + col.width
            end
        end

        -- Ocultar stats extra no usados
        for si = statIdx + 1, #row.statTexts do
            row.statTexts[si]:Hide()
        end

        row:Show()
        yOffset = yOffset - ROW_HEIGHT
    end

    return yOffset
end

-- --------------------------------------------------------------------------
-- Refresh principal de filas
-- --------------------------------------------------------------------------

function ExiliumRBG.RefreshRows()
    if not ExiliumRBG.MainFrame or not ExiliumRBG.MainFrame.leftPanel then return end

    local parent = ExiliumRBG.MainFrame.leftPanel

    -- Ocultar todas las filas
    for _, row in pairs(rowPool) do
        row:Hide()
    end

    CreateHeaders(parent)

    -- Calcular máximo daño para barras
    local maxDamage = 1
    for _, p in ipairs(ExiliumRBG.myTeam) do
        if p.damage and p.damage > maxDamage then maxDamage = p.damage end
    end
    for _, p in ipairs(ExiliumRBG.enemyTeam) do
        if p.damage and p.damage > maxDamage then maxDamage = p.damage end
    end

    local yOffset = -HEADER_HEIGHT - 4

    -- Mi equipo
    yOffset = PopulateTeamRows(ExiliumRBG.myTeam, 0, yOffset, parent, maxDamage)

    -- Separador visual
    yOffset = yOffset - 6
    if not parent.separator then
        parent.separator = parent:CreateTexture(nil, "ARTWORK")
        parent.separator:SetHeight(2)
        parent.separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    end
    parent.separator:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    parent.separator:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, yOffset)
    parent.separator:Show()
    yOffset = yOffset - 6

    -- Equipo enemigo
    yOffset = PopulateTeamRows(ExiliumRBG.enemyTeam, #ExiliumRBG.myTeam, yOffset, parent, maxDamage)
end
