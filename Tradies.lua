--[[
	* Copyright (c) 2019 by Antoine Desmarets.
	* Cixi of Remulos Oceanic / WoW Classic
	*
	* Tradies is distributed in the hope that it will be useful and entertaining,
	* but WITHOUT ANY WARRANTY
]]--


-- New in 204
-- - updated website to work with TBC items
-- - updated addon for TBC


local tradlocal_version = "204"  --change here, and in TOC
local tradlocal_reqPrefix = "Tradies;"

local Tradies_button_tr = nil
local Tradies_button_cr = nil

local Tradies_profs = {}


local Tradies_frame = CreateFrame("Frame")
Tradies_frame:RegisterEvent("ADDON_LOADED")				--Initialisation
Tradies_frame:RegisterEvent("CRAFT_UPDATE")				--open tradeskill window
Tradies_frame:RegisterEvent("TRADE_SKILL_UPDATE");		--open tradeskill window
Tradies_frame:RegisterEvent("CHAT_MSG_WHISPER");		--receive whispers
Tradies_frame:RegisterEvent("CHAT_MSG_PARTY");			--receive party messages
Tradies_frame:RegisterEvent("CHAT_MSG_GUILD");			--receive guild messages
Tradies_frame:RegisterEvent("CHAT_MSG_CHANNEL");		--receive global channel messages

Tradies_frame:SetScript("OnEvent", function(self, event, ...)

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg, arg9 = ...
	
	if event == "ADDON_LOADED" and arg1 == "Tradies" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff00ff[Tradies]|r v."..tradlocal_version.." by Cixi@Remulos. Open a profession window to get started.")
		if Tradies_List == nil then Tradies_List = {} end
		if Tradies_AutoReply == nil then Tradies_AutoReply = true end
	end

	if event == "TRADE_SKILL_UPDATE" then
		local prof, lev, maxlev = GetTradeSkillLine()
		Tradies_List[prof] = {}
		Tradies_List[prof].level = lev
		Tradies_List[prof].max = maxlev
		Tradies_List[prof].recipes = {}

		for i=1, GetNumTradeSkills() do
			itemLink = GetTradeSkillItemLink(i)
			if itemLink ~= nil then 
				--local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink) 
				local _, _, Colour, Ltype, Id = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				Tradies_List[prof].recipes[Id] = itemLink
			end
		end

		if Tradies_button_tr == nil then 
			Tradies_button_tr = CreateFrame("Button","TradeSkillsExport",TradeSkillFrame) 
			Tradies_button_tr:SetWidth(48)
			Tradies_button_tr:SetHeight(48)
			Tradies_button_tr:SetPoint("TOPLEFT", TradeSkillFrame, "TOPRIGHT", -30, -13)
			Tradies_button_tr:SetNormalTexture("Interface/Icons/inv_misc_wrench_01")
			Tradies_button_tr:SetHighlightTexture("Interface/Icons/inv_misc_wrench_01")
			Tradies_button_tr:SetToplevel(true)
			Tradies_button_tr:SetScript("OnClick", function() 
				Tradies_Export(true) 
			end)
		end
	end

	if  event == "CRAFT_UPDATE" then 
		local prof, lev, maxlev = GetCraftDisplaySkillLine()
		Tradies_List[prof] = {}
		Tradies_List[prof].level = lev
		Tradies_List[prof].max = maxlev
		Tradies_List[prof].recipes = {}

		for i=1, GetNumCrafts() do
			itemLink = GetCraftItemLink(i)
			if itemLink ~= nil then 
				local _, _, Colour, Ltype, Id = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				Tradies_List[prof].recipes[Id] = itemLink
			end
		end

		if Tradies_button_cr == nil then 
			Tradies_button_cr = CreateFrame("Button","CraftExport",CraftFrame) 
			Tradies_button_cr:SetWidth(48)
			Tradies_button_cr:SetHeight(48)
			Tradies_button_cr:SetPoint("TOPLEFT", CraftFrame, "TOPRIGHT", -30, -13)
			Tradies_button_cr:SetNormalTexture("Interface/Icons/inv_misc_wrench_01")
			Tradies_button_cr:SetHighlightTexture("Interface/Icons/inv_misc_wrench_01")
			Tradies_button_cr:SetToplevel(true)
			Tradies_button_cr:SetScript("OnClick", function() 
					Tradies_Export(false) 
			end)
		end
	end


	if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_CHANNEL" then

		if Tradies_AutoReply then 
			--local channel = "WHISPER"
			--if event == "CHAT_MSG_GUILD" then channel = "GUILD" end
			--if event == "CHAT_MSG_PARTY" then channel = "PARTY" end
			
			--print(event, ...)
			--print(arg1);
			local msg = Tradies_split(arg1, " ")
			local sender = arg2
			if string.lower(msg[1]) == "?tradies" then 
				if msg[2] == nil then 
					if event == "CHAT_MSG_WHISPER" then 
						--list trades, but only if whispered directly
						for k,v in pairs(Tradies_List) do
							SendChatMessage("[Tradies] "..k.." (" .. v.level .. "/" .. v.max .. ")", "WHISPER", nil, sender)
						end 
						SendChatMessage("[Tradies] Whisper '?tradies <keyword>' to get a list of matching recipes.", "WHISPER", nil, sender)
					end 
				else 
					--list matching items
					local keyword = string.lower(string.sub(arg1, 10))
					if string.len(keyword) > 2 then 
						for k,v in pairs(Tradies_List) do
							for k2,v2 in pairs(v.recipes) do
								if string.find(string.lower(v2), keyword) ~= nil then 
									-- found something
									SendChatMessage("[Tradies] "..k..": " .. v2, "WHISPER", nil, sender)
								end
							end
						end 
					else
						--channel = "WHISPER" -- this is to ensure only the requester gets spammed.
						SendChatMessage("[Tradies] the <keyword> must be minimum 3 letters.", "WHISPER", nil, sender)
					end
				end 

			end
		end
	end 
