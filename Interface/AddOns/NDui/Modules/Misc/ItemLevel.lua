﻿local _, ns = ...
local B, C, L, DB = unpack(ns)
local M = B:GetModule("Misc")

local pairs, select, next, wipe = pairs, select, next, wipe
local UnitGUID, GetItemInfo = UnitGUID, GetItemInfo
local GetInventoryItemLink = GetInventoryItemLink

local inspectSlots = {
	"Head",
	"Neck",
	"Shoulder",
	"Shirt",
	"Chest",
	"Waist",
	"Legs",
	"Feet",
	"Wrist",
	"Hands",
	"Finger0",
	"Finger1",
	"Trinket0",
	"Trinket1",
	"Back",
	"MainHand",
	"SecondaryHand",
	"Ranged",
}

function M:GetSlotAnchor(index)
	if not index then return end

	if index <= 5 or index == 9 or index == 15 then
		return "BOTTOMLEFT", 40, 20
	elseif index == 16 then
		return "BOTTOMRIGHT", -40, 2
	elseif index == 17 then
		return "BOTTOMLEFT", 40, 2
	else
		return "BOTTOMRIGHT", -40, 20
	end
end

function M:CreateItemTexture(slot, relF, x, y)
	local icon = slot:CreateTexture()
	icon:SetPoint(relF, x, y)
	icon:SetSize(14, 14)
	icon.bg = B.ReskinIcon(icon)
	icon.bg:SetFrameLevel(3)
	icon.bg:Hide()

	return icon
end

function M:CreateColorBorder()
	if C.db["Skins"]["BlizzardSkins"] then return end

	local frame = CreateFrame("Frame", nil, self)
	frame:SetAllPoints()
	self.colorBG = B.CreateSD(frame, 4, true)
	self.colorBG:SetFrameLevel(5)
end

function M:CreateItemString(frame, strType)
	if frame.fontCreated then return end

	for index, slot in pairs(inspectSlots) do
		if index ~= 4 then
			local slotFrame = _G[strType..slot.."Slot"]
			slotFrame.iLvlText = B.CreateFS(slotFrame, DB.Font[2]+1)
			slotFrame.iLvlText:ClearAllPoints()
			slotFrame.iLvlText:SetPoint("BOTTOMLEFT", slotFrame, 1, 1)
			local relF, x, y = M:GetSlotAnchor(index)
			slotFrame.enchantText = B.CreateFS(slotFrame, DB.Font[2]+1)
			slotFrame.enchantText:ClearAllPoints()
			slotFrame.enchantText:SetPoint(relF, slotFrame, x, y)
			slotFrame.enchantText:SetTextColor(0, 1, 0)
		--	for i = 1, 5 do
		--		local offset = (i-1)*18 + 5
		--		local iconX = x > 0 and x+offset or x-offset
		--		local iconY = index > 15 and 20 or 2
		--		slotFrame["textureIcon"..i] = M:CreateItemTexture(slotFrame, relF, iconX, iconY)
		--	end
			M.CreateColorBorder(slotFrame)
		end
	end

	frame.fontCreated = true
end

function M:ItemBorderSetColor(slotFrame, r, g, b)
	if slotFrame.colorBG then
		slotFrame.colorBG:SetBackdropBorderColor(r, g, b)
	end
	if slotFrame.bg then
		slotFrame.bg:SetBackdropBorderColor(r, g, b)
	end
end

local pending = {}
function M:RefreshButtonInfo()
	if InspectFrame and InspectFrame.unit then
		for index, slotFrame in pairs(pending) do
			local link = GetInventoryItemLink(InspectFrame.unit, index)
			if link then
				local quality, level = select(3, GetItemInfo(link))
				if quality then
					local color = DB.QualityColors[quality]
					M:ItemBorderSetColor(slotFrame, color.r, color.g, color.b)
					if C.db["Misc"]["ShowItemLevel"] and level and level > 1 and quality > 1 then
						slotFrame.iLvlText:SetText(level)
						slotFrame.iLvlText:SetTextColor(color.r, color.g, color.b)
					end
					pending[index] = nil
				end
			end
		end

		if not next(pending) then
			self:Hide()
			return
		end
	else
		wipe(pending)
		self:Hide()
	end
end

function M:ItemLevel_SetupLevel(frame, strType, unit)
	if not UnitExists(unit) then return end

	M:CreateItemString(frame, strType)

	for index, slot in pairs(inspectSlots) do
		if index ~= 4 then
			local slotFrame = _G[strType..slot.."Slot"]
			slotFrame.iLvlText:SetText("")
			slotFrame.enchantText:SetText("")
		--	for i = 1, 5 do
		--		local texture = slotFrame["textureIcon"..i]
		--		texture:SetTexture(nil)
		--		texture.bg:Hide()
		--	end
			M:ItemBorderSetColor(slotFrame, 0, 0, 0)

			local itemTexture = GetInventoryItemTexture(unit, index)
			if itemTexture then
				local link = GetInventoryItemLink(unit, index)
				if link then
					local quality, level = select(3, GetItemInfo(link))
					if quality then
						local color = DB.QualityColors[quality]
						M:ItemBorderSetColor(slotFrame, color.r, color.g, color.b)
						if C.db["Misc"]["ShowItemLevel"] and level and level > 1 and quality > 1 then
							slotFrame.iLvlText:SetText(level)
							slotFrame.iLvlText:SetTextColor(color.r, color.g, color.b)
						end
					else
						pending[index] = slotFrame
						M.QualityUpdater:Show()
					end
				else
					pending[index] = slotFrame
					M.QualityUpdater:Show()
				end
			end
		end
	end
end

function M:ItemLevel_UpdatePlayer()
	M:ItemLevel_SetupLevel(CharacterFrame, "Character", "player")
end

function M:ItemLevel_UpdateInspect(...)
	local guid = ...
	if InspectFrame and InspectFrame.unit and UnitGUID(InspectFrame.unit) == guid then
		M:ItemLevel_SetupLevel(InspectFrame, "Inspect", InspectFrame.unit)
	end
end

function M:ShowItemLevel()
	if not C.db["Misc"]["ItemLevel"] then return end

	-- iLvl on CharacterFrame
	CharacterFrame:HookScript("OnShow", M.ItemLevel_UpdatePlayer)
	B:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", M.ItemLevel_UpdatePlayer)

	-- iLvl on InspectFrame
	B:RegisterEvent("INSPECT_READY", M.ItemLevel_UpdateInspect)

	-- Update item quality
	M.QualityUpdater = CreateFrame("Frame")
	M.QualityUpdater:Hide()
	M.QualityUpdater:SetScript("OnUpdate", M.RefreshButtonInfo)
end
M:RegisterMisc("GearInfo", M.ShowItemLevel)