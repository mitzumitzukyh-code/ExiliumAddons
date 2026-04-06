-- ==========================================================================
-- ExiliumRBG — UI/GroupFrame.lua
-- Gestión de grupos Ataque / Defensa
-- ==========================================================================

local ADDON_PREFIX = "|cff00aaff[ExiliumRBG]|r "

local groupFrame = nil
local attackList = {}
local defenseList = {}

-- --------------------------------------------------------------------------
-- Crear el panel de grupos (incrustado en rightPanel del MainFrame)
-- --------------------------------------------------------------------------

local function CreateGroupFrame()
    if not ExiliumRBG.MainFrame or not ExiliumRBG.MainFrame.rightPanel then return end

    local parent = ExiliumRBG.MainFrame.rightPanel

    groupFrame = CreateFrame("Frame", "ExiliumRBGGroupFrame", parent, "BackdropTemplate")
    groupFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    groupFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    groupFrame:SetHeight(220)

    groupFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    groupFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.9)

    -- ----- Columna Ataque -----
    local attackHeader = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    attackHeader:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 8, -8)
    attackHeader:SetText("|cffff4444ATAQUE|r")
    groupFrame.attackHeader = attackHeader

    local attackPanel = CreateFrame("Frame", nil, groupFrame, "BackdropTemplate")
    attackPanel:SetPoint("TOPLEFT", attackHeader, "BOTTOMLEFT", 0, -4)
    attackPanel:SetSize(105, 150)
    local theme = ExiliumRBG.GetTheme()
    local aBg = theme.attackBg
    attackPanel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
    attackPanel:SetBackdropColor(aBg[1], aBg[2], aBg[3], aBg[4])
    groupFrame.attackPanel = attackPanel

    -- ----- Columna Defensa -----
    local defenseHeader = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    defenseHeader:SetPoint("TOPLEFT", groupFrame, "TOP", 8, -8)
    defenseHeader:SetText("|cff4444ffDEFENSA|r")
    groupFrame.defenseHeader = defenseHeader

    local defensePanel = CreateFrame("Frame", nil, groupFrame, "BackdropTemplate")
    defensePanel:SetPoint("TOPLEFT", defenseHeader, "BOTTOMLEFT", 0, -4)
    defensePanel:SetSize(105, 150)
    local dBg = theme.defenseBg
    defensePanel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
    defensePanel:SetBackdropColor(dBg[1], dBg[2], dBg[3], dBg[4])
    groupFrame.defensePanel = defensePanel

    -- ----- Botón Anunciar al raid -----
    local announceBtn = CreateFrame("Button", nil, groupFrame, "BackdropTemplate")
    announceBtn:SetSize(210, 22)
    announceBtn:SetPoint("BOTTOMLEFT", groupFrame, "BOTTOMLEFT", 8, 8)
    announceBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    announceBtn:SetBackdropColor(0.15, 0.4, 0.15, 0.9)
    local announceText = announceBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    announceText:SetPoint("CENTER")
    announceText:SetText("Anunciar grupos al raid")
    announceBtn:SetScript("OnClick", function()
        ExiliumRBG.AnnounceGroups()
    end)
    announceBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.5, 0.2, 1)
    end)
    announceBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.4, 0.15, 0.9)
    end)

    return groupFrame
end

-- --------------------------------------------------------------------------
-- Crear fila de miembro en un panel de grupo
-- --------------------------------------------------------------------------

local function CreateMemberRow(parent, index, playerData, groupType)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4 - (index - 1) * 20)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4 - (index - 1) * 20)
    row:EnableMouse(true)

    -- Icono clase
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    GetClassIcon(playerData.classToken, icon)

    -- Nombre
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    local colorCode = GetClassColor(playerData.classToken)
    nameText:SetText(colorCode .. playerData.name .. "|r")

    -- Click derecho → quitar de grupo
    row:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            ExiliumRBG.AssignGroup(playerData.name, nil)
        end
    end)

    -- Drag support
    row:SetMovable(true)
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self.isDragging = true
        self.dragPlayer = playerData.name
        self.dragFromGroup = groupType
    end)
    row:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.isDragging = false
        -- Detectar si soltó sobre el otro panel
        if self.dragFromGroup == "attack" and groupFrame.defensePanel then
            if groupFrame.defensePanel:IsMouseOver() then
                ExiliumRBG.AssignGroup(self.dragPlayer, "defense")
            end
        elseif self.dragFromGroup == "defense" and groupFrame.attackPanel then
            if groupFrame.attackPanel:IsMouseOver() then
                ExiliumRBG.AssignGroup(self.dragPlayer, "attack")
            end
        end
        -- Re-anclar la fila
        ExiliumRBG.RefreshGroupFrame()
    end)

    return row
end

-- --------------------------------------------------------------------------
-- Refresh del panel de grupos
-- --------------------------------------------------------------------------

function ExiliumRBG.RefreshGroupFrame()
    if not groupFrame then
        CreateGroupFrame()
        if not groupFrame then return end
    end

    -- Limpiar filas anteriores
    for _, row in ipairs(attackList) do row:Hide() end
    for _, row in ipairs(defenseList) do row:Hide() end
    attackList = {}
    defenseList = {}

    -- Poblar Ataque
    local attackMembers = ExiliumRBG.GetGroupMembers("attack")
    for i, player in ipairs(attackMembers) do
        local row = CreateMemberRow(groupFrame.attackPanel, i, player, "attack")
        table.insert(attackList, row)
    end

    -- Poblar Defensa
    local defenseMembers = ExiliumRBG.GetGroupMembers("defense")
    for i, player in ipairs(defenseMembers) do
        local row = CreateMemberRow(groupFrame.defensePanel, i, player, "defense")
        table.insert(defenseList, row)
    end
end

-- --------------------------------------------------------------------------
-- Anunciar grupos al raid
-- --------------------------------------------------------------------------

function ExiliumRBG.AnnounceGroups()
    local attackMembers = ExiliumRBG.GetGroupMembers("attack")
    local defenseMembers = ExiliumRBG.GetGroupMembers("defense")

    if #attackMembers == 0 and #defenseMembers == 0 then
        print(ADDON_PREFIX .. "No hay grupos asignados.")
        return
    end

    -- Verificar permisos
    local hasPermission = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")

    local channel = hasPermission and "RAID_WARNING" or "RAID"

    if #attackMembers > 0 then
        local names = {}
        for _, p in ipairs(attackMembers) do
            table.insert(names, p.name)
        end
        SendChatMessage("[ExiliumRBG] ATAQUE: " .. table.concat(names, ", "), channel)
    end

    if #defenseMembers > 0 then
        local names = {}
        for _, p in ipairs(defenseMembers) do
            table.insert(names, p.name)
        end
        SendChatMessage("[ExiliumRBG] DEFENSA: " .. table.concat(names, ", "), channel)
    end
end
