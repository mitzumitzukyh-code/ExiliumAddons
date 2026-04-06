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

local CALLS_PADDING = 10
local CALL_BTN_H    = 32
local CALL_BTN_GAP  = 6
local CUSTOM_INPUT_H = 24

local function CreateCallsFrame()
    if not ExiliumRBG.MainFrame or not ExiliumRBG.MainFrame.rightPanel then return end

    local parent = ExiliumRBG.MainFrame.rightPanel

    callsFrame = CreateFrame("Frame", "ExiliumRBGCallsFrame", parent, "BackdropTemplate")
    callsFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -260)
    callsFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    callsFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 10,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    callsFrame:SetBackdropColor(0.06, 0.06, 0.10, 0.95)

    -- Título
    local title = callsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", callsFrame, "TOPLEFT", CALLS_PADDING, -CALLS_PADDING)
    title:SetText("|cff00aaffCalls Rápidas|r")

    -- ----- Dropdown de puntos del mapa -----
    mapDropdown = CreateFrame("Frame", "ExiliumRBGMapDropdown", callsFrame, "UIDropDownMenuTemplate")
    mapDropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -2)
    mapDropdown.selectedValue = nil

    UIDropDownMenu_SetWidth(mapDropdown, 110)
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

    -- ----- Botones de call predefinidas — Grilla 2x3 -----
    local gridLeft = CALLS_PADDING
    local gridTop  = -54
    local availW   = 220  -- approximate usable width for 2 columns
    local btnWidth = math.floor((availW - CALL_BTN_GAP) / 2)

    -- Fila 1: Atacar / Defender
    local attackBtn = CreateCallButton(callsFrame, "|cffff4444ATACAR|r", btnWidth, CALL_BTN_H,
        "base_attack", function()
            return "[ExiliumRBG] ATACAR: " .. GetSelectedBase()
        end)
    attackBtn:SetPoint("TOPLEFT", callsFrame, "TOPLEFT", gridLeft, gridTop)

    local defendBtn = CreateCallButton(callsFrame, "|cff4444ffDEFENDER|r", btnWidth, CALL_BTN_H,
        "base_defense", function()
            return "[ExiliumRBG] DEF: " .. GetSelectedBase()
        end)
    defendBtn:SetPoint("LEFT", attackBtn, "RIGHT", CALL_BTN_GAP, 0)

    -- Fila 2: INC / WIPE
    local incBtn = CreateCallButton(callsFrame, "|cffff0000INC|r", btnWidth, CALL_BTN_H,
        "inc", function()
            return "[ExiliumRBG] INC: " .. GetSelectedBase()
        end)
    incBtn:SetPoint("TOPLEFT", attackBtn, "BOTTOMLEFT", 0, -CALL_BTN_GAP)

    local wipeBtn = CreateCallButton(callsFrame, "|cffff8800WIPE|r", btnWidth, CALL_BTN_H,
        "wipe", function()
            return "[ExiliumRBG] WIPE — back to " .. GetSelectedBase()
        end)
    wipeBtn:SetPoint("LEFT", incBtn, "RIGHT", CALL_BTN_GAP, 0)

    -- Fila 3: GO / BACK
    local goBtn = CreateCallButton(callsFrame, "|cff00ff00GO GO GO|r", btnWidth, CALL_BTN_H,
        "go", function()
            return "[ExiliumRBG] GO " .. GetSelectedBase()
        end)
    goBtn:SetPoint("TOPLEFT", incBtn, "BOTTOMLEFT", 0, -CALL_BTN_GAP)

    local backBtn = CreateCallButton(callsFrame, "|cffaaaaaaBACK|r", btnWidth, CALL_BTN_H,
        "back", function()
            return "[ExiliumRBG] BACK — regroup"
        end)
    backBtn:SetPoint("LEFT", goBtn, "RIGHT", CALL_BTN_GAP, 0)

    -- ----- Divider antes de call personalizada -----
    local customDiv = callsFrame:CreateTexture(nil, "ARTWORK")
    customDiv:SetHeight(1)
    customDiv:SetPoint("TOPLEFT", goBtn, "BOTTOMLEFT", 0, -CALLS_PADDING)
    customDiv:SetPoint("TOPRIGHT", backBtn, "BOTTOMRIGHT", 0, -CALLS_PADDING)
    customDiv:SetColorTexture(0.3, 0.5, 0.8, 0.4)

    -- ----- Call personalizada -----
    local customLabel = callsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    customLabel:SetPoint("TOPLEFT", customDiv, "BOTTOMLEFT", 0, -6)
    customLabel:SetText("Call personalizada:")

    customInput = CreateFrame("EditBox", "ExiliumRBGCustomCallInput", callsFrame, "BackdropTemplate")
    customInput:SetSize(160, CUSTOM_INPUT_H)
    customInput:SetPoint("TOPLEFT", customLabel, "BOTTOMLEFT", 0, -4)
    customInput:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 4, right = 4, top = 2, bottom = 2 },
    })
    customInput:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    customInput:SetFontObject("GameFontNormalSmall")
    customInput:SetAutoFocus(false)
    customInput:SetMaxLetters(200)
    customInput:SetTextInsets(4, 4, 0, 0)

    local sendCustomBtn = CreateCallButton(callsFrame, "Enviar", 56, CUSTOM_INPUT_H,
        "custom", function()
            local text = customInput:GetText()
            if text and text ~= "" then
                customInput:SetText("")
                return "[ExiliumRBG] " .. text
            end
            print(ADDON_PREFIX .. "Escribe un mensaje primero.")
            return nil
        end)
    sendCustomBtn:SetPoint("LEFT", customInput, "RIGHT", CALL_BTN_GAP, 0)

    -- ----- Verificación de permisos (aviso visual) -----
    local permWarning = callsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    permWarning:SetPoint("BOTTOMLEFT", callsFrame, "BOTTOMLEFT", CALLS_PADDING, 6)
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
