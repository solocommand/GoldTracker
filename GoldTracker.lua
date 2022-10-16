local addonName, addon = ...
local L = addon.L
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local ldbi = LibStub:GetLibrary('LibDBIcon-1.0')
local timer = nil;
local realmName = GetRealmName();
local factionName = UnitFactionGroup("Player");
local character = UnitName("player");

local function showConfig()
  InterfaceOptionsFrame_OpenToCategory(addonName)
  InterfaceOptionsFrame_OpenToCategory(addonName)
end

local function highlight(text)
  if not text then return "" end
  return HIGHLIGHT_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE;
end

local function GetMoneyString(money, textOnly)
	local goldString, silverString, copperString;
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
	local copper = mod(money, COPPER_PER_SILVER);
  local SILVER_AMOUNT_TEXTURE = "%02d\124TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:2:0\124t";
  local COPPER_AMOUNT_TEXTURE = "%02d\124TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:2:0\124t";

  if (textOnly) then
    goldString = ("|cFFFFFF00%s|r%s"):format(FormatLargeNumber(gold), GOLD_AMOUNT_SYMBOL)
    silverString = ("|cFFCCCCCC%02d|r%s"):format(silver, SILVER_AMOUNT_SYMBOL)
    copperString = ("|cFFFF6600%02d|r%s"):format(silver, COPPER_AMOUNT_SYMBOL)
  else
    goldString = GOLD_AMOUNT_TEXTURE_STRING:format(FormatLargeNumber(gold), 0, 0);
    silverString = SILVER_AMOUNT_TEXTURE:format(silver, 0, 0);
    copperString = COPPER_AMOUNT_TEXTURE:format(copper, 0, 0);
  end

	return goldString.." "..silverString.." "..copperString;
end

-- Init & config panel
do
  local eventFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
  eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    if type(GoldTrackerSettings) ~= "table" then GoldTrackerSettings = {gold={},minimap={hide=false}} end
    local sv = GoldTrackerSettings
    if type(sv.minimap) ~= "table" then sv.minimap = {hide=false} end
    if type(sv.gold) ~= "table" then sv.gold = {} end
    if type(sv.showAll) ~= "boolean" then sv.showAll = true end
    addon.db = sv

    ldbi:Register(addonName, addon.dataobj, addon.db.minimap)
      self:SetScript("OnEvent", nil)
  end)
  eventFrame:RegisterEvent("ADDON_LOADED")
  addon.frame = eventFrame
end

-- data text
do
  local f = CreateFrame("frame")
  local text = "..loading.."
  local tooltip = ""
  local dataobj = ldb:NewDataObject("GoldTracker", {
    type = "data source",
    icon = "Interface\\AddOns\\GoldTracker\\GoldTracker",
    text = text,
    OnEnter = function(frame)
      GameTooltip:SetOwner(frame, "ANCHOR_NONE")
      GameTooltip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
      GameTooltip:ClearLines()
      addon:updateTooltip(frame)
      GameTooltip:Show()
    end,
    OnLeave = function()
      GameTooltip:Hide()
    end,
    OnClick = function(self, button)
      showConfig()
    end,
  })

  addon.dataobj = dataobj

  local function updateGold(copper)
    local gold = addon.db.gold
    if type(gold[factionName]) ~= "table" then gold[factionName] = {} end
    if type(gold[factionName][realmName]) ~= "table" then gold[factionName][realmName] = {} end
    gold[factionName][realmName][character] = copper
    addon.db.gold = gold
  end

  local function getServerGold()
    local copper = 0
    for faction,realms in pairs(addon.db.gold) do
      if (faction == factionName) then
        for realm,characters in pairs(realms) do
          if (realm == realmName) then
            for character, amt in pairs(characters) do
              copper = copper + amt
            end
          end
        end
      end
    end
    return copper
  end

  local function updateText()
    local copper = GetMoney();
    updateGold(copper);
    if (addon.db.showAll) then copper = getServerGold() end
    dataobj.text = GetMoneyString(copper, false);
  end

  function addon:updateTooltip()
    GameTooltip:AddLine(L["GoldTracker"])
    for faction,realms in pairs(addon.db.gold) do
      for realm,characters in pairs(realms) do
        local total = 0
        GameTooltip:AddLine(highlight(('\n%s - %s'):format(realm, faction)))
        local sorted = {}
        for n in pairs(characters) do table.insert(sorted, n) end
        table.sort(sorted)
        for i,character in ipairs(sorted) do
          local copper = characters[character]
          GameTooltip:AddDoubleLine(character, highlight(GetMoneyString(copper, true)))
          total = total + copper
        end
        GameTooltip:AddDoubleLine(highlight(L.total), highlight(GetMoneyString(total, true)))
      end
    end
  end

  function addon:setDB(key, value)
    addon.db[key] = value
    updateText()
  end

  function addon:clearCharacter(faction, realm, character)
    addon.db.gold[faction][realm][character] = nil
    updateText()
  end

  f:RegisterEvent("PLAYER_ENTERING_WORLD");
  f:RegisterEvent("PLAYER_MONEY");
  f:SetScript("OnEvent", function(self, event)
    if(event == "PLAYER_MONEY" or event == "PLAYER_ENTERING_WORLD") then
      updateText()
    end
  end)
end
