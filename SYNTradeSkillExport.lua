local ts_ver = "424"
local ts_frame = CreateFrame("Frame")
local ts_page = 1

ts_frame:RegisterEvent("ADDON_LOADED")
ts_frame:RegisterEvent("SKILL_LINES_CHANGED")
ts_frame:RegisterEvent("TRADE_SKILL_UPDATE")
ts_frame:RegisterEvent("TRADE_SKILL_CLOSE")
ts_frame:RegisterEvent("CRAFT_UPDATE")
ts_frame:RegisterEvent("CRAFT_CLOSE");

ts_frame:SetScript("OnEvent", function(self, event, ...)

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg, arg9 = ...
	player_name = UnitName("player").."-"..GetRealmName()
	g_name, _, _, _ = GetGuildInfo("player")

	if event == "ADDON_LOADED" and arg1 == "SYNTradeSkillExport" then
		if tradeskill_list == nil then tradeskill_list = {} end
		if craft_list == nil then craft_list = {} end
		if export_data == nil then export_data = {} end
		if export_data[player_name] == nil then export_data[player_name] = {} end

	end

	-------------------------------------------------------------------------------
	-- Update Spellbook Spells To Try Find a Profession Spec
	-------------------------------------------------------------------------------

	if event == "SKILL_LINES_CHANGED" then
		if export_data[player_name].spellbook_items == nil then export_data[player_name].spellbook_items = {} end

		local _, _, _, numSpells, _, _, _, _ = GetSpellTabInfo(ts_page)
		for i=1, numSpells do
			_, spellbook_item_id = GetSpellBookItemInfo(i, ts_ver)
			spellbook_item_name, _, _, _, _, _, _ = GetSpellInfo(spellbook_item_id)
			export_data[player_name].spellbook_items[tostring(spellbook_item_id)] = spellbook_item_name
		end
	end

	-------------------------------------------------------------------------------
	-- Update Trade Skills. (Everything But Enchanting)
	-------------------------------------------------------------------------------

	if event == "TRADE_SKILL_UPDATE" then
		if export_data[player_name].professions == nil then export_data[player_name].professions = {} end
		local i2 = GetNumTradeSkills()
		for i=1, i2 do
			ts_link = GetTradeSkillItemLink(i)
			if ts_link ~= nil then
				local _, _, _, _, Id = string.find(ts_link, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				export_data[player_name].professions[Id] = GetItemInfo(Id)
			end
		end
		export_data[player_name].guild_name = g_name
		export_data[player_name].character_name = UnitName("player")
		export_data[player_name].realm_name = GetRealmName()
		export_data[player_name].faction_name = UnitFactionGroup("player")
		export_data[player_name].class_name = UnitClass("player")
		export_data[player_name].race_name = UnitRace("player")

		Maybe_Tradeskill_Export()
	end

	-------------------------------------------------------------------------------
	-- Update Crafts. (Enchanting)
	-------------------------------------------------------------------------------

	if event == "CRAFT_UPDATE" then
		if export_data[player_name].crafts == nil then export_data[player_name].crafts = {} end
		local k2 = GetNumCrafts()
		for k=1, k2 do
			craft_link = GetCraftItemLink(k)
			if craft_link ~= nil then
				local _, _, _, _, Id = string.find(craft_link, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				export_data[player_name].crafts[Id] = GetCraftInfo(k)
			end
		end
		export_data[player_name].guild_name = g_name
		export_data[player_name].character_name = UnitName("player")
		export_data[player_name].realm_name = GetRealmName()
		export_data[player_name].faction_name = UnitFactionGroup("player")
		export_data[player_name].class_name = UnitClass("player")
		export_data[player_name].race_name = UnitRace("player")
		Maybe_Tradeskill_Export()
	end

	if event == "CRAFT_CLOSE" or  event == "TRADE_SKILL_CLOSE" then
		StaticPopup_Hide("EXPORT_TRADESKILL")
		StaticPopup_Hide("EXPORT_AVAILABLE")
	end

end)


-------------------------------------------------------------------------------
-- Show Export Window
-------------------------------------------------------------------------------
function Maybe_Tradeskill_Export()
	if StaticPopup_Visible("EXPORT_AVAILABLE") or StaticPopup_Visible("EXPORT_TRADESKILL") then
		return
	else

	local function notempty(s)
		return s ~= nil or s ~= ''
	end

	if notempty(export_data[player_name].character_name) then
		StaticPopupDialogs["EXPORT_AVAILABLE"] = {
			text = "|cffff6188S|cfffc9867Y|cffffd866N|cffa9dc76Trade|cff78dce8Skill|cffab9df2Export|r\n\n",
			button1 = "Export",
			button1Pulse = true,
			OnAccept = function (self, data, data2)
				Tradeskill_Export()
			end,
			timeout = 0,
			hasEditBox = false,
			editBoxWidth = 200,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}

		StaticPopup_Show("EXPORT_AVAILABLE")
	end
end

function Tradeskill_Export()


	export_data_json = encode_json(export_data)
	ser = ts_ver .. ">>" .. export_data_json
	serialized_json_export_data = Serialize(ser)
	StaticPopupDialogs["EXPORT_TRADESKILL"] = {
		text = "|cffff6188S|cfffc9867Y|cffffd866N|cffa9dc76Trade|cff78dce8Skill|cffab9df2Export|r\n\nCopy the text into your guilds #professions channel on Discord.\n",
		button1 = "Done",
		OnShow = function (self, data)
			self.editBox:SetText("syntradeskillexport".. serialized_json_export_data)
			self.editBox:HighlightText()
			self.editBox:SetScript("OnEscapePressed", function(self) StaticPopup_Hide ("EXPORT_TRADESKILL") end)
			end,
		timeout = 0,
		hasEditBox = true,
		editBoxWidth = 350,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Hide("EXPORT_AVAILABLE")
	StaticPopup_Show("EXPORT_TRADESKILL")

end
end
-------------------------------------------------------------------------------
-- Encode to Base 64
-------------------------------------------------------------------------------

function Serialize(data)
	local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	local s64 = ''
	local str = data
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

-------------------------------------------------------------------------------
-- Encode to JSON
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}

local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end

local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end

local function encode_nil(val)
  return "null"
end

local function encode_table(val, stack)
  local res = {}
  stack = stack or {}

  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end

local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
  if val ~= val or val <= -math.huge or val >= math.huge then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end

local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}

encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end

function encode_json(val)
	return ( encode(val) )
end
