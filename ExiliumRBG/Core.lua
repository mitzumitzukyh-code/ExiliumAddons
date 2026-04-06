-- ==========================================================================
-- ExiliumRBG — Core.lua
-- Bootstrap del addon, eventos principales y slash commands
-- ==========================================================================

ExiliumRBG = {}
ExiliumRBGDB = ExiliumRBGDB or {}

local ADDON_PREFIX = "|cff00aaff[ExiliumRBG]|r "

-- Defaults para SavedVariables
local DEFAULTS = {
    position = { x = 400, y = 0 },
    scale = 1.0,
    visible = true,
    theme = "dark",
    opacity = 0.92,
    fontSize = 12,
    showBars = true,
    columns = {
        class = true,
        name = true,
        damage = true,
        healing = true,
        deaths = true,
        kb = true,
        honor = false,
        objectives = true,
    },
    sortBy = "damage",
    sortDir = "desc",
    groups = {},
    callChannels = {
        base_attack = "both",
        base_defense = "chat",
        inc = "warning",
        wipe = "both",
        go = "both",
        back = "chat",
        player_move = "chat",
        custom = "chat",
    },
}

-- Timestamp de inicio del BG (usado por ExportFrame)
ExiliumRBG.bgStartTime = nil

-- --------------------------------------------------------------------------
-- Utilidades globales
-- --------------------------------------------------------------------------

function FormatNumber(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(n)
    end
end

function GetClassColor(classToken)
    local color = RAID_CLASS_COLORS[classToken]
    if color then
        return string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
    end
    return "|cffffffff"
end

function GetClassIcon(classToken, textureObject)
    textureObject:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes")
    local coords = CLASS_ICON_TCOORDS[classToken]
    if coords then
        textureObject:SetTexCoord(unpack(coords))
    else
        textureObject:SetTexCoord(0, 1, 0, 1)
    end
end

-- --------------------------------------------------------------------------
-- Sistema de temas
-- --------------------------------------------------------------------------

ExiliumRBG.Themes = {
    dark = {
        bgColor      = { 0.05, 0.05, 0.15 },
        borderColor  = { 0, 0.6, 1, 0.8 },
        titleColor   = { 0, 0.7, 1 },
        headerColor  = { 1, 1, 0 },
        attackBg     = { 0.4, 0.05, 0.05, 0.3 },
        defenseBg    = { 0.05, 0.05, 0.4, 0.3 },
    },
    neon = {
        bgColor      = { 0, 0, 0 },
        borderColor  = { 0, 1, 0.8, 1 },
        titleColor   = { 0, 1, 0.8 },
        headerColor  = { 0, 1, 0.5 },
        attackBg     = { 0.5, 0, 0, 0.4 },
        defenseBg    = { 0, 0, 0.5, 0.4 },
    },
    gold = {
        bgColor      = { 0.1, 0.08, 0.02 },
        borderColor  = { 1, 0.8, 0, 0.9 },
        titleColor   = { 1, 0.8, 0 },
        headerColor  = { 1, 1, 0.5 },
        attackBg     = { 0.4, 0.1, 0, 0.3 },
        defenseBg    = { 0, 0.1, 0.4, 0.3 },
    },
}

function ExiliumRBG.GetTheme()
    local themeName = ExiliumRBGDB.theme or "dark"
    return ExiliumRBG.Themes[themeName] or ExiliumRBG.Themes.dark
end

function ExiliumRBG.ApplyTheme()
    local theme = ExiliumRBG.GetTheme()

    if ExiliumRBG.MainFrame then
        local bg = theme.bgColor
        ExiliumRBG.MainFrame:SetBackdropColor(bg[1], bg[2], bg[3], ExiliumRBGDB.opacity or 0.92)
        local bc = theme.borderColor
        ExiliumRBG.MainFrame:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4])
    end

    if ExiliumRBG.RefreshUI then
        ExiliumRBG.RefreshUI()
    end
end

-- --------------------------------------------------------------------------
-- Minimap Button
-- --------------------------------------------------------------------------

local minimapBtn = nil
local MINIMAP_RADIUS = 104
local DEFAULT_MINIMAP_ANGLE = 225

