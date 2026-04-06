-- ==========================================================================
-- ExiliumRBG — UI/ConfigFrame.lua
-- Panel de configuración del addon
-- ==========================================================================

local ADDON_PREFIX = "|cff00aaff[ExiliumRBG]|r "

local configFrame = nil

-- Defaults para restaurar
local DEFAULTS = {
    position = { x = 400, y = 0 },
    scale = 1.0,
    visible = true,
    theme = "dark",
    opacity = 0.92,
    fontSize = 12,
    showBars = true,
    columns = {
        class = true, name = true, damage = true, healing = true,
        deaths = true, kb = true, honor = false, objectives = true,
    },
    sortBy = "damage",
    sortDir = "desc",
}

-- --------------------------------------------------------------------------
-- Crear slider genérico
-- --------------------------------------------------------------------------

local function CreateSlider(parent, label, minVal, maxVal, step, defaultVal, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 40)

    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    text:SetText(label)

    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -4)
    slider:SetSize(180, 16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(defaultVal)

    local valText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    valText:SetText(tostring(defaultVal))

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        valText:SetText(string.format("%.2f", value))
        if onChange then onChange(value) end
    end)

    container.slider = slider
    container.valText = valText
    return container
end

-- --------------------------------------------------------------------------
-- Crear checkbox genérico
-- --------------------------------------------------------------------------

local function CreateCheckbox(parent, label, defaultChecked, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetChecked(defaultChecked)

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label)

    cb:SetScript("OnClick", function(self)
        if onChange then onChange(self:GetChecked()) end
    end)

    return cb
end

-- --------------------------------------------------------------------------
-- Crear radio button genérico
-- --------------------------------------------------------------------------

local function CreateRadioButton(parent, label, groupName, value, isSelected, onChange)
    local rb = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    rb:SetSize(20, 20)
    rb:SetChecked(isSelected)

    local text = rb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", rb, "RIGHT", 4, 0)
    text:SetText(label)

    rb.groupName = groupName
    rb.value = value

    rb:SetScript("OnClick", function(self)
        if onChange then onChange(value) end
    end)

    return rb
end

-- --------------------------------------------------------------------------
-- Crear el frame de configuración
-- --------------------------------------------------------------------------

