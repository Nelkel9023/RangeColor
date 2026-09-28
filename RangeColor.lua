local ADDON = ...

local defaults = {
	colors = {
		range = { r = 0.8, g = 0.1, b = 0.1 },
		mana = { r = 0.5, g = 0.5, b = 1.0 },
	},
}

local db = defaults

local function getIcon(button)
	local name = button:GetName()
	return button.icon or (name and _G[name .. "Icon"])
end

local function applyIconColor(button, outOfRange)
	local action = button.action
	if not action then return end

	local icon = getIcon(button)
	if not icon then return end

	if outOfRange then
		local c = db.colors.range
		icon:SetVertexColor(c.r, c.g, c.b)
		return
	end

	local isUsable, notEnoughMana = IsUsableAction(action)
	if isUsable then
		icon:SetVertexColor(1.0, 1.0, 1.0)
	elseif notEnoughMana then
		local c = db.colors.mana
		icon:SetVertexColor(c.r, c.g, c.b)
	else
		icon:SetVertexColor(0.4, 0.4, 0.4)
	end
end

local function checkButton(button)
	if not button or not button.action then return end
	applyIconColor(button, IsActionInRange(button.action) == 0)
end

local accumulator = 0

local updateFrame = CreateFrame("Frame")
updateFrame:Hide()
updateFrame:SetScript("OnUpdate", function(self, elapsed)
	accumulator = accumulator + elapsed
	if accumulator < 0.1 then return end
	accumulator = 0

	local patterns = {
		"ActionButton%d",
		"MultiBarBottomLeftButton%d",
		"MultiBarBottomRightButton%d",
		"MultiBarRightButton%d",
		"MultiBarLeftButton%d",
	}
	for _, pattern in ipairs(patterns) do
		for i = 1, 12 do
			local button = _G[pattern:format(i)]
			if button and button:IsShown() then
				checkButton(button)
			end
		end
	end
end)

hooksecurefunc("ActionButton_OnUpdate", function(self)
	if self and self:IsShown() then
		checkButton(self)
	end
end)

hooksecurefunc("ActionButton_UpdateUsable", function(self)
	if self then
		checkButton(self)
	end
end)

hooksecurefunc("ActionButton_Update", function(self)
	if self then
		checkButton(self)
	end
end)

local function ShowColorPicker(colorTable, callback)
	local cp = ColorPickerFrame
	if cp:IsVisible() then
		HideUIPanel(cp)
	end

	local prevR, prevG, prevB = colorTable.r, colorTable.g, colorTable.b

	cp.hasOpacity = false
	cp.opacityFunc = nil
	cp.opacity = nil

	cp.func = function()
		local r, g, b = cp:GetColorRGB()
		colorTable.r, colorTable.g, colorTable.b = r, g, b
		if callback then callback(r, g, b) end
	end

	cp:SetColorRGB(prevR, prevG, prevB)

	cp.cancelFunc = function()
		colorTable.r, colorTable.g, colorTable.b = prevR, prevG, prevB
		if callback then callback(prevR, prevG, prevB) end
	end

	ShowUIPanel(cp)
end

local optionsFrame

local function RefreshButtons()
	local patterns = {
		"ActionButton%d",
		"MultiBarBottomLeftButton%d",
		"MultiBarBottomRightButton%d",
		"MultiBarRightButton%d",
		"MultiBarLeftButton%d",
	}
	for _, pattern in ipairs(patterns) do
		for i = 1, 12 do
			local button = _G[pattern:format(i)]
			if button then
				checkButton(button)
			end
		end
	end
end

