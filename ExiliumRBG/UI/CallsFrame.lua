-- ==========================================================================
-- ExiliumRBG — UI/CallsFrame.lua
-- Panel de calls rápidas para Raid Leaders
-- ==========================================================================

local ADDON_PREFIX = "|cff00aaff[ExiliumRBG]|r "

local callsFrame = nil
local mapDropdown = nil
local customInput = nil

-- --------------------------------------------------------------------------
-- Enviar call según canal configurado
-- --------------------------------------------------------------------------

local function SendCall(callType, message)
    local channelConfig = ExiliumRBGDB.callChannels[callType] or "chat"

    -- Verificar permisos para RAID_WARNING
    local hasPermission = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")

    if channelConfig == "warning" or channelConfig == "both" then
        if hasPermission then
            SendChatMessage(message, "RAID_WARNING")
        else
            print(ADDON_PREFIX .. "No tienes permisos de asistente para RAID_WARNING.")
            SendChatMessage(message, "RAID")
        end
    end

    if channelConfig == "chat" or channelConfig == "both" then
        SendChatMessage(message, "RAID")
    end
end

-- --------------------------------------------------------------------------
-- Crear botón de call
-- --------------------------------------------------------------------------

local function CreateCallButton(parent, label, width, height, callType, messageFunc)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.2, 0.2, 0.3, 0.9)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(label)
    btn.label = text

    btn:SetScript("OnClick", function()
        local msg = messageFunc()
        if msg then
            SendCall(callType, msg)
        end
    end)
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.5, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.3, 0.9)
    end)

    return btn
end

-- --------------------------------------------------------------------------
-- Obtener base seleccionada del dropdown
-- --------------------------------------------------------------------------

local function GetSelectedBase()
    if mapDropdown and mapDropdown.selectedValue then
        return mapDropdown.selectedValue
    end
    local points = ExiliumRBG.GetCurrentMapPoints()
    return points[1] or "Base"
end

-- --------------------------------------------------------------------------
-- Crear el panel de calls
-- --------------------------------------------------------------------------

