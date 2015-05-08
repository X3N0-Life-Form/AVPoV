--[[
	--------------------------------
	--- Generic FSO Table Parser ---
	--------------------------------
	This script is meant to parse data files written in the style of Freespace Open table files.
	The function parseTableFile return a lua table object that mimics the data structure of the parsed table,
	which you can then use or reorganise into easier-to-use data structures.
	Note that this is a 'dumb' parsing script: it doesn't check whether a required attribute is present or not, like FSO does.
	Also note that category names have to be explicitly declared. This helps keeping the complexity of the resulting lua table down a bit.
	
	Example:
	The following Freespace table:
		#Category
		$Name:				entry name
		$Attribute1:		attribute 1 value
		$Attribute2:		attribute 2 value
			+sub attribute:	sub value
		
		$Name:				second entry
		$Another attribute:	value
		$Attribute list: item1, item2, item3
		#End
		
		#Weapons: primary
		$Name:	n1
		$Attr:	val
		
		$Name:	n2
		$Attr:	val
		#End
		
		#Weapons: tertiary
		$Name:	n1
		$Attr:	val
		
		$Name:	n2
		$Attr:	val
		#End
		
	Will result in the following lua table:
		tab['Category']				['entry name']['Attribute1']['value']					= attribute 1 value
		tab['Category']				['entry name']['Attribute2']['value']					= attribute 2 value
		tab['Category']				['entry name']['Attribute2']['sub']['sub attribute']	= sub value
		tab['Category']				['second entry']['Another attribute']					= value
		tab['Category']				['second entry']['Attribute list']				[0]		= item1
		tab['Category']				['second entry']['Attribute list']				[1]		= item2
		tab['Category']				['second entry']['Attribute list']				[2]		= item3
		tab['Weapons: primary']		['n1']['Attr']											= val
		tab['Weapons: primary']		['n2']['Attr']											= val
		tab['Weapons: tertiary']	['n1']['Attr']											= val
		tab['Weapons: tertiary']	['n2']['Attr']											= val
]]--

-------------------------
--- Utility Functions ---
-------------------------

function trim(str)
	return str:find'^%s*$' and '' or str:match'^%s*(.*%S)'
end

function removeComments(line)
	local cut = line:find(";") -- there's gotta be something more robust than that hack job
	if (cut == nil) then
		return line
	else
		return line:sub(0, cut - 1)
	end
end

function extractCategory(line)
	local cut = string.find(line, "#")
	if (cut == nil) then
		return trim(line)
	else
		return trim(string.sub(line, cut + 1))
	end
end

function extractLeft(attribute)
	local line = attribute
	local cut = string.find(line, ":")
	if (cut == nil) then
		return trim(line)
	else
		return trim(string.sub(line, 2, cut - 1))
	end
end

function extractRight(attribute)
	local line = attribute
	local cut = string.find(line, ":")
	if (cut == nil) then
		return trim(line)
	else
		return trim(string.sub(line, cut + 1))
	end
end

-- copied from lua-user wiki
function split(str, pat)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			cap = trim(cap)
			table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end

----------------------
--- Core Functions ---
----------------------

function stuffAttribute(attributeTable, value, isList)
	if (isList == nil) then
		attributeTable = value
	else
		attributeTable = split(value, ",")
	end
end

--[[
	@return a lua table containing data from the parsed table.
]]--
function parseTableFile(filePath, fileName)
	local tableObject = {}

	if cf.fileExists(fileName, filePath, true) then
		local file = cf.openFile(fileName, "r", filePath)
		
		local line = file:read("*l")
		local lineNumber = 1
		while (not (line == nil)) do
			line = removeComments(line)
			line = trim(line)
			-- don't parse empty lines
			if not (line == "") then
				local attribute = extractLeft(line)
				local value = extractRight(line)
				local isCat = string.find(line, "^#")
				local isAttr = string.find(line, "$")
				local isSubAttr = string.find(line, "+")
				local isList = string.find(line, ",")
				local isEnd = string.find(line, "#End")
				--
				ba.print("[parse.lua] Parsing line #"..lineNumber..": "..line.." ("..attribute.." = "..value..")\n")
				if  not (isEnd == nil) then
					ba.print("[parse.lua] Reached an #End marker\n")
				else
					if not (isCat == nil) then
						category = extractCategory(line)
						ba.print("[parse.lua] Entering category: "..category.."\n")
						tableObject[category] = {}
					elseif not (isAttr == nil) then
						if (attribute == "Name") then
							name = value
							ba.print("[parse.lua] Name="..name.."\n")
							tableObject[category][name] = {}
							
						else
							currentAttribute = attribute	-- save attribute name in case we run into sub attributes
							ba.print(category.." - "..name.." - "..attribute)
							tableObject[category][name][attribute] = {}
							tableObject[category][name][attribute]['value'] = "none"
							stuffAttribute(tableObject[category][name][attribute]['value'], value, isList)
							
							ba.print("[parse.lua] name="..name.."; attribute="..attribute.."; value="..tableObject[category][name][attribute]['value'].."\n")
						end
					elseif not (isSubAttr == nil) then
						-- initialize if needs be
						if (tableObject[category][name][currentAttribute]['sub'] == nil) then
							tableObject[category][name][currentAttribute]['sub'] = {}
						end
						stuffAttribute(tableObject[category][name][currentAttribute]['sub'][attribute], value)
						
						ba.print("[parse.lua] name="..name.."; current attribute="..currentAttribute.."; sub attribute="..attribute.."; value="..value.."\n")
					end
				end
				--
			end
			line = file:read("*l")
			lineNumber = lineNumber + 1;
		end
	else
		ba.warning("[parse.lua] Table file not found: "..filePath..fileName.."\n")
	end

	return tableObject
end