local function CreateConfigFrame()
    configFrame = CreateFrame("Frame", "ExiliumRBGConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(420, 480)
    configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    configFrame:SetClampedToScreen(true)
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:SetFrameStrata("DIALOG")

    configFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local theme = ExiliumRBG.GetTheme()
    local bg = theme.bgColor
    configFrame:SetBackdropColor(bg[1], bg[2], bg[3], 0.95)
    local bc = theme.borderColor
    configFrame:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4])

    -- Drag
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    configFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Título
    local titleText = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, -10)
    titleText:SetText("|cff00aaffExiliumRBG — Configuración|r")

    -- Botón X
    local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)

    local yOff = -40

    -- ===================== SECCIÓN 1: VENTANA =====================
    local secVentana = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    secVentana:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    secVentana:SetText("|cffffd700VENTANA|r")
    yOff = yOff - 20

    -- Slider escala
    local scaleSlider = CreateSlider(configFrame, "Escala", 0.75, 1.5, 0.05,
        ExiliumRBGDB.scale or 1.0, function(val)
            ExiliumRBGDB.scale = val
            if ExiliumRBG.MainFrame then
                ExiliumRBG.MainFrame:SetScale(val)
            end
        end)
    scaleSlider:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    yOff = yOff - 50

    -- Botón reset posición
    local resetPosBtn = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
    resetPosBtn:SetSize(120, 22)
    resetPosBtn:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    resetPosBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    resetPosBtn:SetBackdropColor(0.3, 0.15, 0.15, 0.9)
    local resetPosText = resetPosBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetPosText:SetPoint("CENTER")
    resetPosText:SetText("Reset posición")
    resetPosBtn:SetScript("OnClick", function()
        ExiliumRBGDB.position = { x = 400, y = 0 }
        if ExiliumRBG.MainFrame then
            ExiliumRBG.MainFrame:ClearAllPoints()
            ExiliumRBG.MainFrame:SetPoint("CENTER", UIParent, "CENTER", 400, 0)
        end
    end)
    yOff = yOff - 32

    -- ===================== SECCIÓN 2: VISUAL =====================
    local secVisual = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    secVisual:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    secVisual:SetText("|cffffd700VISUAL|r")
    yOff = yOff - 20

    -- Radio tema: dark / neon / gold
    local themeRadios = {}
    local themes = { { "dark", "Dark" }, { "neon", "Neon" }, { "gold", "Gold" } }
    local themeXOff = 12
    for _, t in ipairs(themes) do
        local rb = CreateRadioButton(configFrame, t[2], "theme", t[1],
            (ExiliumRBGDB.theme == t[1]), function(val)
                ExiliumRBGDB.theme = val
                -- Deseleccionar otros radios
                for _, other in ipairs(themeRadios) do
                    other:SetChecked(other.value == val)
                end
                ExiliumRBG.ApplyTheme()
            end)
        rb:SetPoint("TOPLEFT", configFrame, "TOPLEFT", themeXOff, yOff)
        table.insert(themeRadios, rb)
        themeXOff = themeXOff + 80
    end
    yOff = yOff - 28

    -- Slider opacidad
    local opacitySlider = CreateSlider(configFrame, "Opacidad", 0.5, 1.0, 0.02,
        ExiliumRBGDB.opacity or 0.92, function(val)
            ExiliumRBGDB.opacity = val
            if ExiliumRBG.MainFrame then
                local themeBg = ExiliumRBG.GetTheme().bgColor
                ExiliumRBG.MainFrame:SetBackdropColor(themeBg[1], themeBg[2], themeBg[3], val)
            end
        end)
    opacitySlider:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    yOff = yOff - 50

    -- Slider fuente
    local fontSlider = CreateSlider(configFrame, "Tamaño fuente", 9, 18, 1,
        ExiliumRBGDB.fontSize or 12, function(val)
            ExiliumRBGDB.fontSize = val
        end)
    fontSlider:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    yOff = yOff - 50

    -- Checkbox barras
    local barsCb = CreateCheckbox(configFrame, "Mostrar barras de progreso",
        ExiliumRBGDB.showBars, function(checked)
            ExiliumRBGDB.showBars = checked
            if ExiliumRBG.RefreshUI then ExiliumRBG.RefreshUI() end
        end)
    barsCb:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    yOff = yOff - 28

    -- ===================== SECCIÓN 3: COLUMNAS =====================
    local secCols = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    secCols:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    secCols:SetText("|cffffd700COLUMNAS|r")
    yOff = yOff - 20

    local columnDefs = {
        { key = "class",      label = "Icono clase" },
        { key = "name",       label = "Nombre" },
        { key = "damage",     label = "Daño" },
        { key = "healing",    label = "Sanación" },
        { key = "deaths",     label = "Muertes" },
        { key = "kb",         label = "KB" },
        { key = "honor",      label = "Honor" },
        { key = "objectives", label = "Objetivos" },
    }

    local colXOff = 12
    local colCount = 0
    for _, col in ipairs(columnDefs) do
        local cb = CreateCheckbox(configFrame, col.label,
            ExiliumRBGDB.columns[col.key], function(checked)
                ExiliumRBGDB.columns[col.key] = checked
                if ExiliumRBG.RefreshUI then ExiliumRBG.RefreshUI() end
            end)
        cb:SetPoint("TOPLEFT", configFrame, "TOPLEFT", colXOff, yOff)
        colCount = colCount + 1
        colXOff = colXOff + 100
        if colCount % 4 == 0 then
            colXOff = 12
            yOff = yOff - 24
        end
    end
    if colCount % 4 ~= 0 then yOff = yOff - 24 end
    yOff = yOff - 8

    -- ===================== SECCIÓN 4: ORDENACIÓN =====================
    local secSort = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    secSort:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 12, yOff)
    secSort:SetText("|cffffd700ORDENACIÓN|r")
    yOff = yOff - 20

    -- Radio sortBy
    local sortByOptions = { "damage", "healing", "deaths", "kb", "hk", "honorGained" }
    local sortByRadios = {}
    local sortXOff = 12
    local sortCount = 0
    for _, opt in ipairs(sortByOptions) do
        local rb = CreateRadioButton(configFrame, opt, "sortBy", opt,
            (ExiliumRBGDB.sortBy == opt), function(val)
                ExiliumRBGDB.sortBy = val
                for _, other in ipairs(sortByRadios) do
                    other:SetChecked(other.value == val)
                end
                ExiliumRBG.ForceUpdate()
            end)
        rb:SetPoint("TOPLEFT", configFrame, "TOPLEFT", sortXOff, yOff)
        table.insert(sortByRadios, rb)
        sortXOff = sortXOff + 100
        sortCount = sortCount + 1
        if sortCount % 4 == 0 then
            sortXOff = 12
            yOff = yOff - 24
        end
    end
    if sortCount % 4 ~= 0 then yOff = yOff - 24 end
    yOff = yOff - 4

    -- Radio sortDir
    local sortDirRadios = {}
    local dirOptions = { { "desc", "Descendente" }, { "asc", "Ascendente" } }
    local dirXOff = 12
    for _, d in ipairs(dirOptions) do
        local rb = CreateRadioButton(configFrame, d[2], "sortDir", d[1],
            (ExiliumRBGDB.sortDir == d[1]), function(val)
                ExiliumRBGDB.sortDir = val
                for _, other in ipairs(sortDirRadios) do
                    other:SetChecked(other.value == val)
                end
                ExiliumRBG.ForceUpdate()
            end)
        rb:SetPoint("TOPLEFT", configFrame, "TOPLEFT", dirXOff, yOff)
        table.insert(sortDirRadios, rb)
        dirXOff = dirXOff + 130
    end

    -- ===================== BOTONES INFERIORES =====================

    -- Botón Restaurar defaults
    local defaultsBtn = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
    defaultsBtn:SetSize(130, 26)
    defaultsBtn:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 12, 10)
    defaultsBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    defaultsBtn:SetBackdropColor(0.4, 0.15, 0.15, 0.9)
    local defaultsBtnText = defaultsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    defaultsBtnText:SetPoint("CENTER")
    defaultsBtnText:SetText("Restaurar defaults")
    defaultsBtn:SetScript("OnClick", function()
        for k, v in pairs(DEFAULTS) do
            if type(v) == "table" then
                ExiliumRBGDB[k] = {}
                for kk, vv in pairs(v) do
                    ExiliumRBGDB[k][kk] = vv
                end
            else
                ExiliumRBGDB[k] = v
            end
        end
        ExiliumRBG.ApplyTheme()
        configFrame:Hide()
        print(ADDON_PREFIX .. "Configuración restaurada a valores por defecto.")
    end)

    -- Botón Cerrar (Cancelar)
    local cancelBtn = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
    cancelBtn:SetSize(80, 26)
    cancelBtn:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -12, 10)
    cancelBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    cancelBtn:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
    local cancelBtnText = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cancelBtnText:SetPoint("CENTER")
    cancelBtnText:SetText("Cancelar")
    cancelBtn:SetScript("OnClick", function()
        configFrame:Hide()
    end)

    -- Botón Guardar
    local saveBtn = CreateFrame("Button", nil, configFrame, "BackdropTemplate")
    saveBtn:SetSize(80, 26)
    saveBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -8, 0)
    saveBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    saveBtn:SetBackdropColor(0.15, 0.4, 0.15, 0.9)
    local saveBtnText = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    saveBtnText:SetPoint("CENTER")
    saveBtnText:SetText("Guardar")
    saveBtn:SetScript("OnClick", function()
        ExiliumRBG.ApplyTheme()
        if ExiliumRBG.RefreshUI then ExiliumRBG.RefreshUI() end
        configFrame:Hide()
        print(ADDON_PREFIX .. "Configuración guardada.")
    end)

    configFrame:Hide()
    return configFrame
end

-- --------------------------------------------------------------------------
-- Toggle
-- --------------------------------------------------------------------------

function ExiliumRBG.ToggleConfigFrame()
    if not configFrame then
        CreateConfigFrame()
    end

    if configFrame:IsShown() then
        configFrame:Hide()
    else
        configFrame:Show()
    end
end
