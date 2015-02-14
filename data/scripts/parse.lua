ba.warning("TODO: array list of things, ie. +R: 128, 128, 128, 128")
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
		tab['entry name']['Attribute1'] = attribute 1 value
		tab['entry name']['Attribute2'] = attribute 2 value
		tab['entry name']['Attribute2']['sub']['sub attribute'] = sub value
		tab['second entry']['Another attribute'] = value
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

----------------------
--- Core Functions ---
----------------------

--[[
	@return a lua table containing data from the parsed table.
]]--
function parseTableFile(filePath, fileName)
	local tableObject = {}

	if cf.fileExists(fileName, filePath, true) then
		local file = cf.openFile(fileName, "r", filePath)
		
		local hasCategory = false
		local line = file:read("*l")
		while (not (line == nil)) do
			line = removeComments(line)
			line = trim(line)
			attribute = extractLeft(line)
			value = extractRight(line)
			isCat = string.find(line, "#(.)+:")
			isAttr = string.find(line, "($)")
			isSubAttr = string.find(line, "+")
			--
			ba.print("[parse.lua] Parsing line: "..line)
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
					ba.print("[parse.lua] Name="..name)
				else
					currentAttribute = attribute -- save attribute name in case we run into sub attributes
					if (hasCategory) then
						tableObject[category][name][attribute] = value
					else
						tableObject[name][attribute] = value
					end
					ba.print("[parse.lua] name="..name.."; attribute="..attribute.."; value="..value)
				end
			elseif not (isSubAttr == nil) then
				-- initialize if needs be
				if (hasCategory and tableObject[category][name][currentAttribute]['sub'] == nil) then
					tableObject[category][name][currentAttribute]['sub'] = {}
				elseif (tableObject[name][currentAttribute]['sub'] == nil) then
					tableObject[name][currentAttribute]['sub'] = {}
				end
				
				if (hasCategory) then		
					tableObject[category][name][currentAttribute]['sub'][attribute] = value
				else
					tableObject[name][currentAttribute]['sub'][attribute] = value
				end
				ba.print("[parse.lua] name="..name.."; current attribute="..currentAttribute.."; sub attribute="..attribute.."; value="..value)
			end
			--
			line = file:read("*l")
		end
	else
		ba.warning("[parse.lua] Table file not found: "..filePath..fileName)
	end

	return tableObject
end