local function UpdateMinimapPos()
    if not minimapBtn then return end
    local angle = ExiliumRBGDB.minimapAngle or math.rad(DEFAULT_MINIMAP_ANGLE)
    local x = math.cos(angle) * MINIMAP_RADIUS
    local y = math.sin(angle) * MINIMAP_RADIUS
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    minimapBtn = CreateFrame("Button", "ExiliumRBGMinimapBtn", Minimap)
    minimapBtn:SetSize(32, 32)
    minimapBtn:SetFrameStrata("HIGH")
    minimapBtn:SetFrameLevel(10)

    -- Textura del botón (espadas cruzadas PvP)
    local tex = minimapBtn:CreateTexture(nil, "ARTWORK")
    tex:SetTexture("Interface\\Icons\\Achievement_PVP_H_A")
    tex:SetSize(24, 24)
    tex:SetPoint("CENTER", 0, 0)
    tex:SetTexCoord(0.05, 0.95, 0.05, 0.95)  -- recortar borde del ícono

    -- Borde circular
    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(56, 56)
    border:SetPoint("CENTER", 10, -10)

    -- Highlight
    local highlight = minimapBtn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetAllPoints()
    highlight:SetBlendMode("ADD")

    -- Click izquierdo → toggle ventana principal
    minimapBtn:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            if ExiliumRBG.ToggleMainFrame then
                ExiliumRBG.ToggleMainFrame()
            end
        end
    end)
    minimapBtn:RegisterForClicks("LeftButtonUp")

    -- Drag para mover alrededor del minimapa
    minimapBtn:RegisterForDrag("LeftButton")
    minimapBtn:SetScript("OnDragStart", function(self)
        self.dragging = true
    end)
    minimapBtn:SetScript("OnDragStop", function(self)
        self.dragging = false
    end)
    minimapBtn:SetScript("OnUpdate", function(self)
        if self.dragging then
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.atan2(cy - my, cx - mx)
            ExiliumRBGDB.minimapAngle = angle
            UpdateMinimapPos()
        end
    end)

    -- Tooltip al hover
    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ExiliumRBG", 0, 0.7, 1)
        GameTooltip:AddLine("Click: Mostrar/Ocultar", 1, 1, 1)
        GameTooltip:AddLine("Drag: Mover botón", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Default angle si no hay guardado
    if not ExiliumRBGDB.minimapAngle then
        ExiliumRBGDB.minimapAngle = math.rad(DEFAULT_MINIMAP_ANGLE)
    end

    UpdateMinimapPos()
end

-- --------------------------------------------------------------------------
-- Inicialización de defaults
-- --------------------------------------------------------------------------

local function InitDefaults()
    for k, v in pairs(DEFAULTS) do
        if ExiliumRBGDB[k] == nil then
            if type(v) == "table" then
                ExiliumRBGDB[k] = {}
                for kk, vv in pairs(v) do
                    ExiliumRBGDB[k][kk] = vv
                end
            else
                ExiliumRBGDB[k] = v
            end
        end
    end
    -- Asegurarse de que sub-tablas también tienen sus defaults
    if DEFAULTS.columns then
        for k, v in pairs(DEFAULTS.columns) do
            if ExiliumRBGDB.columns[k] == nil then
                ExiliumRBGDB.columns[k] = v
            end
        end
    end
    if DEFAULTS.callChannels then
        for k, v in pairs(DEFAULTS.callChannels) do
            if ExiliumRBGDB.callChannels[k] == nil then
                ExiliumRBGDB.callChannels[k] = v
            end
        end
    end
end

-- --------------------------------------------------------------------------
-- Detección de RBG
-- --------------------------------------------------------------------------

function ExiliumRBG.IsInRatedBG()
    if C_PvP and C_PvP.IsRatedBattleground then
        local ok, result = pcall(C_PvP.IsRatedBattleground)
        if ok and result then
            return true
        end
    end
    return false
end

-- --------------------------------------------------------------------------
-- Eventos
-- --------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "ExiliumRBG" then
            InitDefaults()
            CreateMinimapButton()
            print(ADDON_PREFIX .. "v1.0.0 cargado. Usa /erbg para abrir.")
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if ExiliumRBG.IsInRatedBG() then
            -- Entrar a RBG: mostrar y resetear
            ExiliumRBG.bgStartTime = time()
            ExiliumRBGDB.groups = {}
            if ExiliumRBG.ResetData then
                ExiliumRBG.ResetData()
            end
            if ExiliumRBG.MainFrame then
                ExiliumRBG.MainFrame:Show()
            end
            if ExiliumRBG.RefreshUI then
                ExiliumRBG.RefreshUI()
            end
            print(ADDON_PREFIX .. "Rated Battleground detectado. Addon activo.")
        else
            -- No está en RBG: ocultar
            if ExiliumRBG.MainFrame and ExiliumRBG.MainFrame:IsShown() then
                ExiliumRBG.MainFrame:Hide()
            end
        end

    elseif event == "PLAYER_LEAVING_WORLD" then
        -- Guardar posición al salir
        if ExiliumRBG.MainFrame then
            local point, _, _, x, y = ExiliumRBG.MainFrame:GetPoint()
            if x and y then
                ExiliumRBGDB.position.x = x
                ExiliumRBGDB.position.y = y
            end
        end
    end
end)

-- --------------------------------------------------------------------------
-- Slash Commands
-- --------------------------------------------------------------------------

SLASH_EXILIUMRBG1 = "/exiliumrbg"
SLASH_EXILIUMRBG2 = "/erbg"

SlashCmdList["EXILIUMRBG"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "config" then
        if ExiliumRBG.ToggleConfigFrame then
            ExiliumRBG.ToggleConfigFrame()
        end
    elseif msg == "export" then
        if ExiliumRBG.ToggleExportFrame then
            ExiliumRBG.ToggleExportFrame()
        end
    else
        if ExiliumRBG.ToggleMainFrame then
            ExiliumRBG.ToggleMainFrame()
        end
    end
end
