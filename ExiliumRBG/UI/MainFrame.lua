-- ==========================================================================
-- ExiliumRBG — UI/MainFrame.lua
-- Ventana principal del addon
-- ==========================================================================

local ADDON_PREFIX = "|cff00aaff[ExiliumRBG]|r "

-- --------------------------------------------------------------------------
-- Creación del frame principal
-- --------------------------------------------------------------------------

local function CreateMainFrame()
    local f = CreateFrame("Frame", "ExiliumRBGMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(680, 520)
    f:SetPoint("CENTER", UIParent, "CENTER", ExiliumRBGDB.position.x or 400, ExiliumRBGDB.position.y or 0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetResizable(true)
    f:SetScale(ExiliumRBGDB.scale or 1.0)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(10)

    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    local theme = ExiliumRBG.GetTheme()
    local bg = theme.bgColor
    f:SetBackdropColor(bg[1], bg[2], bg[3], ExiliumRBGDB.opacity or 0.92)
    local bc = theme.borderColor
    f:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4])

    -- Drag para mover
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        ExiliumRBGDB.position.x = x
        ExiliumRBGDB.position.y = y
    end)

    -- ----- Barra de título -----
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(28)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
    local tc = theme.titleColor
    titleText:SetTextColor(tc[1], tc[2], tc[3])
    titleText:SetText("ExiliumRBG v1.0")
    f.titleText = titleText

    -- Botón X (cerrar)
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Botón Config
    local configBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    configBtn:SetSize(60, 22)
    configBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    configBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    configBtn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    local configText = configBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    configText:SetPoint("CENTER")
    configText:SetText("Config")
    configBtn:SetScript("OnClick", function()
        if ExiliumRBG.ToggleConfigFrame then
            ExiliumRBG.ToggleConfigFrame()
        end
    end)
    configBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.5, 1)
    end)
    configBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    end)

    -- Botón Exportar
    local exportBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    exportBtn:SetSize(70, 22)
    exportBtn:SetPoint("RIGHT", configBtn, "LEFT", -4, 0)
    exportBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    exportBtn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    local exportText = exportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    exportText:SetPoint("CENTER")
    exportText:SetText("Exportar")
    exportBtn:SetScript("OnClick", function()
        if ExiliumRBG.ToggleExportFrame then
            ExiliumRBG.ToggleExportFrame()
        end
    end)
    exportBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.5, 1)
    end)
    exportBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    end)

    -- ----- Área de contenido: dos columnas -----
    -- Columna izquierda: estadísticas (Rows)
    local leftPanel = CreateFrame("Frame", nil, f)
    leftPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -4)
    leftPanel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
    leftPanel:SetWidth(420)
    f.leftPanel = leftPanel

    -- Columna derecha: grupos y calls
    local rightPanel = CreateFrame("Frame", nil, f)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0)
    rightPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
    f.rightPanel = rightPanel

    -- Oculto por defecto, se muestra al entrar en RBG
    f:Hide()

    return f
end

-- --------------------------------------------------------------------------
-- Inicializar
-- --------------------------------------------------------------------------

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    ExiliumRBG.MainFrame = CreateMainFrame()
    self:UnregisterEvent("PLAYER_LOGIN")
end)

-- --------------------------------------------------------------------------
-- Toggle y Refresh
-- --------------------------------------------------------------------------

function ExiliumRBG.ToggleMainFrame()
    if not ExiliumRBG.MainFrame then return end
    if ExiliumRBG.MainFrame:IsShown() then
        ExiliumRBG.MainFrame:Hide()
    else
        ExiliumRBG.MainFrame:Show()
        if ExiliumRBG.RefreshUI then
            ExiliumRBG.RefreshUI()
        end
    end
end

function ExiliumRBG.RefreshUI()
    -- Llamar refresh de cada sub-módulo si existe
    if ExiliumRBG.RefreshRows then
        ExiliumRBG.RefreshRows()
    end
    if ExiliumRBG.RefreshGroupFrame then
        ExiliumRBG.RefreshGroupFrame()
    end
    if ExiliumRBG.RefreshCallsFrame then
        ExiliumRBG.RefreshCallsFrame()
    end
end
