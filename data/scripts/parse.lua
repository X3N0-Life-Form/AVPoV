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
		#Category			; note that this category doesn't have a name
		$Name:				entry name
		$Attribute1:		attribute 1 value
		$Attribute2:		attribute 2 value
			+sub attribute:	sub value
		
		$Name:				second entry
		$Another attribute:	value
		$Attribute list: item1, item2, item3
		#End
		
		;; The following categories do have names
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
		tab['entry name']['Attribute1']['value'] = attribute 1 value
		tab['entry name']['Attribute2']['value'] = attribute 2 value
		tab['entry name']['Attribute2']['sub']['sub attribute'] = sub value
		tab['second entry']['Another attribute'] = value
		tab['second entry']['Attribute list'][0] = item1
		tab['second entry']['Attribute list'][1] = item2
		tab['second entry']['Attribute list'][2] = item3
		tab['primary']['n1']['Attr'] = val
		tab['primary']['n2']['Attr'] = val
		tab['tertiary']['n1']['Attr'] = val
		tab['tertiary']['n2']['Attr'] = val
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

function stuffAttribute(attributeTable, value)
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
		
		local hasCategory = false
		local line = file:read("*l")
		local lineNumber = 1;
		while (not (line == nil)) do
			line = removeComments(line)
			line = trim(line)
			local attribute = extractLeft(line)
			local value = extractRight(line)
			isCat = string.find(line, "#(.)+:")
			isAttr = string.find(line, "($)")
			isSubAttr = string.find(line, "+")
			isList = string.find(line, ",")
			--
			ba.print("[parse.lua] Parsing line #"..lineNumber..": "..line.."\n")
			if not (isCat == nil) then
				hasCategory = true
			elseif not (isAttr == nil) then
				if (attribute == "Name") then
					name = value
					if (hasCategory) then
						tableObject[category][name] = {}
					else
						tableObject[name] = {}
					end
					ba.print("[parse.lua] Name="..name.."\n")
				else
					currentAttribute = attribute	-- save attribute name in case we run into sub attributes
					if (hasCategory) then --TODO: refactor into functions
						tableObject[category][name][attribute] = {}
						stuffAttribute(tableObject[category][name][attribute]['value'], value)
					else
						tableObject[name][attribute] = {}
						stuffAttribute(tableObject[name][attribute]['value'], value)
					end
					ba.print("[parse.lua] name="..name.."; attribute="..attribute.."; value="..value.."\n")
				end
			elseif not (isSubAttr == nil) then
				-- initialize if needs be
				if (hasCategory and tableObject[category][name][currentAttribute]['sub'] == nil) then
					tableObject[category][name][currentAttribute]['sub'] = {}
				elseif (tableObject[name][currentAttribute]['sub'] == nil) then
					tableObject[name][currentAttribute]['sub'] = {}
				end
				
				if (hasCategory) then
					stuffAttribute(tableObject[category][name][currentAttribute]['sub'][attribute], value)
				else
					stuffAttribute(tableObject[name][currentAttribute]['sub'][attribute], value)
				end
				ba.print("[parse.lua] name="..name.."; current attribute="..currentAttribute.."; sub attribute="..attribute.."; value="..value.."\n")
			end
			--
			line = file:read("*l")
			lineNumber = lineNumber + 1;
		end
	else
		ba.warning("[parse.lua] Table file not found: "..filePath..fileName.."\n")
	end

	return tableObject
end
