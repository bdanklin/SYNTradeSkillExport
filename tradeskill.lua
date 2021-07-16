local ts_ver = "420"
local ts_button = nil

local ts_frame = CreateFrame("Frame")
ts_frame:RegisterEvent("ADDON_LOADED")
ts_frame:RegisterEvent("TRADE_SKILL_SHOW")
ts_frame:RegisterEvent("TRADE_SKILL_UPDATE");

ts_frame:SetScript("OnEvent", function(self, event, ...)

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg, arg9 = ...

	if event == "ADDON_LOADED" and arg1 == "Tradies" then
		if tradeskill_list == nil then tradeskill_list = {} end
	end

	if event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_SHOW" then
		for i=1, GetNumTradeSkills() do
			itemLink = GetTradeSkillItemLink(i)
			if itemLink ~= nil then
				local _, _, _, _, Id = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				tradeskill_list[Id] = ""
			end
		end

		if ts_button == nil then
			ts_button = CreateFrame("Button","TradeSkillsExport",TradeSkillFrame)
			ts_button:SetWidth(40)
			ts_button:SetHeight(40)
			ts_button:SetPoint("TOPLEFT", TradeSkillFrame, "TOPRIGHT", -30, -13)
			ts_button:SetNormalTexture("Interface/Icons/inv_misc_thegoldencheep")
			ts_button:SetHighlightTexture("Interface/Icons/inv_misc_thegoldencheep")
			ts_button:SetToplevel(true)
			ts_button:SetScript("OnClick", function()Tradeskill_Export(true)end)
		end
	end
end)

-------------------------------------------------------------------------------
-- Show Export Window
-------------------------------------------------------------------------------

function Tradeskill_Export(isTr)
	local player = {}
	player.g, _, _ = GetGuildInfo("player")

	player.n = UnitName("player")
	player.R = GetRealmName()
	player.F = UnitFactionGroup("player")
	_, player.c = UnitClass("player")
	_, player.r = UnitRace("player")

	local serplayer = encode_json(player)
	local sertradies = encode_json(tradeskill_list)
	ser = ">>v" .. ts_ver .. ">>p" .. serplayer .. ">>t" .. sertradies


	local encoded = Serialize(ser)
	StaticPopupDialogs["EXPORT_TRADESKILL"] = {
		text = "Copy the text below, then send it to the See You Next Tuesday Discord bot.",
		button1 = "Done",
		OnShow = function (self, data)
			self.editBox:SetText(""..encoded)
			self.editBox:HighlightText()
			self.editBox:SetScript("OnEscapePressed", function(self) StaticPopup_Hide ("EXPORT_TRADESKILL") end)
			end,
		timeout = 0,
		hasEditBox = true,
		editBoxWidth = 350,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("EXPORT_TRADESKILL")

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

  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
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
    -- Encode
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"

  else
    -- Treat as an object
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
  -- Check for NaN, -inf and inf
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
