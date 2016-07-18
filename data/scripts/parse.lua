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

-- set to true to enable prints
parse_enableDebugPrints = false

-------------------------
--- Utility Functions ---
-------------------------

function dPrint_parse(message)
	if (parse_enableDebugPrints) then
		ba.print("[parse.lua] "..message)
	end
end

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
		if (string.find(line, "[#$+]") == nil) then
			return trim(string.sub(line, 1, cut - 1))
		else
			return trim(string.sub(line, 2, cut - 1))
		end
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

--[[
	Returns the specified value as a string. If the value is a table, return each value separated by a space.
	
	@return value
]]
function getValueAsString(value)
	if (value == nil) then
		return "nil"
	elseif (type(value) == 'table') then
		local str = ""
		for index, currentValue in pairs(value) do
			str = str..currentValue.." "
		end
		return str
	elseif (type(value) == 'boolean') then
		if (value) then
			return "true"
		else
			return "false"
		end
	else
		return value
	end
end

--[[
	Returns either the passed value, or the value according to the current difficulty level.

	@param value value or table of values
	@return actual value
]]
function getValue(value)
	if (type(value) == 'table') then
		return value[ba.getGameDifficulty()]
	else
		return value
	end
end

----------------------
--- Core Functions ---
----------------------

function getAttribute(value, isList)
	if (isList) then
		dPrint_parse("\t\tStuffing attribute list: "..value.."\n")
		return split(value, ",")
	else
		dPrint_parse("\t\tStuffing attribute value: "..value.."\n")
		return value
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
		
		dPrint_parse("#############################################\n")
		ba.print("[parse.lua] Parsing file "..fileName.."\n");
		dPrint_parse("#############################################\n")
		
		while (not (line == nil)) do
			line = removeComments(line)
			line = trim(line)
			-- Don't parse empty lines
			if not (line == "") then
				-- Extract values
				local attribute = extractLeft(line)
				local value = extractRight(line)
				-- Extract flags
				local isCat = not (string.find(line, "^#") == nil)
				local isAttr = not (string.find(line, "[$]") == nil)
				local isSubAttr = not (string.find(line, "[+]") == nil)
				local isList = not (string.find(line, ",") == nil)
				local isEnd = not (string.find(line, "^#End") == nil)
				
				dPrint_parse("Parsing line #"..lineNumber..": "..line.." ("..attribute.." = "..value..")\n")
				dPrint_parse("\tLine flags: Category = "..getValueAsString(isCat)..", Attribute = "..getValueAsString(isAttr)..", Sub Attribute = "..getValueAsString(isSubAttr)..", List = "..getValueAsString(isList)..", End = "..getValueAsString(isEnd).."\n")
				if  (isEnd) then
					dPrint_parse("Reached an #End marker\n")
				else
					if (isCat) then
						category = extractCategory(line)
						dPrint_parse("Entering category: "..category.."\n")
						tableObject[category] = {}
					elseif (isAttr) then
						if (attribute == "Name") then
							name = value
							dPrint_parse("\n")
							dPrint_parse("Name="..name.."\n")
							tableObject[category][name] = {}
							
						else
							currentAttribute = attribute	-- save attribute name in case we run into sub attributes
							dPrint_parse(category.." - "..name.." - "..attribute.."\n")
							tableObject[category][name][attribute] = {}
							tableObject[category][name][attribute]['value'] = getAttribute(value, isList)
							
							dPrint_parse("name="..name.."; attribute="..attribute.."; value="..getValueAsString(value).."\n")
						end
					elseif (isSubAttr) then
						-- initialize if needs be
						if (tableObject[category][name][currentAttribute]['sub'] == nil) then
							tableObject[category][name][currentAttribute]['sub'] = {}
						end
						tableObject[category][name][currentAttribute]['sub'][attribute] = getAttribute(value, isList)
						
						dPrint_parse("name="..name.."; current attribute="..currentAttribute.."; sub attribute="..attribute.."; value="..value.."\n")
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

--[[
	Prints the specified table object to a string
	
	@param tableObject : the table to print
	@return a string representing the table object
]]
function getTableObjectAsString(tableObject)
	local str = ""
	-- for each #Category
	for category, entries in pairs(tableObject) do
		str = str.."[parse.lua] #"..category.."\n\n"
		
		-- for each $Name:
		for name, attributes in pairs(entries) do
			str = str.."[parse.lua] $Name: \t"..name.."\n"
			
			-- for each $Attribute:
			for attributeName, prefixes in pairs(attributes) do
				if not (type(prefixes['value']) == 'table') then
					str = str.."[parse.lua] \t$"..attributeName.." = "..prefixes['value'].."\n"
				else
					str = str.."[parse.lua] \t"
					for index, value in pairs(prefixes['value']) do
						str = str..value.." "
					end
					str = str.."\n"
				end
				
				-- if there are any sub-attributes
				if not (prefixes['sub'] == nil) then
					-- for each +Sub Attribute:
					for subAttributeName, subAttributeValue in pairs(prefixes['sub']) do
						str = str.."[parse.lua] \t\t+"..subAttributeName.." = "..subAttributeValue.."\n"
					end -- end for each attribute
				end
				
			end -- end for each attribute
			
		end -- end for each entry
		
		str = str.."\n[parse.lua] #End\n"
	end -- end for each category
	
	return str
end