local function CreateOptionsFrame()
	if optionsFrame then
		optionsFrame:Show()
		return optionsFrame
	end

	local f = CreateFrame("Frame", "RangeColorOptions", UIParent)
	f:SetWidth(340)
	f:SetHeight(160)
	f:SetPoint("CENTER")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	f:SetClampedToScreen(true)
	f:Hide()

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -14)
	title:SetText("RangeColor")

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", 20, -44)
	desc:SetWidth(300)
	desc:SetJustifyH("LEFT")
	desc:SetText("Same IsActionInRange check the default hotkey uses. Icon turns your color when out of range.")

	local rangeColorBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	rangeColorBtn:SetWidth(160)
	rangeColorBtn:SetHeight(22)
	rangeColorBtn:SetPoint("TOPLEFT", 20, -90)
	rangeColorBtn:SetText("Out of Range Color")
	rangeColorBtn:SetScript("OnClick", function()
		ShowColorPicker(db.colors.range, function()
			if optionsFrame then optionsFrame:UpdateSwatches() end
			RefreshButtons()
		end)
	end)

	local rangeSwatch = f:CreateTexture(nil, "ARTWORK")
	rangeSwatch:SetWidth(16)
	rangeSwatch:SetHeight(16)
	rangeSwatch:SetPoint("LEFT", rangeColorBtn, "RIGHT", 8, 0)
	rangeSwatch:SetTexture("Interface\\Buttons\\WHITE8X8")
	rangeSwatch:SetVertexColor(db.colors.range.r, db.colors.range.g, db.colors.range.b, 1)

	local manaColorBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	manaColorBtn:SetWidth(160)
	manaColorBtn:SetHeight(22)
	manaColorBtn:SetPoint("TOPLEFT", 20, -118)
	manaColorBtn:SetText("Out of Mana Color")
	manaColorBtn:SetScript("OnClick", function()
		ShowColorPicker(db.colors.mana, function()
			if optionsFrame then optionsFrame:UpdateSwatches() end
			RefreshButtons()
		end)
	end)

	local manaSwatch = f:CreateTexture(nil, "ARTWORK")
	manaSwatch:SetWidth(16)
	manaSwatch:SetHeight(16)
	manaSwatch:SetPoint("LEFT", manaColorBtn, "RIGHT", 8, 0)
	manaSwatch:SetTexture("Interface\\Buttons\\WHITE8X8")
	manaSwatch:SetVertexColor(db.colors.mana.r, db.colors.mana.g, db.colors.mana.b, 1)

	f.UpdateSwatches = function()
		rangeSwatch:SetVertexColor(db.colors.range.r, db.colors.range.g, db.colors.range.b, 1)
		manaSwatch:SetVertexColor(db.colors.mana.r, db.colors.mana.g, db.colors.mana.b, 1)
	end

	optionsFrame = f
	return f
end

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00RangeColor|r: " .. msg)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
	if name ~= ADDON then return end
	self:UnregisterEvent("ADDON_LOADED")

	RangeColorDB = RangeColorDB or {}

	local function deepMerge(tbl, def)
		for k, v in pairs(def) do
			if tbl[k] == nil then
				if type(v) == "table" then
					tbl[k] = {}
					deepMerge(tbl[k], v)
				else
					tbl[k] = v
				end
			elseif type(v) == "table" and type(tbl[k]) == "table" then
				deepMerge(tbl[k], v)
			end
		end
	end

	deepMerge(RangeColorDB, defaults)
	db = RangeColorDB

	updateFrame:Show()
	RefreshButtons()

	SLASH_RANGECOLOR1 = "/rangecolor"
	SLASH_RANGECOLOR2 = "/rcolor"
	SlashCmdList["RANGECOLOR"] = function(msg)
		msg = strtrim(msg or ""):lower()

		if msg == "" or msg == "options" or msg == "config" then
			CreateOptionsFrame()
		elseif msg == "range" then
			ShowColorPicker(db.colors.range, function()
				if optionsFrame then optionsFrame:UpdateSwatches() end
				RefreshButtons()
			end)
		elseif msg == "mana" then
			ShowColorPicker(db.colors.mana, function()
				if optionsFrame then optionsFrame:UpdateSwatches() end
				RefreshButtons()
			end)
		elseif msg == "reset" then
			db.colors.range.r, db.colors.range.g, db.colors.range.b = defaults.colors.range.r, defaults.colors.range.g, defaults.colors.range.b
			db.colors.mana.r, db.colors.mana.g, db.colors.mana.b = defaults.colors.mana.r, defaults.colors.mana.g, defaults.colors.mana.b
			RefreshButtons()
			if optionsFrame and optionsFrame:IsShown() then
				optionsFrame.UpdateSwatches()
			end
			Print("reset to defaults")
		else
			Print("/rangecolor - open options")
			Print("/rangecolor range - pick out-of-range color")
			Print("/rangecolor mana - pick out-of-mana color")
			Print("/rangecolor reset - reset defaults")
		end
	end
end)
