local pf_local_version = "100"  --change here, and in TOC
local pf_local_reqPrefix = "synt_pf;"

local synt_pf_button_tr = nil
local synt_pf_button_cr = nil

local synt_pf_profs = {}


local synt_pf_frame = CreateFrame("Frame")
synt_pf_frame:RegisterEvent("ADDON_LOADED")						--Initialisation
synt_pf_frame:RegisterEvent("CRAFT_UPDATE")						--open tradeskill window
synt_pf_frame:RegisterEvent("TRADE_SKILL_UPDATE");		--open tradeskill window

synt_pf_frame:SetScript("OnEvent", function(self, event, ...)

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg, arg9 = ...

	if event == "ADDON_LOADED" and arg1 == "synt_pf" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff00ff[synt_pf]|r v."..tradlocal_version.." by Cixi@Remulos. Open a profession window to get started.")
		if synt_pf_List == nil then synt_pf_List = {} end
		if synt_pf_AutoReply == nil then synt_pf_AutoReply = true end
	end

	if event == "TRADE_SKILL_UPDATE" then
		local prof, lev, maxlev = GetTradeSkillLine()
		synt_pf_List[prof] = {}
		synt_pf_List[prof].level = lev
		synt_pf_List[prof].max = maxlev
		synt_pf_List[prof].recipes = {}

		for i=1, GetNumTradeSkills() do
			itemLink = GetTradeSkillItemLink(i)
			if itemLink ~= nil then
				--local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
				local _, _, Colour, Ltype, Id = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				synt_pf_List[prof].recipes[Id] = itemLink
			end
		end

		if synt_pf_button_tr == nil then
			synt_pf_button_tr = CreateFrame("Button","TradeSkillsExport",TradeSkillFrame)
			synt_pf_button_tr:SetWidth(40)
			synt_pf_button_tr:SetHeight(40)
			synt_pf_button_tr:SetPoint("TOPLEFT", TradeSkillFrame, "TOPRIGHT", -30, -13)
			synt_pf_button_tr:SetNormalTexture("Interface/Icons/inv_misc_wrench_01")
			synt_pf_button_tr:SetHighlightTexture("Interface/Icons/inv_misc_wrench_01")
			synt_pf_button_tr:SetToplevel(true)
			synt_pf_button_tr:SetScript("OnClick", function()
				synt_pf_Export(true)
			end)
		end
	end

	if  event == "CRAFT_UPDATE" then
		local prof, lev, maxlev = GetCraftDisplaySkillLine()
		synt_pf_List[prof] = {}
		synt_pf_List[prof].level = lev
		synt_pf_List[prof].max = maxlev
		synt_pf_List[prof].recipes = {}

		for i=1, GetNumCrafts() do
			itemLink = GetCraftItemLink(i)
			if itemLink ~= nil then
				local _, _, Colour, Ltype, Id = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				synt_pf_List[prof].recipes[Id] = itemLink
			end
		end

		if synt_pf_button_cr == nil then
			synt_pf_button_cr = CreateFrame("Button","CraftExport",CraftFrame)
			synt_pf_button_cr:SetWidth(48)
			synt_pf_button_cr:SetHeight(48)
			synt_pf_button_cr:SetPoint("TOPLEFT", CraftFrame, "TOPRIGHT", -30, -13)
			synt_pf_button_cr:SetNormalTexture("Interface/Icons/inv_misc_wrench_01")
			synt_pf_button_cr:SetHighlightTexture("Interface/Icons/inv_misc_wrench_01")
			synt_pf_button_cr:SetToplevel(true)
			synt_pf_button_cr:SetScript("OnClick", function()
					synt_pf_Export(false)
			end)
		end
	end



end)
-------------------------------------------------------------------------

function synt_pf_Export(isTr)


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

	local serplayer = synt_pf_serialize(player)
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

	local encoded = synt_pf_enc(ser)

	StaticPopupDialogs["EXPORT_SYNT"] = {
		text = "Copy Paste",
		button1 = "Close",
		OnShow = function (self, data)
			self.editBox:SetText(""..encoded)
			self.editBox:HighlightText()
			self.editBox:SetScript("OnEscapePressed", function(self) StaticPopup_Hide ("EXPORT_synt_pf") end)
			end,
		timeout = 0,
		hasEditBox = true,
		editBoxWidth = 350,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("EXPORT_SYNT")

end

-------------------------------------------------------------------------

function synt_pf_split(str, sep)
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

function synt_pf_serialize (o)
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
		res = res .. synt_pf_serialize(v)
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
function synt_pf_enc(data)
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
function synt_pf_dec(data)
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

function encodeBase64(data)
	local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	local s64 = ''
	local str = source_str

	while #str > 0 do
			local bytes_num = 0
			local buf = 0

			for byte_cnt=1,3 do
					buf = (buf * 256)
					if #str > 0 then
							buf = buf + string.byte(str, 1, 1)
							str = string.sub(str, 2)
							bytes_num = bytes_num + 1
					end
			end

			for group_cnt=1,(bytes_num+1) do
					local b64char = math.fmod(math.floor(buf/262144), 64) + 1
					s64 = s64 .. string.sub(b64chars, b64char, b64char)
					buf = buf * 64
			end

			for fill_cnt=1,(3-bytes_num) do
					s64 = s64 .. '='
			end
	end

	return s64
end
