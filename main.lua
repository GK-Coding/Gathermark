local f = CreateFrame("Frame")

-- local b = CreateFrame("Button", MyButton, Minimap)

SLASH_GATHERMARK1 = "/gathermark"
SLASH_GATHERMARK2 = "/gmark"
SLASH_RESET1 = "/gathermarkreset"
SLASH_RESET2 = "/gmarkreset"
SLASH_RESET3 = "/gmreset"
SLASH_HI1 = "/hi"
SLASH_HI2 = "/helloworld"

local Begin_Time_Set = false
local First_Item_Logged = false

local barIndex = 0;

local gatherStats = CreateFrame("Frame", "Gather_StatsFrame", UIParent, "BasicFrameTemplateWithInset")
gatherStats:SetSize(200, 240)
gatherStats:SetPoint("TOPLEFT", UIPARENT, "LEFT", 10, 200)
gatherStats.title = gatherStats:CreateFontString(nil, "ARTWORK")
gatherStats.title:SetFontObject("GameFontNormal")
gatherStats.title:SetPoint("CENTER", gatherStats.TitleBg, "CENTER")
gatherStats.title:SetText("Gathermark")

gatherStats.body = gatherStats:CreateFontString(nil, "ARTWORK")
gatherStats.body:SetFontObject("GameFontNormal")
gatherStats.body:SetPoint("CENTER", gatherStats, "CENTER", 0, 0)
gatherStats.body:SetText("Mine Something To Begin")

gatherStats.resetButton = CreateFrame("Button", nil, gatherStats, "GameMenuButtonTemplate")
gatherStats.resetButton:SetPoint("BOTTOM", gatherStats, "BOTTOM", 0, 10)
gatherStats.resetButton:SetSize(140, 40)
gatherStats.resetButton:SetText("Reset")
gatherStats.resetButton:SetNormalFontObject("GameFontNormalLarge")
gatherStats.resetButton:SetHighlightFontObject("GameFontHighlightLarge")

-- function resetSession()
--   print("test")
--   for i, v in pairs(MiningSession) do
--     MiningSession[i] = 0
--     print("test")
--     gatherStats[i]:SetText(i .. " - " .. 0)
--   end
--   gatherStats.duration:SetText("")
--   Begin_Time_Set = false
--   First_Item_Logged = false
--   MiningSession = {}
--   gatherStats.duration:Hide()
--   barIndex = 0;
--   gatherStats.body:Show()
-- end

MiningSession = {}
gsEntries = {}

f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

f:SetScript("OnEvent",
  function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
      local unit, castGUID, spellID = ...
      if spellID == 309835 then
        Last_Mined = time()
        MiningSession.latest = Last_Mined
        if Begin_Time_Set == false then
          MiningSession.began = Last_Mined
          Begin_Time_Set = true
        end
        self:RegisterEvent("ITEM_LOCK_CHANGED")
        self:RegisterEvent("LOOT_OPENED")
      end
    elseif event == "ITEM_LOCK_CHANGED" then
      local bag, slot = ...
      local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
  		if locked then
  			currentItem = link
  		else
  			currentItem = nil
  			self:UnregisterEvent("ITEM_LOCK_CHANGED")
  			self:UnregisterEvent("LOOT_OPENED")
  		end
    elseif event == "LOOT_OPENED" then
      gatherStats.body:Hide()
  		for i = 1, GetNumLootItems() do
  			local lootType = GetLootSlotType(i)
  			local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
  			if lootType == 2 then
  				print("Money:", item)
  			else
  				if not First_Item_Logged then
            if gatherStats.duration == nil then
            gatherStats.duration = gatherStats:CreateFontString(nil, "ARTWORK")
            gatherStats.duration:SetPoint("TOP", gatherStats, "TOP", 0, -30)
            end
            gatherStats.duration:SetFontObject("GameFontNormal")
            gatherStats.duration:SetText("Began Session: " .. date("%I:%M:%S", MiningSession.began))
            First_Item_Logged = true
          end
          if MiningSession[item] == nil then
            barIndex = barIndex + 1
            MiningSession[item] = quantity
            local check = item .. " - " .. 0
            if gatherStats[item] == nil then
            gatherStats[item] = gatherStats:CreateFontString(nil, "ARTWORK")
            gatherStats[item]:SetPoint("TOP", gatherStats, "TOP", 0, -15*barIndex-30)
            end
            gatherStats[item]:SetFontObject("GameFontNormal")
            gatherStats[item]:SetText(item .. " - " .. quantity)
            table.insert(gsEntries, item)
          else
            MiningSession[item] = MiningSession[item] + quantity
            gatherStats[item]:SetText(item .. " - " .. MiningSession[item])
          end
  			end
  		end
    end
  end)

  -- b:SetSize(40,40)
  -- b:SetNormalTexture("Interface\\Icons\\trade_mining")
  -- b:SetHighlightTexture(b:GetHighlightTexture("Interface\\Icons\\trade_mining"))
  -- b:SetPoint('BOTTOMRIGHT')
  -- b:SetText("Show Yields")
  -- b:Show()
  -- b:SetScript('OnClick', function()
  --   duration = time() - MiningSession.began
  --   print("Duration: " .. duration .. " seconds")
  --   for index, value in pairs(MiningSession) do
  --     if index == "began" or index == "latest" then
  --     else
  --       print(index, " x", value)
  --     end
  --   end
  -- end)

  SlashCmdList["GATHERMARK"] = function()
    duration = time() - MiningSession.began
    print("Duration: " .. duration .. " seconds")
    for index, value in pairs(MiningSession) do
      if index == "began" or index == "latest" then
      else
        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, invTexture, itemSellPrice = GetItemInfo(index)
        if itemRarity == 0 then
          local totalSellPrice = itemSellPrice*value
          print(itemName, " x", value, " - ", ("%dg %ds %dc"):format(totalSellPrice / 100 / 100, (totalSellPrice / 100) % 100, totalSellPrice % 100))
        else
          print(index, " x", value)
        end
      end
    end
  end

  SlashCmdList["RESET"] = function()
    gatherStats.duration:SetText("Session Was Reset")
    Begin_Time_Set = false
    First_Item_Logged = false
    for i,v in ipairs(gsEntries) do
      print(v)
      gatherStats[v]:SetText(v .. " - " .. 0)
    end
    MiningSession = {}
  end

  SlashCmdList["HI"] = function()
    message("Hello World")
  end


  gatherStats.resetButton:SetScript("OnClick", function()
    gatherStats.duration:SetText("Session Was Reset")
    Begin_Time_Set = false
    First_Item_Logged = false
    for i,v in ipairs(gsEntries) do
      print(v)
      gatherStats[v]:SetText(v .. " - " .. 0)
    end
    MiningSession = {}
  end)
