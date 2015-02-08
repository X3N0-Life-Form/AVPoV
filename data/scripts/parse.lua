

-------------------------
--- Utility Functions ---
-------------------------

function trim(str)
	return str:find'^%s*$' and '' or str:match'^%s*(.*%S)'
end

function removeComments(line)
	return line:gsub("--(.)*|//(.)*|;;(.)*", "")
end

function extractLeft(attribute)
	local line = attribute
	local cut = string.find(line, ":")
	return trim(string.sub(line, 2, cut - 1))
end

function extractRight(attribute)
	local line = attribute
	local cut = string.find(line, ":")
	return trim(string.sub(line, cut + 1))
end

----------------------
--- Core Functions ---
----------------------

--[[
	Note: valid states are:
			- name_or_category
			- category
			- name
			- attribute
]]--
function parseTableFile(filePath, fileName)
	local tableObject = {}

	if cf.fileExists(fileName, filePath, true) then
		local file = cf.openFile(fileName, "r", filePath)
		
		local state = "name_or_category"-----------------------------------
		local hasCategory = false
		local line = file:read("*l")
		while (not (line == nil)) do
			line = removeComments(line)
			line = trim(line)
			attribute = extractLeft(line)
			value = extractRight(line)
			isCat = string.find(line, "#")
			isAttr = string.find(line, "$")
			isSubAttr = string.find(line, "+")
			--
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
				else
					currentAttribute = attribute -- save attribute name in case we run into sub attributes
					if (hasCategory) then
						tableObject[category][name][attribute] = value
					else
						tableObject[name][attribute] = value
					end
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
			end
			--
			line = file:read("*l")
		end
	end

	return tableObject
end