end)
-------------------------------------------------------------------------

function Tradies_Export(isTr)


	local player = {}
	player.n = UnitName("player")
	player.R = GetRealmName()
	player.l = UnitLevel("player")
	player.F = UnitFactionGroup("player")
	_, classFile = UnitClass("player")
	_, raceFile = UnitRace("player")

	local g = UnitSex("player")
	player.g = 'male'
	if g == 3 then player.g = 'female' end
	player.c = classFile
	player.r = raceFile   --Scourge, Troll, etc
	
	local serplayer = Tradies_serialize(player)
	ser = tradlocal_version .. "##" .. serplayer .. "##"


	local skill, type, numAvail, isExpanded, altVerb, numSkillUps
	local itemLink

	if isTr then 
		for i=1, GetNumTradeSkills() do
			itemLink = GetTradeSkillItemLink(i)
			if itemLink ~= nil then 
				--local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink) 
				local _, _, Colour, Ltype, Id = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				--ser = ser .. Id .."#" .. itemName .."#" .. Colour .. "|"
				ser = ser .. Id.. "#item" .. "|"
				--print(itemName .. " / " .. Id .. " / " .. Colour )
			end
		end
	else 
		for i=1, GetNumCrafts() do
			itemLink = GetCraftItemLink(i)
			if itemLink ~= nil then 
				--print(itemLink)
				local _, _, Colour, Ltype, Id = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				--print(Id)
				--ser = ser .. Id .."#" .. itemName .."#" .. Colour .. "|"
				ser = ser .. Id .. "#spell" .. "|"
				--print(itemName .. " / " .. Id .. " / " .. Colour )
			end
		end
	end

	ser = string.sub(ser, 1, string.len(ser)-1) -- remove last ppipe

	local encoded = Tradies_enc(ser)
	
	StaticPopupDialogs["EXPORT_TRADIES"] = {
		text = "Copy the text below, then upload it to\n\nhttp://warcraftratings.com/tradies/upload",
		button1 = "Done",
		OnShow = function (self, data)
			self.editBox:SetText(""..encoded)
			self.editBox:HighlightText()
			self.editBox:SetScript("OnEscapePressed", function(self) StaticPopup_Hide ("EXPORT_TRADIES") end)
			end,
		timeout = 0,
		hasEditBox = true,
		editBoxWidth = 350,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("EXPORT_TRADIES")

end

-------------------------------------------------------------------------

function Tradies_split(str, sep)
	local t = {}
	local ind = string.find(str, sep)
	while (ind ~= nil) do 	
		table.insert(t, string.sub(str, 1, ind-1))
		str = string.sub(str, ind+1)
		ind = string.find(str, sep, 1, true)
	end
	if (str ~="") then table.insert(t, str) end
	return t
end

-------------------------------------------------------------------------

function Tradies_serialize (o)
	local res = ""
	if type(o) == "number" then
	  res = res .. o
	elseif type(o) == "string" then
		res = res .. string.format("%q", o)
	elseif type(o) == "table" then
		res = res .. "{\n"
	  for k,v in pairs(o) do
		if type(k) == "number" then
			res = res .. "  [" .. k .. "] = "
		elseif type(k) == "string" then
			 res = res .. "  [\"" .. k .. "\"] = "
		end
		res = res .. Tradies_serialize(v)
		res = res .. ",\n"
	  end
	  res = res ..  "}"
	elseif type(o) == "boolean" then
		if o then res = res .. "true"
		else res = res .. "false" end
	else
	  error("cannot serialize a " .. type(o))
	end
	return res
  end

-------------------------------------------------------------------------

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
-- encoding
function Tradies_enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-------------------------------------------------------------------------
-- decoding
function Tradies_dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end

-------------------------------------------------------------------------

function Tradies_SlashCommandHandler( msg )
	if (msg == '' or msg == 'help' or msg == '?') then
		
		print("|cffff00ff[Tradies]|r This addon will automatically reply to |cfffff700?tradies|r requests in /w, /p, /g or global.")
		print("|cffff00ff[Tradies]|r Based on your professions, tradies will reply with any item that matches.")
		print("|cffff00ff[Tradies]|r For example, if you type |cfffff700/g ?tradies mong|r you'll get replies from")
		print("|cffff00ff[Tradies]|r any guild alchemist (with the addon) that know the Mongoose recipe.")
		print("|cffff00ff[Tradies]|r use |cfffff700/tradies autoreply|r to toggle au-replies on or off.")
		print("|cffff00ff[Tradies]|r ")
		print("|cffff00ff[Tradies]|r The addon also allows you to upload all your tradeskills to a central website.")
		print("|cffff00ff[Tradies]|r Data can be uploaded to |cfffff700https://warcraftratings.com/tradies/upload|r")
		
	elseif (msg == 'autoreply') then
		if Tradies_AutoReply then 
			Tradies_AutoReply = false 
			print("|cffff00ff[Tradies]|r Auto-replies are now OFF")
		else
			Tradies_AutoReply = true
			print("|cffff00ff[Tradies]|r Auto-replies are now ON")
		end
	end
end

-------------------------------------------------------------------------

SlashCmdList["Tradies"] = Tradies_SlashCommandHandler
SLASH_Tradies1 = "/Tradies"