local function CreateCallsFrame()
    if not ExiliumRBG.MainFrame or not ExiliumRBG.MainFrame.rightPanel then return end

    local parent = ExiliumRBG.MainFrame.rightPanel

    callsFrame = CreateFrame("Frame", "ExiliumRBGCallsFrame", parent, "BackdropTemplate")
    callsFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -226)
    callsFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    callsFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    callsFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.9)

    -- Título
    local title = callsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", callsFrame, "TOPLEFT", 8, -6)
    title:SetText("|cff00aaffCalls Rápidas|r")

    -- ----- Dropdown de puntos del mapa -----
    mapDropdown = CreateFrame("Frame", "ExiliumRBGMapDropdown", callsFrame, "UIDropDownMenuTemplate")
    mapDropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -2)
    mapDropdown.selectedValue = nil

    UIDropDownMenu_SetWidth(mapDropdown, 100)
    UIDropDownMenu_SetText(mapDropdown, "Seleccionar base")

    UIDropDownMenu_Initialize(mapDropdown, function(self, level)
        local points = ExiliumRBG.GetCurrentMapPoints()
        for _, point in ipairs(points) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = point
            info.value = point
            info.func = function(selfItem)
                mapDropdown.selectedValue = selfItem.value
                UIDropDownMenu_SetText(mapDropdown, selfItem.value)
                CloseDropDownMenus()
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- ----- Botones de call predefinidas -----
    local btnWidth = 100
    local btnHeight = 28
    local spacing = 4
    local startY = -50

    -- Fila 1: Atacar / Defender
    local attackBtn = CreateCallButton(callsFrame, "|cffff4444ATACAR BASE|r", btnWidth, btnHeight,
        "base_attack", function()
            return "[ExiliumRBG] ATACAR: " .. GetSelectedBase()
        end)
    attackBtn:SetPoint("TOPLEFT", callsFrame, "TOPLEFT", 8, startY)

    local defendBtn = CreateCallButton(callsFrame, "|cff4444ffDEFENDER BASE|r", btnWidth, btnHeight,
        "base_defense", function()
            return "[ExiliumRBG] DEF: " .. GetSelectedBase()
        end)
    defendBtn:SetPoint("LEFT", attackBtn, "RIGHT", spacing, 0)

    -- Fila 2: INC / WIPE
    local incBtn = CreateCallButton(callsFrame, "|cffff0000INC|r", btnWidth, btnHeight,
        "inc", function()
            return "[ExiliumRBG] INC: " .. GetSelectedBase()
        end)
    incBtn:SetPoint("TOPLEFT", attackBtn, "BOTTOMLEFT", 0, -spacing)

    local wipeBtn = CreateCallButton(callsFrame, "|cffff8800WIPE|r", btnWidth, btnHeight,
        "wipe", function()
            return "[ExiliumRBG] WIPE — back to " .. GetSelectedBase()
        end)
    wipeBtn:SetPoint("LEFT", incBtn, "RIGHT", spacing, 0)

    -- Fila 3: GO / BACK
    local goBtn = CreateCallButton(callsFrame, "|cff00ff00GO GO GO|r", btnWidth, btnHeight,
        "go", function()
            return "[ExiliumRBG] GO " .. GetSelectedBase()
        end)
    goBtn:SetPoint("TOPLEFT", incBtn, "BOTTOMLEFT", 0, -spacing)

    local backBtn = CreateCallButton(callsFrame, "|cffaaaaaaBACK BACK|r", btnWidth, btnHeight,
        "back", function()
            return "[ExiliumRBG] BACK — regroup"
        end)
    backBtn:SetPoint("LEFT", goBtn, "RIGHT", spacing, 0)

    -- ----- Call personalizada -----
    local customLabel = callsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    customLabel:SetPoint("TOPLEFT", goBtn, "BOTTOMLEFT", 0, -10)
    customLabel:SetText("Call personalizada:")

    customInput = CreateFrame("EditBox", "ExiliumRBGCustomCallInput", callsFrame, "BackdropTemplate")
    customInput:SetSize(160, 22)
    customInput:SetPoint("TOPLEFT", customLabel, "BOTTOMLEFT", 0, -2)
    customInput:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    customInput:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    customInput:SetFontObject("GameFontNormalSmall")
    customInput:SetAutoFocus(false)
    customInput:SetMaxLetters(200)

    local sendCustomBtn = CreateCallButton(callsFrame, "Enviar", 50, 22,
        "custom", function()
            local text = customInput:GetText()
            if text and text ~= "" then
                customInput:SetText("")
                return "[ExiliumRBG] " .. text
            end
            print(ADDON_PREFIX .. "Escribe un mensaje primero.")
            return nil
        end)
    sendCustomBtn:SetPoint("LEFT", customInput, "RIGHT", 4, 0)

    -- ----- Verificación de permisos (aviso visual) -----
    local permWarning = callsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    permWarning:SetPoint("BOTTOMLEFT", callsFrame, "BOTTOMLEFT", 8, 6)
    permWarning:SetTextColor(0.6, 0.6, 0.6)
    callsFrame.permWarning = permWarning

    return callsFrame
end

-- --------------------------------------------------------------------------
-- Refresh
-- --------------------------------------------------------------------------

function ExiliumRBG.RefreshCallsFrame()
    if not callsFrame then
        CreateCallsFrame()
        if not callsFrame then return end
    end

    -- Actualizar aviso de permisos
    if callsFrame.permWarning then
        local hasPermission = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
        if hasPermission then
            callsFrame.permWarning:SetText("")
        else
            callsFrame.permWarning:SetText("Sin permisos de asistente (sin RW)")
        end
    end

    -- Actualizar dropdown con puntos del mapa actual
    if mapDropdown then
        UIDropDownMenu_Initialize(mapDropdown, function(self, level)
            local points = ExiliumRBG.GetCurrentMapPoints()
            for _, point in ipairs(points) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = point
                info.value = point
                info.func = function(selfItem)
                    mapDropdown.selectedValue = selfItem.value
                    UIDropDownMenu_SetText(mapDropdown, selfItem.value)
                    CloseDropDownMenus()
                end
                info.notCheckable = true
                UIDropDownMenu_AddButton(info)
            end
        end)
    end
end
