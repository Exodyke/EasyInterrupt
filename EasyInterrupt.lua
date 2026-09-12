EasyInterruptDB = EasyInterruptDB or {
    enabled = true,
    soundEnabled = true,
    soundFile = "Sound\\Interface\\RaidWarning.wav",
    ignoreListStr = ""
}

Config = Config or {}
Config.interruptAnnounce = EasyInterruptDB.enabled

local ignoredSpellIDs = {}
local function ParseIgnoreList()
    ignoredSpellIDs = {}
    for id in string.gmatch(EasyInterruptDB.ignoreListStr, "([^,]+)") do
        local num = tonumber(string.trim(id))
        if num then
            ignoredSpellIDs[num] = true
        end
    end
end

local loaderFrame = CreateFrame("Frame")
loaderFrame:RegisterEvent("ADDON_LOADED")
loaderFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "EasyInterrupt" then
        ParseIgnoreList()
        if EasyInterruptIgnoreBox then
            EasyInterruptIgnoreBox:SetText(EasyInterruptDB.ignoreListStr)
        end
        loaderFrame:UnregisterEvent("ADDON_LOADED")
    end
end)
local soundList = {
    { text = "Raid Warning", value = "Sound\\Interface\\RaidWarning.wav" },
    { text = "Ready Check", value = "Sound\\Interface\\LevelUp.wav" },
    { text = "Auction Open", value = "Sound\\Interface\\AuctionWindowOpen.wav" },
    { text = "Auction Close", value = "Sound\\Interface\\AuctionWindowClose.wav" },
    { text = "Alarm Clock", value = "Sound\\Interface\\AlarmClockWarning3.wav" },
    { text = "PVP Flag Captured", value = "Sound\\Spells\\PVPFlagCaptured.wav" },
    { text = "PVP Flag Taken", value = "Sound\\Spells\\PVPFlagTaken.wav" },
    { text = "GM Chat Message", value = "Sound\\Interface\\GM_ChatWarning.wav" },
    { text = "Map Ping", value = "Sound\\Interface\\MapPing.wav" },
    { text = "Error Message", value = "Sound\\Interface\\igQuestFailed.wav" },
}

local interruptSpells = {
    ["WARRIOR"] = 6552,   
    ["PALADIN"] = 10308,  
    ["HUNTER"] = 34490,   
    ["ROGUE"] = 1766,     
    ["PRIEST"] = 15487,   
    ["DEATHKNIGHT"] = 47528, 
    ["SHAMAN"] = 57994,   
    ["MAGE"] = 2139,      
    ["WARLOCK"] = 19647,  
    ["DRUID"] = 16979     
}

local _, playerClass = UnitClass("player")
local myInterruptSpellID = interruptSpells[playerClass]
local lastPlayedCastID = nil
local panel = CreateFrame("Frame", "EasyInterruptOptionsPanel", InterfaceOptionsFramePanelContainer)
panel.name = "EasyInterrupt"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("EasyInterrupt")

local author = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
author:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
author:SetText("Автор: |cffC41F3BExodyke|r")

local cbEnabled = CreateFrame("CheckButton", "EasyInterruptCbEnabled", panel, "InterfaceOptionsCheckButtonTemplate")
cbEnabled:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -20)
_G[cbEnabled:GetName() .. "Text"]:SetText("Включить аддон")
cbEnabled:SetChecked(EasyInterruptDB.enabled)
cbEnabled:SetScript("OnClick", function(self)
    local val = not not self:GetChecked()
    EasyInterruptDB.enabled = val
    Config.interruptAnnounce = val
end)

local cbSound = CreateFrame("CheckButton", "EasyInterruptCbSound", panel, "InterfaceOptionsCheckButtonTemplate")
cbSound:SetPoint("TOPLEFT", cbEnabled, "BOTTOMLEFT", 0, -10)
_G[cbSound:GetName() .. "Text"]:SetText("Звук, если каст можно прервать и интеррапт готов")
cbSound:SetChecked(EasyInterruptDB.soundEnabled)
cbSound:SetScript("OnClick", function(self)
    EasyInterruptDB.soundEnabled = not not self:GetChecked()
end)
local dropDown = CreateFrame("Frame", "EasyInterruptSoundDropdown", panel, "UIDropDownMenuTemplate")
dropDown:SetPoint("TOPLEFT", cbSound, "BOTTOMLEFT", -15, -15)

local function DropDown_OnClick(self)
    UIDropDownMenu_SetSelectedValue(dropDown, self.value)
    EasyInterruptDB.soundFile = self.value
    PlaySoundFile(self.value)
end

UIDropDownMenu_Initialize(dropDown, function()
    for _, item in ipairs(soundList) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = item.text
        info.value = item.value
        info.func = DropDown_OnClick
        info.checked = (item.value == EasyInterruptDB.soundFile)
        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_SetSelectedValue(dropDown, EasyInterruptDB.soundFile)
UIDropDownMenu_SetWidth(dropDown, 200)

local dropDownLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
dropDownLabel:SetPoint("BOTTOMLEFT", dropDown, "TOPLEFT", 20, 2)
dropDownLabel:SetText("Выбор звука:")
local ignoreLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
ignoreLabel:SetPoint("TOPLEFT", dropDown, "BOTTOMLEFT", 20, -20)
ignoreLabel:SetText("Игнорируемые ID заклинаний (через запятую):")

local scrollContainer = CreateFrame("Frame", "EasyInterruptScrollContainer", panel)
scrollContainer:SetSize(340, 100)
scrollContainer:SetPoint("TOPLEFT", ignoreLabel, "BOTTOMLEFT", 0, -8)
scrollContainer:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
scrollContainer:SetBackdropColor(0, 0, 0, 0.5)
scrollContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

local scrollFrame = CreateFrame("ScrollFrame", "EasyInterruptScrollFrame", scrollContainer, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 8, -8)
scrollFrame:SetPoint("BOTTOMRIGHT", -26, 8)

local ignoreBox = CreateFrame("EditBox", "EasyInterruptIgnoreBox", scrollFrame)
ignoreBox:SetSize(300, 100)
ignoreBox:SetMultiLine(true)
ignoreBox:SetAutoFocus(false)
ignoreBox:SetFontObject("GameFontHighlight")
ignoreBox:SetText(EasyInterruptDB.ignoreListStr or "")

ignoreBox:SetScript("OnTextChanged", function(self)
    EasyInterruptDB.ignoreListStr = self:GetText()
    ParseIgnoreList()
    local _, max = _G[scrollFrame:GetName() .. "ScrollBar"]:GetMinMaxValues()
    for i = 1, 10 do
        if scrollFrame:GetVerticalScroll() < max then
            scrollFrame:SetVerticalScroll(max)
        end
    end
end)

ignoreBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
    scrollFrame:UpdateScrollChildRect()
    local scrollHeight = scrollFrame:GetHeight()
    local currentScroll = scrollFrame:GetVerticalScroll()
    y = -y
    if y < currentScroll then
        scrollFrame:SetVerticalScroll(y)
    elseif y + h > currentScroll + scrollHeight then
        scrollFrame:SetVerticalScroll(y + h - scrollHeight)
    end
end)

ignoreBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

scrollFrame:SetScrollChild(ignoreBox)
scrollContainer:SetScript("OnMouseDown", function() ignoreBox:SetFocus() end)

InterfaceOptions_AddCategory(panel)
local soundFrame = CreateFrame("Frame")
soundFrame:RegisterEvent("UNIT_SPELLCAST_START")
soundFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
soundFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

local function CheckTargetCast()
    if not EasyInterruptDB.soundEnabled or not myInterruptSpellID then return end
    
    local isCasting, name, notInterruptible, startTime, spellID
    local castName, _, _, _, castStart, _, _, _, castNotInterruptible = UnitCastingInfo("target")
    
    if castName then
        name = castName
        notInterruptible = castNotInterruptible
        startTime = castStart
        isCasting = true
        
        local _, _, _, _, _, _, _, _, _, castSpellID = UnitCastingInfo("target")
        spellID = castSpellID
    else
        local chanName, _, _, _, chanStart, _, _, chanNotInterruptible = UnitChannelInfo("target")
        if chanName then
            name = chanName
            notInterruptible = chanNotInterruptible
            startTime = chanStart
            isCasting = true
            
            local _, _, _, _, _, _, _, _, chanSpellID = UnitChannelInfo("target")
            spellID = chanSpellID
        end
    end
    
    if isCasting and not notInterruptible then
        if spellID and ignoredSpellIDs[spellID] then return end
        
        local currentCastID = name .. "_" .. (startTime or 0)
        if lastPlayedCastID == currentCastID then return end
        
        local start, duration = GetSpellCooldown(myInterruptSpellID)
        local cd = 0
        if start and duration and start > 0 and duration > 0 then
            cd = start + duration - GetTime()
        end
        if cd <= 0 then
            lastPlayedCastID = currentCastID
            PlaySoundFile(EasyInterruptDB.soundFile)
        end
    end
end

soundFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        lastPlayedCastID = nil
        CheckTargetCast()
    elseif unit == "target" then
        CheckTargetCast()
    end
end)

local updateFrame = CreateFrame("Frame")
local elapsedTimer = 0
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if not EasyInterruptDB.soundEnabled or not myInterruptSpellID then return end
    elapsedTimer = elapsedTimer + elapsed
    if elapsedTimer >= 0.1 then
        elapsedTimer = 0
        local name = UnitCastingInfo("target") or UnitChannelInfo("target")
        if name then
            CheckTargetCast()
        else
            lastPlayedCastID = nil
        end
    end
end)
local interruptFrame = CreateFrame("Frame")
interruptFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
interruptFrame:SetScript("OnEvent", function(self, event, ...)
    if not Config.interruptAnnounce then return end
    local _, eventType, sourceGUID, _, _, _, _, _, _, _, _, extraSpellID, extraSpellName = ...
    if eventType == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player") then
        local _, instanceType = GetInstanceInfo()
        if instanceType == "party" or instanceType == "raid" then 
            SendChatMessage("Прервано: " .. (GetSpellLink(extraSpellID) or extraSpellName), (instanceType == "raid" and "RAID" or "PARTY"))
        end
    end
end)


-- ПУК ПУК ПУК Я ЧЕЛОВЕК ПАУК